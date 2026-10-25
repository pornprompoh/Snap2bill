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
import '../../../widgets/custom_button.dart';

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
  bool _hourlyReminderEnabled = true; // เปิดใช้งานระบบเตือนทุก 1 ชม. โดยเริ่มต้น

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
                        final reminder = '👋 สวัสดี $memberName!\n'
                            '🍲 ยอดหารบิลร้าน $shopName ของคุณคือ ฿${amount.toStringAsFixed(2)}\n'
                            '💳 พร้อมเพย์: $_hostPromptPay ($_hostName)\n'
                            '✨ สแกน QR โอนแล้วรบกวนส่งสลิปด้วยน้า ขอบคุณครับ/ค่ะ 🙏';
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
    final myShare = _currentUserId == null
        ? 0.0
        : totalsByUser[_currentUserId] ?? 0.0;
    final displayedAmount = _isCurrentUserHost ? billTotal : myShare;
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
    final allParticipantsPaid = activeUserIds.isNotEmpty &&
        activeUserIds.every((uid) => _isParticipantPaid(uid));
    final unpaidMembers = activeUserIds
        .where((uid) => !_isParticipantPaid(uid))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('สรุปยอดและเคลียร์บิล')),
      body: _isLoadingHost
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    color: Theme.of(context).colorScheme.primaryContainer,
                    width: double.infinity,
                    child: Column(
                      children: [
                        Text(
                          _isCurrentUserHost
                              ? 'ยอดรวมทั้งบิล'
                              : 'ยอดที่คุณต้องชำระ',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${AppFormatters.formatCurrency(displayedAmount)} ฿',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          splitType == 'equal'
                              ? '*ส่วนเกิน/VAT หารเท่าเฉพาะคนที่กินจริง (คนไม่กินจ่าย 0)'
                              : '*ส่วนเกิน/VAT หารตามสัดส่วนค่าอาหารที่เลือกกินจริง',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!_hasValidPromptPay) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'เจ้าของบิลยังไม่ได้ตั้งค่า PromptPay ในหน้าโปรไฟล์',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                          if (_isCurrentUserHost)
                            TextButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                context,
                                AppRoutes.profile,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('ตั้งค่า PromptPay'),
                            ),
                        ],
                      ],
                    ),
                  ),

                  // 🚀 3. แบนเนอร์ฉลองเมื่อทุกคนจ่ายครบ 100% แจ้งให้เจ้าของบิลมาปิดบิล
                  if (allParticipantsPaid)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green.shade400, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF00AA5B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.celebration, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🎉 สมาชิกทุกคนชำระเงินครบ 100% แล้ว!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'ยอดเงินครบตามบิลแล้ว เจ้าของบิลสามารถกดปิดบิลเสร็จสิ้นได้เลย',
                                      style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_isCurrentUserHost) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00AA5B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('แตะเพื่อปิดบิลนี้ทันที 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: _isFinishing ? null : _saveAndFinish,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'proportional',
                          icon: Icon(Icons.pie_chart_outline, size: 16),
                          label: Text('หารตามที่กินจริง'),
                        ),
                        ButtonSegment(
                          value: 'equal',
                          icon: Icon(Icons.people_outline, size: 16),
                          label: Text('หารเท่าเฉพาะคนที่กิน'),
                        ),
                      ],
                      selected: {splitType},
                      onSelectionChanged: (selection) {
                        context.read<BillProvider>().setSplitType(
                          selection.first,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ⏰ 2. การ์ดระบบแจ้งเตือนทวงเงินอัตโนมัติ ทุกๆ 1 ชม.
                  if (_isCurrentUserHost && !allParticipantsPaid && unpaidMembers.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.orange.shade900, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'ระบบแจ้งเตือนสะกิดทุก 1 ชม. (${unpaidMembers.length} คนยังไม่จ่าย)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                              Switch.adaptive(
                                value: _hourlyReminderEnabled,
                                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => _hourlyReminderEnabled = val);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(val
                                          ? 'เปิดระบบเตือนสะกิดทุก 1 ชม. สำหรับคนที่ยังไม่จ่ายแล้ว 🔔'
                                          : 'ปิดการเตือนรายชั่วโมงแล้ว'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF06C755),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 38),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.send, size: 16),
                            label: Text('📢 สะกิดเพื่อนที่ยังไม่จ่ายทุกคนเข้า LINE (${unpaidMembers.length} คน)'),
                            onPressed: () {
                              final shopName = widget.receiptData['shop_name'] ?? 'ร้านอาหาร';
                              final listNames = unpaidMembers
                                  .map((uid) => '- ${userNames[uid] ?? 'เพื่อน'}: ฿${AppFormatters.formatCurrency(totalsByUser[uid] ?? 0)}')
                                  .join('\n');
                              final msg = '📢 สะกิดเตือนตี้บิล "$shopName" จ้า (เตือนอัตโนมัติทุก 1 ชม.)\n'
                                  '🍲 สมาชิกที่มียอดค้างชำระ:\n$listNames\n'
                                  '💳 พร้อมเพย์: $_hostPromptPay ($_hostName)\n'
                                  '✨ โอนแล้วรบกวนส่งสลิปด้วยน้า ขอบคุณครับ/ค่ะ 🙏';
                              SharePlus.instance.share(
                                ShareParams(
                                  title: 'สะกิดเตือนเพื่อนจ่ายเงิน',
                                  text: msg,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isCurrentUserHost
                            ? 'ยอดชำระและสถานะของเพื่อน'
                            : 'ส่วนแบ่งของคุณ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
                  const Divider(thickness: 2),
                  const SizedBox(height: 16),

                  if (_hasValidPromptPay && qrAmount > 0) ...[
                    const SizedBox(height: 8),
                    PromptPayCard(
                      hostName: _hostName,
                      promptPayNumber: _hostPromptPay,
                      qrPayload: _generatePromptPayPayload(
                        _hostPromptPay,
                        qrAmount,
                      ),
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
                  ],

                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    // 🚀 ถ้าเป็น Host ถึงจะขึ้นปุ่มเซฟบิลสีเขียว ถ้าเป็น Guest จะเป็นปุ่ม "กลับหน้าแรก" เฉยๆ ไม่แตะฐานข้อมูล
                    child: CustomButton(
                      text: _isCurrentUserHost
                          ? (allParticipantsPaid ? 'ปิดบิลเสร็จสมบูรณ์ 🎉' : 'เสร็จสิ้นการหารบิล')
                          : 'กลับหน้าแรก',
                      backgroundColor: _isCurrentUserHost
                          ? AppColors.success
                          : Theme.of(context).colorScheme.primary,
                      isLoading: _isFinishing,
                      onPressed: _isFinishing ? null : _saveAndFinish,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
