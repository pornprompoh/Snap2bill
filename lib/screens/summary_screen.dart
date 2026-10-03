import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/bill_model.dart';
import '../../models/user_model.dart';
import '../../providers/bill_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/supabase_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

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
    return widget.roomParticipants
        .map(
          (participant) =>
              participant['user_id']?.toString() ??
              participant['id']?.toString() ??
              '',
        )
        .where((userId) => userId.isNotEmpty)
        .toSet()
        .toList();
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

  bool _isParticipantPaid(String userId) {
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
              'split_type': context.read<BillProvider>().splitType,
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

  void _showPromptPayDialog(String userName, double amount) {
    if (!_hasValidPromptPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เจ้าของบิลยังไม่ได้ตั้งค่าเบอร์ PromptPay'),
        ),
      );
      return;
    }

    final String qrPayload = _generatePromptPayPayload(_hostPromptPay, amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.qr_code_2, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              'สแกนจ่ายให้ $_hostName\n($_hostPromptPay)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'ยอดชำระ: ${AppFormatters.formatCurrency(amount)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
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
    final qrAmount = _isCurrentUserHost ? billTotal : myShare;
    final displayedUserIds = _isCurrentUserHost
        ? totalsByUser.keys.toList()
        : (_currentUserId != null && totalsByUser.containsKey(_currentUserId)
              ? [_currentUserId!]
              : <String>[]);

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
                              ? '*ส่วนเกินหารเท่ากันในสมาชิกทุกคน'
                              : '*ส่วนเกินหารตามสัดส่วนค่าอาหารที่เลือก',
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
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'equal',
                          label: Text('หารส่วนเกินเท่ากัน'),
                        ),
                        ButtonSegment(
                          value: 'proportional',
                          label: Text('หารตามสัดส่วนที่กิน'),
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _isCurrentUserHost
                            ? 'ยอดชำระและสถานะของเพื่อน'
                            : 'ส่วนแบ่งของคุณ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedUserIds.length,
                    itemBuilder: (context, index) {
                      final userId = displayedUserIds[index];
                      final name = userNames[userId] ?? 'เพื่อน';
                      final amount = totalsByUser[userId] ?? 0.0;
                      final paid = _isParticipantPaid(userId);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: paid
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          child: Icon(
                            paid
                                ? Icons.check_circle_outline
                                : Icons.pending_outlined,
                            color: paid
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                          ),
                        ),
                        title: Text(name),
                        subtitle: _isCurrentUserHost
                            ? Text(
                                [
                                  paid ? 'ชำระแล้ว' : 'รอชำระ',
                                  ...?itemSharesByUser[userId],
                                ].join('\n'),
                              )
                            : (itemSharesByUser[userId]?.isNotEmpty == true
                                  ? Text(itemSharesByUser[userId]!.join('\n'))
                                  : null),
                        trailing: Text(AppFormatters.formatCurrency(amount)),
                        onTap: _hasValidPromptPay
                            ? () => _showPromptPayDialog(name, amount)
                            : null,
                      );
                    },
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 16),

                  if (_hasValidPromptPay && qrAmount > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryDark.withValues(
                              alpha: 0.06,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'PROMPTPAY',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'ชำระให้ $_hostName',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: QrImageView(
                                data: _generatePromptPayPayload(
                                  _hostPromptPay,
                                  qrAmount,
                                ),
                                version: QrVersions.auto,
                                size: 190,
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
                            const SizedBox(height: 12),
                            Text(
                              _hostPromptPay,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.35,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _isCurrentUserHost
                                          ? 'ยอดรวมบิล'
                                          : 'ยอดที่คุณต้องชำระ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.formatCurrency(qrAmount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.primaryDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    // 🚀 ถ้าเป็น Host ถึงจะขึ้นปุ่มเซฟบิลสีเขียว ถ้าเป็น Guest จะเป็นปุ่ม "กลับหน้าแรก" เฉยๆ ไม่แตะฐานข้อมูล
                    child: CustomButton(
                      text: _isCurrentUserHost
                          ? 'เสร็จสิ้นการหารบิล'
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
