import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../models/bill_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/bill_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../services/supabase_storage_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bill/promptpay_card.dart';
import '../../../widgets/bill/member_summary_list.dart';

class SummaryScreen extends StatefulWidget {
  final String lobbyId;
  final Map<String, dynamic> receiptData;
  final Map<int, List<Map<String, dynamic>>> itemSharers;
  final List<Map<String, dynamic>> roomParticipants;
  final Uint8List? receiptImageBytes;
  final bool isHost; // 🚀 รับสถานะ Host

  const SummaryScreen({
    super.key,
    required this.lobbyId,
    required this.receiptData,
    required this.itemSharers,
    this.roomParticipants = const [],
    this.receiptImageBytes,
    this.isHost = true,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isFinishing = false;
  String _hostPromptPay = '';
  String? _hostPromptPayType;
  String? _hostBankName;
  String _hostBankAccountNumber = '';
  String? _hostBankAccountName;
  String _hostName = 'เจ้าของบิล';
  String? _currentUserId;
  String? _selectedUserId;
  bool _isCurrentUserHost = false;
  bool _isLoadingHost = true;

  bool get _hasValidPromptPay {
    final cleanTarget = _hostPromptPay.replaceAll(RegExp(r'[^0-9]'), '');
    return (_hostPromptPayType == 'phone' &&
            cleanTarget.length == 10 &&
            cleanTarget.startsWith('0')) ||
        (_hostPromptPayType == 'id_card' && cleanTarget.length == 13);
  }

  bool get _hasValidBankTransfer => _hostBankAccountNumber.isNotEmpty;
  bool get _hasPaymentMethod => _hasValidPromptPay || _hasValidBankTransfer;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _selectedUserId = _currentUserId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchHostPromptPayInfo();
    });
  }

  Future<void> _fetchHostPromptPayInfo() async {
    try {
      final supabase = Supabase.instance.client;
      final userProvider = context.read<UserProvider>();
      final currentProfile = await userProvider.fetchCurrentUserProfile();
      final currentUserId = supabase.auth.currentUser?.id;
      String? hostId;

      if (widget.lobbyId.isNotEmpty) {
        final lobby = await supabase
            .from('lobbies')
            .select('host_id')
            .eq('room_code', widget.lobbyId)
            .maybeSingle();
        hostId = lobby?['host_id']?.toString();
      }

      hostId ??= widget.receiptData['owner_id']?.toString();
      if (hostId == null && widget.isHost) hostId = currentUserId;

      UserModel? hostProfile = currentProfile;
      if (hostId != null && hostId != currentProfile?.id) {
        final response = await supabase
            .from('profiles')
            .select()
            .eq('id', hostId)
            .maybeSingle();
        if (response != null) hostProfile = UserModel.fromMap(response);
      }

      if (mounted) {
        final emailName = hostProfile?.email?.split('@').first;
        setState(() {
          _currentUserId = currentUserId;
          _selectedUserId ??= currentUserId;
          _isCurrentUserHost = currentUserId != null && currentUserId == hostId;
          _hostPromptPay = hostProfile?.promptPayNumber ?? '';
          _hostPromptPayType = hostProfile?.promptPayType;
          _hostBankName = hostProfile?.bankName;
          _hostBankAccountNumber = hostProfile?.bankAccountNumber ?? '';
          _hostBankAccountName = hostProfile?.bankAccountName;
          _hostName = hostProfile?.displayName?.trim().isNotEmpty == true
              ? hostProfile!.displayName!.trim()
              : emailName ?? 'เจ้าของบิล';
        });
      }
    } catch (e) {
      debugPrint('ดึง PromptPay Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHost = false);
    }
  }

  List<BillItemModel> _getClaimedBillItems() {
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];
    return [
      for (var i = 0; i < items.length; i++) _claimedBillItem(items[i], i),
    ];
  }

  BillItemModel _claimedBillItem(dynamic rawItem, int index) {
    final item = Map<String, dynamic>.from(rawItem as Map);
    final unitPrice =
        double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
    final quantity =
        int.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
    final userQuantities = <String, int>{};
    final sharedUsers = <String>{};
    for (final sharer in widget.itemSharers[index] ?? []) {
      final userId = sharer['user_id']?.toString() ?? '';
      if (userId.isEmpty) continue;
      if (sharer['is_shared'] == true) sharedUsers.add(userId);
      final claimedQuantity = int.tryParse(
        sharer['quantity']?.toString() ?? '',
      );
      userQuantities[userId] =
          (userQuantities[userId] ?? 0) +
          (claimedQuantity ?? 1).clamp(0, quantity);
    }

    return BillItemModel(
      id: index.toString(),
      billId: widget.lobbyId,
      itemName: item['item_name']?.toString() ?? 'ไม่ระบุชื่อ',
      price: unitPrice,
      quantity: quantity,
      claimedBy: userQuantities.keys.toList(),
      userQuantities: userQuantities,
      sharedUsers: sharedUsers.toList(),
    );
  }

  Map<String, double> _calculateUserShares() {
    final finalTotal =
        double.tryParse(
          (widget.receiptData['final_total'] ??
                      widget.receiptData['total_amount'])
                  ?.toString() ??
              '',
        ) ??
        0.0;
    return BillProvider.calculateUserShares(
      items: _getClaimedBillItems(),
      finalTotal: finalTotal,
      splitType: context.read<BillProvider>().splitType,
      participantIds: _getRoomMemberIds(),
    );
  }

  List<String> _getRoomMemberIds() {
    final ids = widget.roomParticipants
        .map(
          (participant) =>
              participant['user_id']?.toString() ??
              participant['id']?.toString() ??
              '',
        )
        .where((userId) => userId.isNotEmpty)
        .toSet();

    for (final member in context.read<BillProvider>().roomMembers) {
      if (member.id.isNotEmpty) ids.add(member.id);
    }
    return ids.toList();
  }

  Map<String, List<String>> _getItemSharesByUser() {
    final itemsByUser = <String, List<String>>{};
    for (final item in _getClaimedBillItems()) {
      var remainingQuantity = item.quantity;
      for (final claim in item.userQuantities.entries) {
        final quantity = claim.value.clamp(0, remainingQuantity);
        if (quantity == 0) continue;
        remainingQuantity -= quantity;
        (itemsByUser[claim.key] ??= []).add(
          '${item.itemName} (ส่วนตัว $quantity ชิ้น): '
          '${AppFormatters.formatCurrency(item.price * quantity)}',
        );
      }
      final sharedUsers = item.sharedUsers.toSet();
      if (remainingQuantity <= 0 || sharedUsers.isEmpty) continue;
      final sharedPrice = item.price * remainingQuantity / sharedUsers.length;
      for (final userId in sharedUsers) {
        (itemsByUser[userId] ??= []).add(
          '${item.itemName} (แชร์ $remainingQuantity ชิ้น / '
          '${sharedUsers.length} คน): '
          '${AppFormatters.formatCurrency(sharedPrice)}',
        );
      }
    }
    return itemsByUser;
  }

  Map<String, String> _getUserNames() {
    final names = <String, String>{};
    for (final participant in widget.roomParticipants) {
      final userId =
          participant['user_id']?.toString() ?? participant['id']?.toString();
      if (userId == null || userId.isEmpty) continue;
      names[userId] =
          participant['user_name']?.toString() ??
          participant['display_name']?.toString() ??
          'เพื่อน';
    }
    for (final member in context.read<BillProvider>().roomMembers) {
      if (member.id.isNotEmpty) {
        names[member.id] = member.name;
      }
    }
    for (final sharers in widget.itemSharers.values) {
      for (final sharer in sharers) {
        final userId = sharer['user_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          names[userId] = sharer['user_name']?.toString() ?? 'เพื่อน';
        }
      }
    }
    return names;
  }

  bool _isGuestMember(String userId) {
    if (userId.startsWith('guest_')) return true;
    if (context.read<BillProvider>().roomMembers.any((m) => m.id == userId && m.isGuest)) {
      return true;
    }
    return widget.roomParticipants.any((participant) {
      final participantId =
          participant['user_id']?.toString() ?? participant['id']?.toString();
      return participantId == userId &&
          (participant['is_guest'] == true || participant['isGuest'] == true);
    });
  }

  final Map<String, bool> _manualPaidStatus = {};

  bool _isParticipantPaid(String userId) {
    if (_manualPaidStatus.containsKey(userId)) {
      return _manualPaidStatus[userId]!;
    }
    for (final sharers in widget.itemSharers.values) {
      for (final sharer in sharers) {
        if (sharer['user_id']?.toString() != userId) continue;
        final status = sharer['payment_status']?.toString().toLowerCase();
        if (sharer['is_paid'] == true ||
            status == 'paid' ||
            status == 'cleared' ||
            status == 'settled') {
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _saveAndFinish() async {
    if (_isFinishing) return;
    final splitType = context.read<BillProvider>().splitType;
    setState(() => _isFinishing = true);

    // 🚀 ถ้าเป็น Guest (หรือรันบน Web) แค่เตะกลับหน้า Home เลย ไม่ต้องเซฟลงฐานข้อมูลซ้ำซ้อน
    if (!_isCurrentUserHost) {
      await _navigateHomeAfterFrame();
      return;
    }

    var savedSuccessfully = false;

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'ไม่พบรหัสผู้ใช้งาน กรุณาล็อกอินใหม่';
      final userTotalsForDB = _calculateUserShares();
      final calculatedTotal = userTotalsForDB.values.fold<double>(
        0,
        (sum, amount) => sum + amount,
      );

      String? imageUrl;
      if (widget.receiptImageBytes != null) {
        imageUrl = await SupabaseStorageService().uploadReceiptBytes(
          widget.receiptImageBytes!,
          widget.lobbyId,
        );
      }

      final sharersJson = widget.itemSharers.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final finalTotal =
          double.tryParse(
            (widget.receiptData['final_total'] ??
                        widget.receiptData['total_amount'])
                    ?.toString() ??
                '',
          ) ??
          calculatedTotal;

      final insertedBill = await supabase
          .from('bills')
          .insert({
            'owner_id': userId,
            'shop_name': widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน',
            'sub_total': finalTotal,
            'image_url': imageUrl,
            'receipt_json': {
              ...widget.receiptData,
              'final_total': finalTotal,
              'total_amount': finalTotal,
              'split_type': splitType,
            },
            'sharers_json': sharersJson,
          })
          .select('id')
          .single();

      final String newBillId = insertedBill['id'].toString();

      final List<Map<String, dynamic>> participantsData = [];
      userTotalsForDB.forEach((uid, amount) {
        // 🚀 กรองไม่เอา 'guest_1234' ลงตาราง เพื่อป้องกัน UUID Error
        if (!uid.startsWith('guest_')) {
          participantsData.add({
            'bill_id': newBillId,
            'profile_id': uid,
            'amount_owed': amount,
          });
        }
      });

      if (participantsData.isNotEmpty) {
        await supabase.from('bill_participants').insert(participantsData);
      }
      savedSuccessfully = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && !savedSuccessfully) {
        setState(() => _isFinishing = false);
      }
    }

    if (savedSuccessfully && mounted) await _navigateHomeAfterFrame();
  }

  Future<void> _navigateHomeAfterFrame() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  String _tlv(String tag, String value) {
    return '$tag${value.length.toString().padLeft(2, '0')}$value';
  }

  String _generatePromptPayPayload(String target, double amount) {
    final cleanTarget = target.replaceAll(RegExp(r'[^0-9]'), '');
    late final String proxyField;

    if (_hostPromptPayType == 'phone' &&
        cleanTarget.length == 10 &&
        cleanTarget.startsWith('0')) {
      proxyField = _tlv('01', '0066${cleanTarget.substring(1)}');
    } else if (_hostPromptPayType == 'id_card' && cleanTarget.length == 13) {
      proxyField = _tlv('02', cleanTarget);
    } else {
      throw ArgumentError('Invalid PromptPay number for the selected type');
    }

    final merchantAccountInfo = _tlv(
      '29',
      _tlv('00', 'A000000677010111') + proxyField,
    );
    final amountField = _tlv('54', amount.toStringAsFixed(2));
    final payload =
        '000201'
        '${_tlv('01', '12')}'
        '$merchantAccountInfo'
        '${_tlv('52', '0000')}'
        '${_tlv('53', '764')}'
        '$amountField'
        '${_tlv('58', 'TH')}'
        '6304';

    return '$payload${_calculateCRC16(payload)}';
  }

  String _calculateCRC16(String payload) {
    int crc = 0xFFFF;
    for (int i = 0; i < payload.length; i++) {
      crc ^= (payload.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  Future<void> _showMemberPaymentDialog({
    required String memberId,
    required String memberName,
    required double amount,
  }) async {
    final bool canGenerateQr = _hasValidPromptPay && amount > 0;
    String qrPayload = '';
    if (canGenerateQr) {
      try {
        qrPayload = _generatePromptPayPayload(_hostPromptPay, amount);
      } catch (_) {}
    }

    final shopName = widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final currentPaid = _isParticipantPaid(memberId);
          return AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.secondary,
                  radius: 18,
                  child: Text(
                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(memberName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        'ยอดสุทธิ: ${AppFormatters.formatCurrency(amount)}',
                        style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (currentPaid) ...[
                    // 🎉 Shopee-style Payment Success View
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade300, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF00AA5B),
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ชำระเงินสำเร็จเรียบร้อยแล้ว! 🎉',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008A4B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ยอดชำระของ $memberName บันทึกเรียบร้อย',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ยอดชำระ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                '${AppFormatters.formatCurrency(amount)} ฿',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF00AA5B),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ผู้รับเงิน', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('$_hostName ($_hostPromptPay)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('สถานะ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Text('ชำระเงินแล้ว ✅', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else if (canGenerateQr && qrPayload.isNotEmpty) ...[
                    // ⏱️ Single-use dynamic QR with countdown reminder
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text('คิวอาร์โค้ดใช้ครั้งเดียว (Single-Use)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.brown)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 180,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primaryDark,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'พร้อมเพย์: $_hostPromptPay ($_hostName)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'สแกนจ่ายได้ทันที ยอด ฿${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('ยังไม่ได้ระบุเลขพร้อมเพย์ของเจ้าของบิล'),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ปุ่มทวงเงินเข้า LINE (เฉพาะคนที่ยังไม่จ่าย)
                  if (!currentPaid) ...[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF06C755),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('ส่งแจ้งเตือนทวงเงินเข้า LINE (สะกิด)'),
                      onPressed: () {
                        final bankInfo = _hasValidBankTransfer
                            ? '\n🏦 บัญชีธนาคาร: ${_hostBankName ?? ''} เลขบัญชี $_hostBankAccountNumber ($_hostName)'
                            : '';
                        final promptPayInfo = _hasValidPromptPay
                            ? '\n💳 พร้อมเพย์: $_hostPromptPay ($_hostName)'
                            : '';
                        final reminder = '👋 สวัสดี $memberName!\n'
                            '🍲 ยอดหารบิลร้าน $shopName ของคุณคือ ฿${amount.toStringAsFixed(2)}'
                            '$promptPayInfo$bankInfo\n'
                            '✨ โอนแล้วรบกวนส่งสลิปด้วยน้า ขอบคุณครับ/ค่ะ 🙏';
                        SharePlus.instance.share(
                          ShareParams(
                            title: 'ทวงเงินค่าอาหาร',
                            text: reminder,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ปุ่มแนบสลิปแจ้งโอน
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('แนบสลิปแจ้งโอนเงิน'),
                    onPressed: () async {
                      final picker = ImagePicker();
                      final file = await picker.pickImage(source: ImageSource.gallery);
                      if (file != null && mounted) {
                        setDialogState(() {
                          _manualPaidStatus[memberId] = true;
                        });
                        setState(() {
                          _manualPaidStatus[memberId] = true;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('แนบสลิปและบันทึกสถานะจ่ายแล้วให้ $memberName แล้ว')),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // สลับสถานะจ่ายแล้ว / รอจ่าย
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currentPaid ? 'สถานะ: จ่ายแล้ว ✅' : 'สถานะ: รอชำระ ⏳',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currentPaid ? Colors.green : Colors.orange.shade800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            _manualPaidStatus[memberId] = !currentPaid;
                          });
                          setState(() {
                            _manualPaidStatus[memberId] = !currentPaid;
                          });
                        },
                        child: Text(currentPaid ? 'เปลี่ยนเป็นรอจ่าย' : 'เปลี่ยนเป็นจ่ายแล้ว'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('ปิด'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final splitType = context.watch<BillProvider>().splitType;
    final totalsByUser = _calculateUserShares();
    final userNames = _getUserNames();
    final itemSharesByUser = _getItemSharesByUser();
    final shopName = widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';

    final calculatedTotal = totalsByUser.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );
    final billTotal =
        double.tryParse(
          (widget.receiptData['final_total'] ??
                      widget.receiptData['total_amount'])
                  ?.toString() ??
              '',
        ) ??
        calculatedTotal;
    final subTotal = double.tryParse(widget.receiptData['sub_total']?.toString() ?? '0') ?? (billTotal * 0.85);
    final scAmount = double.tryParse(widget.receiptData['service_charge']?.toString() ?? '0') ?? 0.0;
    final vatAmount = double.tryParse(widget.receiptData['vat_amount']?.toString() ?? '0') ?? 0.0;

    final selectedQrUserId = _isCurrentUserHost
        ? (_selectedUserId ?? _currentUserId)
        : _currentUserId;
    final selectedQrName = selectedQrUserId == null
        ? 'คุณ'
        : userNames[selectedQrUserId] ??
              (selectedQrUserId == _currentUserId
                  ? (_isCurrentUserHost ? _hostName : 'คุณ')
                  : 'เพื่อน');
    final qrAmount = selectedQrUserId == null
        ? 0.0
        : totalsByUser[selectedQrUserId] ?? 0.0;
    final displayedUserIds = _isCurrentUserHost
        ? totalsByUser.keys.toList()
        : (_currentUserId != null && totalsByUser.containsKey(_currentUserId)
              ? [_currentUserId!]
              : <String>[]);

    final activeUserIds = displayedUserIds
        .where((uid) => (totalsByUser[uid] ?? 0) > 0)
        .toList();
    final paidMembersCount = activeUserIds.where((uid) => _isParticipantPaid(uid)).length;
    final paidAmount = activeUserIds
        .where((uid) => _isParticipantPaid(uid))
        .fold<double>(0, (sum, uid) => sum + (totalsByUser[uid] ?? 0.0));
    final unpaidAmount = (billTotal - paidAmount).clamp(0.0, billTotal);
    final progress = billTotal > 0 ? (paidAmount / billTotal).clamp(0.0, 1.0) : 1.0;

    final allParticipantsPaid = activeUserIds.isNotEmpty &&
        activeUserIds.every((uid) => _isParticipantPaid(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สรุปยอดและชำระเงิน'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoadingHost
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step Indicator Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ขั้นตอน 5/6  สรุปยอดและชำระเงิน',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.restaurant_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(shopName, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Table Total Card (มียอดรวมทั้งโต๊ะ)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'มียอดรวมทั้งโต๊ะ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppFormatters.formatCurrency(billTotal),
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Breakdown Lines
                              _buildSummaryLine('ค่าอาหารรวม', subTotal),
                              if (scAmount > 0)
                                _buildSummaryLine('Service Charge (10%)', scAmount),
                              if (vatAmount > 0)
                                _buildSummaryLine('VAT (7%)', vatAmount),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  splitType == 'equal'
                                      ? '⚡ คำนวณ Service & VAT แบบหารเท่าเฉพาะคนที่กินจริง'
                                      : '⚡ คำนวณ Service & VAT ตามสัดส่วนจานที่แต่ละคนทานจริง',
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const Divider(height: 20, color: AppColors.border),

                              // Progress Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'ชำระแล้ว $paidMembersCount จาก ${activeUserIds.length} คน',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${AppFormatters.formatCurrency(paidAmount)} / ${AppFormatters.formatCurrency(billTotal)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppColors.border,
                                  color: AppColors.success,
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'คืบหน้า ${(progress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    'ยังค้างเบิก ${AppFormatters.formatCurrency(unpaidAmount)}',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.warning, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section สรุปรายบุคคล
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isCurrentUserHost ? 'สรุปรายบุคคล' : 'ส่วนของคุณ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${activeUserIds.length} ยอดเรียกเก็บ',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // รายการเพื่อนแต่ละคน
                        MemberSummaryList(
                          members: [
                            for (final userId in displayedUserIds)
                              MemberSummaryEntry(
                                id: userId,
                                name: userNames[userId] ?? 'เพื่อน',
                                amount: totalsByUser[userId] ?? 0.0,
                                isPaid: _isParticipantPaid(userId),
                                isGuest: _isGuestMember(userId),
                                subtitle: _isCurrentUserHost
                                    ? [
                                        _isParticipantPaid(userId)
                                            ? 'ชำระแล้ว'
                                            : 'รอชำระ',
                                        ...?itemSharesByUser[userId],
                                      ].join('\n')
                                    : (itemSharesByUser[userId]?.isNotEmpty == true
                                          ? itemSharesByUser[userId]!.join('\n')
                                          : null),
                              ),
                          ],
                          selectedMemberId: selectedQrUserId,
                          onMemberTap: (userId) {
                            setState(() => _selectedUserId = userId);
                            _showMemberPaymentDialog(
                              memberId: userId,
                              memberName: userNames[userId] ?? 'เพื่อน',
                              amount: totalsByUser[userId] ?? 0.0,
                            );
                          },
                          onStatusToggle: (member) {
                            final current = _isParticipantPaid(member.id);
                            setState(() {
                              _manualPaidStatus[member.id] = !current;
                            });
                          },
                        ),
                        const SizedBox(height: 14),

                        // PromptPay QR & บัญชีธนาคารสำหรับการโอน
                        if (_hasPaymentMethod && qrAmount > 0) ...[
                          PromptPayCard(
                            hostName: _hostName,
                            promptPayNumber: _hostPromptPay,
                            bankName: _hostBankName,
                            bankAccountNumber: _hostBankAccountNumber,
                            bankAccountName: _hostBankAccountName,
                            qrPayload: _hasValidPromptPay
                                ? _generatePromptPayPayload(
                                    _hostPromptPay,
                                    qrAmount,
                                  )
                                : '',
                            selectedUserName: selectedQrName,
                            amount: qrAmount,
                            isPaid: selectedQrUserId != null && _isParticipantPaid(selectedQrUserId),
                            onAttachSlip: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final picker = ImagePicker();
                              final file = await picker.pickImage(source: ImageSource.gallery);
                              if (file != null && mounted) {
                                if (selectedQrUserId != null) {
                                  setState(() {
                                    _manualPaidStatus[selectedQrUserId] = true;
                                  });
                                }
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text('แนบสลิปและบันทึกสถานะจ่ายแล้วให้ $selectedQrName แล้ว ✅'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                        ],

                        // แบนเนอร์ฉลองเมื่อจ่ายครบ 100%
                        if (allParticipantsPaid)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.celebration_rounded, color: Color(0xFF16A34A), size: 24),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🎉 ทุกคนชำระเงินครบ 100% แล้ว!',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF166534)),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'ยอดเงินครบตามบิลแล้ว เจ้าของบิลสามารถกดปิดบิลเสร็จสิ้นได้เลย',
                                        style: TextStyle(fontSize: 11, color: Color(0xFF15803D)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'ระบบจะส่งสลิปหลักฐานเข้ากลุ่ม LINE อัตโนมัติเมื่อทุกคนโอนครบ',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Action Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: const Border(top: BorderSide(color: AppColors.border)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        // ปุ่มแชร์บิลสรุปให้ทุกคนใน LINE (LINE Green)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF06C755), // LINE Green
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text(
                              'แชร์บิลสรุปให้ทุกคนใน LINE',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              final listNames = activeUserIds
                                  .map((uid) {
                                    final name = userNames[uid] ?? 'เพื่อน';
                                    final isPaid = _isParticipantPaid(uid);
                                    final amt = AppFormatters.formatCurrency(totalsByUser[uid] ?? 0);
                                    return '- $name: ฿$amt ${isPaid ? "(จ่ายแล้ว ✓)" : "(รอโอน ⏳)"}';
                                  })
                                  .join('\n');
                              final bankInfo = _hasValidBankTransfer
                                  ? '\n🏦 บัญชีธนาคาร: ${_hostBankName ?? ""} เลขบัญชี $_hostBankAccountNumber ($_hostName)'
                                  : '';
                              final promptPayInfo = _hasValidPromptPay
                                  ? '\n💳 พร้อมเพย์: $_hostPromptPay ($_hostName)'
                                  : '';
                              final msg = '🍲 สรุปยอดค่าอาหารร้าน "$shopName" 🍲\n'
                                  'ยอดรวมทั้งโต๊ะ: ${AppFormatters.formatCurrency(billTotal)} บาท\n\n'
                                  '📌 ยอดสรุปรายบุคคล:\n$listNames\n'
                                  '$promptPayInfo$bankInfo\n\n'
                                  '📲 โอนแล้วส่งสลิปแจ้งในกลุ่มได้เลยน้า ขอบคุณทุกคนมากครับ/ค่ะ 🙏✨';
                              SharePlus.instance.share(
                                ShareParams(
                                  title: 'สรุปบิลค่าอาหาร $shopName',
                                  text: msg,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // ปุ่มปิดบิลเสร็จสิ้น
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: allParticipantsPaid ? AppColors.success : AppColors.secondary,
                            foregroundColor: allParticipantsPaid ? Colors.white : AppColors.primary,
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          tooltip: _isCurrentUserHost ? 'ปิดบิลเสร็จสิ้น' : 'กลับหน้าแรก',
                          icon: _isFinishing
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check_rounded, size: 22),
                          onPressed: _isFinishing ? null : _saveAndFinish,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            AppFormatters.formatCurrency(amount),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

