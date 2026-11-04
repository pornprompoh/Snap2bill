import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/bill/member_summary_list.dart';
import '../../utils/bill_progress_helper.dart';
import '../../widgets/bill/poke_reminder_dialog.dart';
import '../../widgets/bill/shareable_receipt_preview_dialog.dart';
import '../../widgets/bill/receipt_image.dart';
import '../../services/offline/offline_service.dart';
import '../../widgets/common/mascot_state_view.dart';
import 'personal_payment_details_screen.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> billData;

  const DetailScreen({super.key, required this.billData});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<List<MemberSummaryEntry>> _membersFuture;
  final GlobalKey _receiptCaptureKey = GlobalKey();
  RealtimeChannel? _billRealtimeChannel;
  String _hostPromptPay = '';
  String? _hostPromptPayType;
  String? _hostBankName;
  String _hostBankAccountNumber = '';
  String? _hostBankAccountName;
  String _hostName = 'เจ้าของบิล';

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMemberSummary();
    _fetchHostPromptPayInfo();
    _setupRealtimeBillSubscription();
  }

  void _setupRealtimeBillSubscription() {
    final billId = widget.billData['id']?.toString();
    if (billId == null || billId.isEmpty) return;

    final channel = Supabase.instance.client.channel('bill_detail_$billId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bills',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: billId,
        ),
        callback: (_) => unawaited(_refreshBillFromRealtime()),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bill_participants',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'bill_id',
          value: billId,
        ),
        callback: (_) => _refreshMemberSummary(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bill_payments',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'bill_id',
          value: billId,
        ),
        callback: (_) => _refreshMemberSummary(),
      );
    _billRealtimeChannel = channel;
    channel.subscribe((status, error) {
      if (error != null) {
        debugPrint('Bill detail Realtime subscription error: $error');
      }
      if (status != RealtimeSubscribeStatus.subscribed && error != null) {
        debugPrint('Bill detail Realtime status: $status');
      }
    });
  }

  void _refreshMemberSummary() {
    if (!mounted) return;
    setState(() => _membersFuture = _loadMemberSummary());
  }

  Future<void> _refreshBillFromRealtime() async {
    final billId = widget.billData['id']?.toString();
    if (billId == null || billId.isEmpty) return;

    try {
      final bill = await Supabase.instance.client
          .from('bills')
          .select()
          .eq('id', billId)
          .maybeSingle();
      if (bill == null || !mounted) return;
      widget.billData.addAll(Map<String, dynamic>.from(bill));
      _refreshMemberSummary();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to refresh bill after Realtime update: $error\n$stackTrace',
      );
    }
  }

  @override
  void dispose() {
    final channel = _billRealtimeChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    super.dispose();
  }

  Future<void> _fetchHostPromptPayInfo() async {
    try {
      final ownerId =
          widget.billData['owner_id']?.toString() ??
          Supabase.instance.client.auth.currentUser?.id;
      if (ownerId != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', ownerId)
            .maybeSingle();
        if (profile != null && mounted) {
          final paymentInfo = _asMap(profile['payment_info']);
          setState(() {
            _hostPromptPay =
                profile['promptpay_number']?.toString() ??
                paymentInfo['number']?.toString() ??
                '';
            _hostPromptPayType =
                profile['promptpay_type']?.toString() ??
                paymentInfo['type']?.toString();
            _hostBankName = paymentInfo['bank_name']?.toString();
            _hostBankAccountNumber =
                paymentInfo['bank_account_number']?.toString() ?? '';
            _hostBankAccountName = paymentInfo['bank_account_name']?.toString();
            final name = profile['display_name']?.toString().trim();
            _hostName = name?.isNotEmpty == true
                ? name!
                : profile['email']?.toString().split('@').first ?? 'เจ้าของบิล';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching host promptpay: $e');
    }
  }

  Future<List<MemberSummaryEntry>> _loadMemberSummary() async {
    final receipt = _asMap(widget.billData['receipt_json']);
    final sharersByItem = _asMap(widget.billData['sharers_json']);
    final billId = widget.billData['id']?.toString();
    List<dynamic> participantRows = [];
    List<dynamic> paymentRows = [];
    if (billId != null) {
      try {
        participantRows = await Supabase.instance.client
            .from('bill_participants')
            .select('profile_id, amount_owed, status')
            .eq('bill_id', billId);
        paymentRows = await Supabase.instance.client
            .from('bill_payments')
            .select('profile_id, status, slip_data')
            .eq('bill_id', billId);
      } catch (error) {
        if (!OfflineService.isLikelyNetworkError(error)) rethrow;
        debugPrint('Using cached bill participants: $error');
      }
    }
    final paymentsByProfileId = <String, Map<String, dynamic>>{
      for (final row in paymentRows)
        if (row['profile_id'] != null)
          row['profile_id'].toString(): Map<String, dynamic>.from(row),
    };
    widget.billData['bill_payments'] = paymentRows;
    final cachedPayments = _asMap(widget.billData['payment_updates']);

    final profileIds = participantRows
        .map((row) => row['profile_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final namesById = <String, String>{};

    final items = <BillItemModel>[];
    final rawItems = _asList(receipt['items']);
    for (var index = 0; index < rawItems.length; index++) {
      final rawItem = _asMap(rawItems[index]);
      final personalQuantities = <String, int>{};
      final sharedUsers = <String>{};
      final itemSharers = _asList(sharersByItem[index.toString()]);

      for (final rawSharer in itemSharers) {
        final sharer = _asMap(rawSharer);
        final userId = sharer['user_id']?.toString() ?? '';
        if (userId.isEmpty) continue;
        final userName = sharer['user_name']?.toString();
        if (userName?.isNotEmpty == true) namesById[userId] = userName!;
        final quantity =
            int.tryParse(sharer['quantity']?.toString() ?? '') ?? 0;
        if (quantity > 0) personalQuantities[userId] = quantity;
        if (sharer['is_shared'] == true) sharedUsers.add(userId);
      }

      final rawClaims =
          rawItem['userQuantities'] ??
          rawItem['claims'] ??
          rawItem['user_quantities'];
      if (itemSharers.isEmpty && rawClaims is Map) {
        rawClaims.forEach((userId, quantity) {
          final count = int.tryParse(quantity.toString()) ?? 0;
          if (count > 0) personalQuantities[userId.toString()] = count;
        });
      }
      if (itemSharers.isEmpty) {
        final rawShared =
            rawItem['sharedUsers'] ??
            rawItem['shared_claims'] ??
            rawItem['shared_users'];
        if (rawShared is List) {
          sharedUsers.addAll(rawShared.map((id) => id.toString()));
        }
      }

      final quantity =
          int.tryParse(
            (rawItem['qty'] ?? rawItem['quantity'] ?? 1).toString(),
          ) ??
          1;
      items.add(
        BillItemModel(
          id: index.toString(),
          billId: billId ?? '',
          itemName: rawItem['item_name']?.toString() ?? 'ไม่มีชื่อ',
          price:
              double.tryParse(
                (rawItem['unit_price'] ?? rawItem['price'] ?? 0).toString(),
              ) ??
              0,
          quantity: quantity,
          userQuantities: personalQuantities,
          sharedUsers: sharedUsers.toList(),
          claimedBy: personalQuantities.keys.toList(),
        ),
      );
    }

    for (final item in items) {
      profileIds.addAll(
        item.userQuantities.keys.where((id) => !id.startsWith('guest_')),
      );
      profileIds.addAll(
        item.sharedUsers.where((id) => !id.startsWith('guest_')),
      );
    }
    final profilesById = <String, Map<String, dynamic>>{};
    if (profileIds.isNotEmpty) {
      try {
        final profiles = await Supabase.instance.client
            .from('profiles')
            .select('id, display_name, email')
            .inFilter('id', profileIds.toList());
        for (final profile in profiles) {
          profilesById[profile['id'].toString()] = Map<String, dynamic>.from(
            profile,
          );
        }
      } catch (error) {
        if (!OfflineService.isLikelyNetworkError(error)) rethrow;
        debugPrint('Using cached member names: $error');
      }
    }
    for (final profile in profilesById.entries) {
      final name = profile.value['display_name']?.toString().trim();
      namesById.putIfAbsent(
        profile.key,
        () => name?.isNotEmpty == true
            ? name!
            : profile.value['email']?.toString().split('@').first ?? 'เพื่อน',
      );
    }

    final participantIds = <String>{
      ...profileIds,
      for (final item in items) ...item.userQuantities.keys,
      for (final item in items) ...item.sharedUsers,
    };
    final finalTotal =
        double.tryParse(
          (receipt['final_total'] ??
                  receipt['total_amount'] ??
                  widget.billData['sub_total'] ??
                  0)
              .toString(),
        ) ??
        0;
    final calculatedShares = BillProvider.calculateUserShares(
      items: items,
      finalTotal: finalTotal,
      splitType: receipt['split_type']?.toString() ?? 'proportional',
      participantIds: participantIds,
    );

    final ownerId =
        widget.billData['owner_id']?.toString() ??
        widget.billData['user_id']?.toString() ??
        receipt['owner_id']?.toString() ??
        '';
    String currentUserId = '';
    try {
      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      currentUserId = currentAuthUser?.id ?? '';
    } catch (_) {}

    bool checkIsOwner(String mid) {
      if (ownerId.isNotEmpty) return mid == ownerId;
      return currentUserId.isNotEmpty && mid == currentUserId;
    }

    final receiptPaidStatuses = _asMap(receipt['paid_statuses']);
    final paymentSlips = _asMap(receipt['payment_slips']);

    final entriesById = <String, MemberSummaryEntry>{};
    for (final id in participantIds) {
      final profile = profilesById[id];
      final name =
          namesById[id] ??
          profile?['display_name']?.toString() ??
          (id.startsWith('guest_') ? 'Guest' : 'เพื่อน');
      final isOwner = checkIsOwner(id);
      final payment = paymentsByProfileId[id] ?? _asMap(cachedPayments[id]);

      // Extract this member's dishes
      final memberDishes = <MemberDishItem>[];
      for (final item in items) {
        final personalQty = item.userQuantities[id] ?? 0;
        if (personalQty > 0) {
          memberDishes.add(
            MemberDishItem(
              itemName: item.itemName,
              quantity: personalQty,
              isShared: false,
              totalSharers: 1,
              unitPrice: item.price,
              totalPrice: (personalQty * item.price).ceilToDouble(),
            ),
          );
        }
        if (item.sharedUsers.contains(id)) {
          final personalClaimsCount = item.userQuantities.values.fold<int>(
            0,
            (a, b) => a + b,
          );
          final sharedQuantity = (item.quantity - personalClaimsCount).clamp(
            0,
            item.quantity,
          );
          final sharersCount = item.sharedUsers.length;
          if (sharedQuantity > 0 && sharersCount > 0) {
            final sharePrice = (item.price * sharedQuantity / sharersCount)
                .ceilToDouble();
            memberDishes.add(
              MemberDishItem(
                itemName: item.itemName,
                quantity: sharedQuantity,
                isShared: true,
                totalSharers: sharersCount,
                unitPrice: item.price,
                totalPrice: sharePrice,
              ),
            );
          }
        }
      }

      final paymentStatus = payment['status']?.toString().toLowerCase();
      final rawStatus =
          paymentStatus ??
          receiptPaidStatuses[id]?.toString().toLowerCase() ??
          'pending';
      final slipUrl =
          payment['slip_data']?.toString() ?? paymentSlips[id]?.toString();
      final effectiveStatus = isOwner
          ? 'owner'
          : (rawStatus == 'paid'
                ? 'paid'
                : (rawStatus == 'reviewing' ||
                          (slipUrl != null && slipUrl.isNotEmpty)
                      ? 'reviewing'
                      : 'pending'));

      entriesById[id] = MemberSummaryEntry(
        id: id,
        name: name,
        amount: calculatedShares[id] ?? 0,
        status: effectiveStatus,
        isGuest: id.startsWith('guest_'),
        isOwner: isOwner,
        isPaid: isOwner ? true : (effectiveStatus == 'paid'),
        itemsCount: memberDishes.length,
        dishes: memberDishes,
        slipUrl: slipUrl,
      );
    }

    for (final row in participantRows) {
      final id = row['profile_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final rowStatus = row['status']?.toString().toLowerCase() ?? '';
      final existing = entriesById[id];
      if (existing == null) continue;
      final isOwner = existing.isOwner;
      final payment = paymentsByProfileId[id] ?? _asMap(cachedPayments[id]);
      final paymentStatus = payment['status']?.toString().toLowerCase();
      final slipUrl =
          payment['slip_data']?.toString() ??
          existing.slipUrl ??
          paymentSlips[id]?.toString();

      final effectiveStatus = isOwner
          ? 'owner'
          : (paymentStatus != null
                ? (paymentStatus == 'paid'
                      ? 'paid'
                      : (paymentStatus == 'reviewing'
                            ? 'reviewing'
                            : 'pending'))
                : (rowStatus == 'paid' ||
                          rowStatus == 'cleared' ||
                          rowStatus == 'settled' ||
                          existing.status == 'paid'
                      ? 'paid'
                      : (rowStatus == 'reviewing' ||
                                rowStatus == 'pending_verification' ||
                                existing.status == 'reviewing' ||
                                (slipUrl != null && slipUrl.isNotEmpty)
                            ? 'reviewing'
                            : 'pending')));

      entriesById[id] = existing.copyWith(
        amount:
            double.tryParse(row['amount_owed']?.toString() ?? '') ??
            existing.amount,
        status: effectiveStatus,
        isPaid: isOwner ? true : (effectiveStatus == 'paid'),
        isReviewing: isOwner ? false : (effectiveStatus == 'reviewing'),
        slipUrl: slipUrl,
      );
    }

    return entriesById.values.toList()..sort((a, b) {
      if (a.isOwner) return -1;
      if (b.isOwner) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  bool get _isCurrentUserOwner {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final ownerId =
        widget.billData['owner_id']?.toString() ??
        widget.billData['user_id']?.toString() ??
        _asMap(widget.billData['receipt_json'])['owner_id']?.toString();
    return currentUserId != null && ownerId != null && currentUserId == ownerId;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        debugPrint('Invalid payment_info JSON in profile.');
      }
    }
    return {};
  }

  List<dynamic> _asList(Object? value) {
    if (value is List) return List<dynamic>.from(value);
    return const [];
  }

  void _openReceiptFullView(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  tooltip: 'ปิดรูปภาพ',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptImage(Object? rawImageUrl) {
    final imageUrl = rawImageUrl?.toString().trim() ?? '';
    final uri = Uri.tryParse(imageUrl);
    final isValidUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValidUrl) {
      return _buildMissingReceiptImage();
    }

    return Semantics(
      button: true,
      label: 'แตะเพื่อดูรูปใบเสร็จแบบเต็ม',
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ReceiptImage(
            imageUrl: imageUrl,
            height: 300,
            width: double.infinity,
            fit: BoxFit.cover,
            onTap: _openReceiptFullView,
            errorBuilder: (context, error) {
              debugPrint('Receipt image failed to load: $imageUrl - $error');
              return _buildMissingReceiptImage();
            },
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'ดูรูปเต็ม',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingReceiptImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'ไม่พบรูปใบเสร็จของบิลนี้',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // 💳 สลับสถานะชำระเงิน (Paid / Pending) และอัปเดตลง Supabase (Week 9 Cloud)
  Future<void> _handleStatusToggle(MemberSummaryEntry member) async {
    if (member.isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เจ้าของรายการไม่ต้องชำระเงินให้ตนเอง')),
      );
      return;
    }

    if (!_isCurrentUserOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'เฉพาะเจ้าของรายการเท่านั้นที่มีสิทธิ์เปลี่ยนสถานะการชำระเงิน',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final billId = widget.billData['id']?.toString();
    if (billId == null) return;

    final newStatus = member.isPaid ? 'pending' : 'paid';
    try {
      await Supabase.instance.client.rpc(
        'set_bill_payment_status',
        params: {
          'p_bill_id': billId,
          'p_profile_id': member.id,
          'p_status': newStatus,
        },
      );
      final paymentUpdates = _asMap(widget.billData['payment_updates']);
      paymentUpdates[member.id] = {
        'status': newStatus,
        'slip_data': newStatus == 'pending' ? null : member.slipUrl,
      };
      widget.billData['payment_updates'] = paymentUpdates;

      final updatedMembers = await _loadMemberSummary();

      setState(() {
        _membersFuture = Future.value(updatedMembers);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'paid'
                  ? 'อัปเดต: ${member.name} ชำระเงินแล้ว ✅'
                  : 'อัปเดต: ${member.name} รอจ่าย ⏳',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: newStatus == 'paid'
                ? AppColors.success
                : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตสถานะการชำระเงินไม่สำเร็จ กรุณาลองอีกครั้ง'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // 📤 เปิดหน้าต่างสร้างและแชร์บิลสรุปสำเร็จรูป (Shareable Bill Summary)
  void _openShareableReceiptDialog() {
    ShareableReceiptPreviewDialog.show(
      context,
      bill: widget.billData,
      hostPromptPay: _hostPromptPay,
      hostPromptPayType: _hostPromptPayType,
      hostBankAccount: _hostBankAccountNumber,
      hostBankName: _hostBankName,
      hostName: _hostName,
      isCurrentViewerOwner: _isCurrentUserOwner,
      onPromptPayUpdated: (promptPay, promptPayType, hostName) {
        setState(() {
          _hostPromptPay = promptPay;
          _hostPromptPayType = promptPayType;
          if (hostName != null && hostName.isNotEmpty) {
            _hostName = hostName;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billSummary = BillProgressHelper.calculate(widget.billData);
    final shopName = widget.billData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final createdAt =
        widget.billData['created_at']?.toString().split('T')[0] ?? '';
    final imageUrl =
        widget.billData['image_url'] ?? widget.billData['receipt_image_url'];
    final receiptJson = _asMap(widget.billData['receipt_json']);
    final items = _asList(receiptJson['items']);
    final sharersJson = _asMap(widget.billData['sharers_json']);

    final subTotal =
        double.tryParse(receiptJson['sub_total']?.toString() ?? '0') ?? 0;
    final vatAmount =
        double.tryParse(receiptJson['vat_amount']?.toString() ?? '0') ?? 0;
    final serviceCharge =
        double.tryParse(receiptJson['service_charge']?.toString() ?? '0') ?? 0;
    final discount =
        double.tryParse(receiptJson['discount']?.toString() ?? '0') ?? 0;
    final totalAmount =
        double.tryParse(
          (receiptJson['final_total'] ??
                  receiptJson['total_amount'] ??
                  widget.billData['sub_total'] ??
                  '0')
              .toString(),
        ) ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดบิลย้อนหลัง'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.primaryOrange,
            ),
            tooltip: 'สะกิดเตือนเพื่อน',
            onPressed: () {
              PokeReminderDialog.show(
                context,
                bill: widget.billData,
                hostPromptPay: _hostPromptPay,
                hostBankAccount: _hostBankAccountNumber,
                hostBankName: _hostBankName,
                hostName: _hostName,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'แชร์บิลสรุปสำเร็จรูป',
            onPressed: _openShareableReceiptDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: RepaintBoundary(
          key: _receiptCaptureKey,
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null && imageUrl.toString().trim().isNotEmpty)
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildReceiptImage(imageUrl),
                    ),
                  ),
                const SizedBox(height: 16),
                Hero(
                  tag: 'bill_${widget.billData['id']}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      shopName.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    'วันที่: $createdAt',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkCardBackground
                        : AppColors.paleYellow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkBorder
                          : AppColors.primaryOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow('ยอดรวม (Subtotal)', subTotal),
                      if (serviceCharge > 0)
                        _buildSummaryRow('Service Charge', serviceCharge),
                      if (vatAmount > 0) _buildSummaryRow('VAT', vatAmount),
                      if (discount > 0)
                        _buildSummaryRow(
                          'ส่วนลด',
                          -discount,
                          color: AppColors.error,
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'ยอดสุทธิ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                totalAmount > 0
                                    ? AppFormatters.formatCurrency(totalAmount)
                                    : 'ยังไม่มีข้อมูลยอดบิล',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.tealGreen,
                                ),
                              ),
                              if (totalAmount > 0 &&
                                  billSummary.averagePerPerson > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'ตกคนละ ${AppFormatters.formatCurrency(billSummary.averagePerPerson)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealGreen,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, size: 20),
                  label: const Text(
                    'สร้างและแชร์บิลสรุปสำเร็จรูป (รูปบิลใบเสร็จ)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _openShareableReceiptDialog,
                ),
                const SizedBox(height: 20),
                const Text(
                  'รายการที่สั่ง (รายละเอียด)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final rawItem = _asMap(items[index]);
                    final itemName =
                        rawItem['item_name']?.toString() ?? 'ไม่มีชื่อ';
                    final qty =
                        int.tryParse(
                          (rawItem['qty'] ?? rawItem['quantity'] ?? 1)
                              .toString(),
                        ) ??
                        1;
                    final unitPrice =
                        double.tryParse(
                          (rawItem['unit_price'] ?? rawItem['price'] ?? 0)
                              .toString(),
                        ) ??
                        0;
                    final totalPrice =
                        double.tryParse(
                          rawItem['total_price']?.toString() ?? '',
                        ) ??
                        qty * unitPrice;
                    final itemSharers = _asList(sharersJson[index.toString()]);
                    final userQuantities = <String, int>{};
                    final namesByUserId = <String, String>{};
                    final sharedUsers = <String, String>{};

                    for (final rawSharer in itemSharers) {
                      final sharer = _asMap(rawSharer);
                      final userId = sharer['user_id']?.toString() ?? '';
                      if (userId.isEmpty) continue;
                      final name = sharer['user_name']?.toString() ?? 'ไม่ระบุ';
                      namesByUserId[userId] = name;
                      final claimedQuantity =
                          int.tryParse(sharer['quantity']?.toString() ?? '') ??
                          0;
                      if (claimedQuantity > 0) {
                        userQuantities[userId] =
                            (userQuantities[userId] ?? 0) + claimedQuantity;
                      }
                      if (sharer['is_shared'] == true) {
                        sharedUsers[userId] = name;
                      }
                    }

                    if (itemSharers.isEmpty) {
                      final claims =
                          rawItem['userQuantities'] ??
                          rawItem['claims'] ??
                          rawItem['user_quantities'];
                      if (claims is Map) {
                        claims.forEach((userId, amount) {
                          final id = userId.toString();
                          final claimedQuantity =
                              int.tryParse(amount.toString()) ?? 0;
                          if (claimedQuantity > 0) {
                            userQuantities[id] = claimedQuantity;
                            namesByUserId[id] = id.startsWith('guest_')
                                ? 'Guest'
                                : id;
                          }
                        });
                      }
                      final shared =
                          rawItem['sharedUsers'] ??
                          rawItem['shared_claims'] ??
                          rawItem['shared_users'];
                      if (shared is List) {
                        for (final userId in shared) {
                          sharedUsers[userId.toString()] =
                              userId.toString().startsWith('guest_')
                              ? 'Guest'
                              : userId.toString();
                        }
                      }
                    }

                    final personalQuantity = userQuantities.values.fold<int>(
                      0,
                      (sum, amount) => sum + amount,
                    );
                    final sharedQuantity = (qty - personalQuantity).clamp(
                      0,
                      qty,
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        itemName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '$qty x ${AppFormatters.formatCurrency(unitPrice)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  AppFormatters.formatCurrency(totalPrice),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (userQuantities.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '👤 ส่วนตัว: ${userQuantities.entries.map((entry) => '${namesByUserId[entry.key] ?? entry.key}: ${entry.value} ชิ้น').join(', ')}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (sharedUsers.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '🤝 แชร์ร่วมกัน ($sharedQuantity ชิ้น): ${sharedUsers.values.join(', ')}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'สรุปยอดชำระและสถานะของเพื่อน',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                FutureBuilder<List<MemberSummaryEntry>>(
                  future: _membersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: MascotStateView(
                            state: MascotState.error,
                            message: 'โหลดสรุปยอดไม่สำเร็จ',
                            detail: 'ลองเปิดหน้านี้ใหม่อีกครั้ง',
                            size: 96,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('ไม่มีข้อมูลยอดชำระรายบุคคล'),
                      );
                    }
                    return MemberSummaryList(
                      members: snapshot.data!,
                      isCurrentViewerOwner: _isCurrentUserOwner,
                      onMemberTap: (memberId) async {
                        final matchingMembers = snapshot.data!.where(
                          (m) => m.id == memberId,
                        );
                        if (matchingMembers.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ไม่พบข้อมูลสมาชิกของบิลนี้'),
                              ),
                            );
                          }
                          return;
                        }
                        final member = matchingMembers.first;
                        final receipt = _asMap(widget.billData['receipt_json']);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonalPaymentDetailsScreen(
                              billData: widget.billData,
                              member: member,
                              hostPromptPay: _hostPromptPay,
                              hostPromptPayType: _hostPromptPayType,
                              hostBankName: _hostBankName,
                              hostBankAccountNumber: _hostBankAccountNumber,
                              hostBankAccountName: _hostBankAccountName,
                              hostName: _hostName,
                              isCurrentViewerOwner: _isCurrentUserOwner,
                              receiptSubTotal:
                                  double.tryParse(
                                    receipt['sub_total']?.toString() ?? '0',
                                  ) ??
                                  0.0,
                              receiptVat:
                                  double.tryParse(
                                    receipt['vat_amount']?.toString() ?? '0',
                                  ) ??
                                  0.0,
                              receiptServiceCharge:
                                  double.tryParse(
                                    receipt['service_charge']?.toString() ??
                                        '0',
                                  ) ??
                                  0.0,
                              receiptDiscount:
                                  double.tryParse(
                                    receipt['discount']?.toString() ?? '0',
                                  ) ??
                                  0.0,
                              onStatusChanged: (newStatus, slipUrl) {
                                setState(() {
                                  _membersFuture = _loadMemberSummary();
                                });
                              },
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            _membersFuture = _loadMemberSummary();
                          });
                        }
                      },
                      onStatusToggle: _handleStatusToggle,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}
