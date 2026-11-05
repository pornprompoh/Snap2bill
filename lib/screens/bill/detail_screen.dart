import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../data/repositories/local_bill_repository.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/bill/member_summary_list.dart';
import '../../utils/bill_progress_helper.dart';
import '../../widgets/bill/poke_reminder_dialog.dart';
import '../../widgets/bill/shareable_receipt_preview_dialog.dart';
import '../../widgets/bill/receipt_image.dart';
import '../../services/offline/offline_service.dart';
import '../../services/storage/local_receipt_storage.dart';
import '../../services/storage/supabase_storage_service.dart';
import '../../widgets/common/mascot_state_view.dart';
import 'personal_payment_details_screen.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> billData;

  DetailScreen({super.key, required Map<String, dynamic> billData})
    : billData = Map<String, dynamic>.from(billData);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with WidgetsBindingObserver {
  late Future<List<MemberSummaryEntry>> _membersFuture;
  final LocalBillRepository _localRepository = LocalBillRepository();
  final GlobalKey _receiptCaptureKey = GlobalKey();
  late final OfflineService _offlineService;
  RealtimeChannel? _billRealtimeChannel;
  bool _isLoadingBill = false;
  String _hostPromptPay = '';
  String? _hostPromptPayType;
  String? _hostBankName;
  String _hostBankAccountNumber = '';
  String? _hostBankAccountName;
  String _hostName = 'เจ้าของบิล';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _offlineService = context.read<OfflineService>()
      ..addListener(_handleOfflineStatusChanged);
    _membersFuture = _loadMemberSummary();
    final billId = widget.billData['id']?.toString();
    if (billId != null && billId.isNotEmpty) {
      _isLoadingBill = false;
      if (!_offlineService.isOffline) _setupRealtimeBillSubscription();
      unawaited(_loadBillLocalFirst());
    } else {
      unawaited(_fetchHostPromptPayInfo());
    }
  }

  Future<void> _loadBillLocalFirst() async {
    final billId = widget.billData['id']?.toString();
    if (billId == null || billId.isEmpty) return;
    try {
      final cachedBill = await _localRepository.getCachedBillData(billId);
      if (cachedBill != null && mounted) {
        setState(() {
          widget.billData.addAll(cachedBill);
          _isLoadingBill = false;
          _membersFuture = _loadMemberSummary();
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to read cached bill detail: $error\n$stackTrace');
      if (mounted) setState(() => _isLoadingBill = false);
    }

    if (!mounted) return;
    unawaited(_fetchHostPromptPayInfo());
    if (!mounted || context.read<OfflineService>().isOffline) return;
    unawaited(_loadBillFromSupabase());
  }

  Future<void> _loadBillFromSupabase() async {
    final billId = widget.billData['id']?.toString();
    if (billId == null || billId.isEmpty) return;

    try {
      final bill = await Supabase.instance.client
          .from('bills')
          .select('*, bill_participants(*), bill_payments(*)')
          .eq('id', billId)
          .maybeSingle()
          .timeout(const Duration(seconds: 15));
      if (bill == null) return;

      final billData = Map<String, dynamic>.from(bill);
      final existingLocalImage = widget.billData['local_image_path']
          ?.toString();
      if (existingLocalImage != null && existingLocalImage.isNotEmpty) {
        billData['local_image_path'] = existingLocalImage;
      }
      final receiptImageUrl =
          (billData['image_url'] ?? billData['receipt_image_url'])?.toString();
      if ((billData['local_image_path'] == null ||
              billData['local_image_path'].toString().isEmpty) &&
          receiptImageUrl != null &&
          receiptImageUrl.isNotEmpty) {
        try {
          final resolvedUrl = await SupabaseStorageService()
              .resolveReceiptImageUrl(receiptImageUrl);
          billData['local_image_path'] = await cacheRemoteImage(
            resolvedUrl,
            'receipt-$billId',
          );
        } catch (error, stackTrace) {
          debugPrint('Failed to cache receipt image: $error\n$stackTrace');
        }
      }
      final paymentRows = _asList(billData['bill_payments']);
      final cachedPaymentsById = <String, Map<String, dynamic>>{
        for (final rawPayment in _asList(widget.billData['bill_payments']))
          if (_asMap(rawPayment)['profile_id'] != null)
            _asMap(rawPayment)['profile_id'].toString():
                Map<String, dynamic>.from(_asMap(rawPayment)),
      };
      for (final rawPayment in paymentRows) {
        if (rawPayment is! Map) continue;
        final payment = Map<String, dynamic>.from(rawPayment);
        final memberId = payment['profile_id']?.toString() ?? 'member';
        final cachedPath = cachedPaymentsById[memberId]?['local_image_path']
            ?.toString();
        if (cachedPath != null && cachedPath.isNotEmpty) {
          payment['local_image_path'] = cachedPath;
          final index = paymentRows.indexOf(rawPayment);
          if (index >= 0) paymentRows[index] = payment;
          continue;
        }
        final slipSource = payment['slip_data']?.toString();
        if (slipSource == null || slipSource.isEmpty) continue;
        try {
          final resolvedSource = slipSource.startsWith('data:image/')
              ? slipSource
              : await SupabaseStorageService().resolveReceiptImageUrl(
                  slipSource,
                );
          payment['local_image_path'] = await cacheRemoteImage(
            resolvedSource,
            'slip-$billId-$memberId',
          );
          final index = paymentRows.indexOf(rawPayment);
          if (index >= 0) paymentRows[index] = payment;
        } catch (error, stackTrace) {
          debugPrint('Failed to cache payment slip: $error\n$stackTrace');
        }
      }
      billData['bill_payments'] = paymentRows;
      final profileIds = <String>{
        if (billData['owner_id'] != null) billData['owner_id'].toString(),
        for (final participant in _asList(billData['bill_participants']))
          if (_asMap(participant)['profile_id'] != null)
            _asMap(participant)['profile_id'].toString(),
      };
      final profilesById = <String, Map<String, dynamic>>{};
      if (profileIds.isNotEmpty) {
        try {
          final profiles = await Supabase.instance.client
              .from('profiles')
              .select()
              .inFilter('id', profileIds.toList())
              .timeout(const Duration(seconds: 10));
          for (final profile in profiles) {
            final profileMap = Map<String, dynamic>.from(profile);
            final cachedProfile = await _localRepository.getCachedProfile(
              profileMap['id'].toString(),
            );
            final cachedAvatarPath = cachedProfile?['local_avatar_path']
                ?.toString();
            if (cachedAvatarPath != null && cachedAvatarPath.isNotEmpty) {
              profileMap['local_avatar_path'] = cachedAvatarPath;
            }
            final avatarUrl = profileMap['avatar_url']?.toString();
            final avatarUri = Uri.tryParse(avatarUrl ?? '');
            if ((cachedAvatarPath == null || cachedAvatarPath.isEmpty) &&
                avatarUri != null &&
                (avatarUri.scheme == 'http' || avatarUri.scheme == 'https') &&
                avatarUri.host.isNotEmpty) {
              try {
                final avatarBytes = await NetworkAssetBundle(
                  avatarUri,
                ).load(avatarUrl!).timeout(const Duration(seconds: 5));
                profileMap['local_avatar_path'] = await saveLocalReceipt(
                  avatarBytes.buffer.asUint8List(),
                  'avatar-${profileMap['id']}',
                );
              } catch (error, stackTrace) {
                debugPrint(
                  'Failed to cache member avatar: $error\n$stackTrace',
                );
              }
            }
            profilesById[profileMap['id'].toString()] = profileMap;
            await _localRepository.cacheProfile(profileMap);
          }
        } catch (error, stackTrace) {
          debugPrint(
            'Failed to sync bill member profiles: $error\n$stackTrace',
          );
        }
      }
      billData['profiles'] = profilesById;
      await _localRepository.cacheSupabaseBills([billData]);

      widget.billData.addAll(billData);
      if (!mounted) return;
      setState(() {
        _isLoadingBill = false;
        _membersFuture = _loadMemberSummary();
      });
      await _fetchHostPromptPayInfo();
    } catch (error, stackTrace) {
      debugPrint('Failed to load bill detail: $error\n$stackTrace');
      _offlineService.reportNetworkFailure(error);
      if (!mounted) return;
      setState(() => _isLoadingBill = false);
    }
  }

  void _setupRealtimeBillSubscription() {
    final billId = widget.billData['id']?.toString();
    if (billId == null ||
        billId.isEmpty ||
        _offlineService.isOffline ||
        _billRealtimeChannel != null) {
      return;
    }

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
        callback: (_) => unawaited(_loadBillFromSupabase()),
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
        callback: (_) => unawaited(_loadBillFromSupabase()),
      );
    _billRealtimeChannel = channel;
    channel.subscribe((status, error) {
      if (error != null) {
        debugPrint('Bill detail Realtime subscription error: $error');
        if (OfflineService.isLikelyNetworkError(error)) {
          _offlineService.reportNetworkFailure(error);
          unawaited(_removeBillRealtimeChannel());
        }
      }
      if (status != RealtimeSubscribeStatus.subscribed && error != null) {
        debugPrint('Bill detail Realtime status: $status');
      }
    });
  }

  void _handleOfflineStatusChanged() {
    if (_offlineService.isOffline) {
      unawaited(_removeBillRealtimeChannel());
    } else {
      _setupRealtimeBillSubscription();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_offlineService.isOffline) {
      _setupRealtimeBillSubscription();
    }
  }

  Future<void> _removeBillRealtimeChannel() async {
    final channel = _billRealtimeChannel;
    _billRealtimeChannel = null;
    if (channel != null) {
      try {
        await Supabase.instance.client.removeChannel(channel);
      } catch (error, stackTrace) {
        debugPrint('Failed to remove bill detail channel: $error\n$stackTrace');
      }
    }
  }

  Future<void> _refreshBillFromRealtime() async {
    await _loadBillFromSupabase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offlineService.removeListener(_handleOfflineStatusChanged);
    unawaited(_removeBillRealtimeChannel());
    super.dispose();
  }

  Future<void> _fetchHostPromptPayInfo() async {
    final offline = context.read<OfflineService>();
    try {
      final ownerId =
          widget.billData['owner_id']?.toString() ??
          _asMap(widget.billData['receipt_json'])['owner_id']?.toString();
      if (ownerId == null || ownerId.isEmpty) return;
      final rawProfile = _asMap(widget.billData['profiles'])[ownerId];
      Map<String, dynamic>? profile = rawProfile is Map
          ? Map<String, dynamic>.from(rawProfile)
          : await _localRepository.getCachedProfile(ownerId);
      if (profile == null && !offline.isOffline) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', ownerId)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
        if (response != null) {
          profile = Map<String, dynamic>.from(response);
          await _localRepository.cacheProfile(profile);
        }
      }
      if (profile != null && mounted) _applyHostProfile(profile);
    } catch (error, stackTrace) {
      debugPrint('Error fetching host payment profile: $error\n$stackTrace');
    }
  }

  void _applyHostProfile(Map<String, dynamic> profile) {
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

  Future<List<MemberSummaryEntry>> _loadMemberSummary() async {
    final receipt = _asMap(widget.billData['receipt_json']);
    final sharersByItem = _asMap(widget.billData['sharers_json']);
    final billId = widget.billData['id']?.toString();
    final participantRows = _asList(widget.billData['bill_participants']);
    final paymentRows = _asList(widget.billData['bill_payments']);
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
    final profilesById = <String, Map<String, dynamic>>{
      for (final entry in _asMap(widget.billData['profiles']).entries)
        if (entry.value is Map)
          entry.key: Map<String, dynamic>.from(entry.value as Map),
    };
    for (final profileId in profileIds) {
      if (profilesById.containsKey(profileId)) continue;
      final profile = await _localRepository.getCachedProfile(profileId);
      if (profile != null) profilesById[profileId] = profile;
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
        localSlipPath: payment['local_image_path']?.toString(),
        avatarUrl: profile?['avatar_url']?.toString(),
        localAvatarPath: profile?['local_avatar_path']?.toString(),
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
        localSlipPath: payment['local_image_path']?.toString(),
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

  void _openReceiptFullView(String imageSource) {
    final isLocalPath =
        !imageSource.startsWith('http://') &&
        !imageSource.startsWith('https://');
    final imageUrl = isLocalPath
        ? (widget.billData['image_url'] ?? widget.billData['receipt_image_url'])
              ?.toString()
        : imageSource;
    final localImagePath = isLocalPath
        ? imageSource
        : widget.billData['local_image_path']?.toString();
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
                    child: ReceiptImage(
                      imageUrl: imageUrl,
                      localImagePath: localImagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error) => const Icon(
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
    final localImagePath = widget.billData['local_image_path']?.toString();
    final uri = Uri.tryParse(imageUrl);
    final isValidUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValidUrl && (localImagePath == null || localImagePath.isEmpty)) {
      return _buildMissingReceiptImage();
    }

    return Semantics(
      button: true,
      label: 'แตะเพื่อดูรูปใบเสร็จแบบเต็ม',
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          ReceiptImage(
            imageUrl: imageUrl.isEmpty ? null : imageUrl,
            localImagePath: localImagePath,
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
    final themeColors = context.appColors;
    return Container(
      height: 180,
      width: double.infinity,
      color: themeColors.surfaceVariant,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: themeColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'ไม่พบรูปใบเสร็จของบิลนี้',
            style: TextStyle(color: themeColors.textSecondary),
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
    final offline = context.read<OfflineService>();
    try {
      if (offline.isOffline) {
        await offline.queue.enqueue(
          type: 'set_bill_payment_status',
          payload: {
            'bill_id': billId,
            'profile_id': member.id,
            'status': newStatus,
          },
        );
      } else {
        try {
          await Supabase.instance.client.rpc(
            'set_bill_payment_status',
            params: {
              'p_bill_id': billId,
              'p_profile_id': member.id,
              'p_status': newStatus,
            },
          );
        } catch (error) {
          if (!OfflineService.isLikelyNetworkError(error)) rethrow;
          await offline.queue.enqueue(
            type: 'set_bill_payment_status',
            payload: {
              'bill_id': billId,
              'profile_id': member.id,
              'status': newStatus,
            },
          );
        }
      }
      final paymentUpdates = _asMap(widget.billData['payment_updates']);
      paymentUpdates[member.id] = {
        'status': newStatus,
        'slip_data': newStatus == 'pending' ? null : member.slipUrl,
      };
      widget.billData['payment_updates'] = paymentUpdates;
      await _localRepository.cacheSupabaseBills([widget.billData]);

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
    final themeColors = context.appColors;
    final billSummary = BillProgressHelper.calculate(widget.billData);
    final shopName = widget.billData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final createdAt =
        widget.billData['created_at']?.toString().split('T')[0] ?? '';
    final imageUrl =
        widget.billData['image_url'] ?? widget.billData['receipt_image_url'];
    final receiptJson = _asMap(widget.billData['receipt_json']);
    final items = _asList(receiptJson['items']);
    final sharersJson = _asMap(widget.billData['sharers_json']);

    final receiptSubTotal = double.tryParse(
      receiptJson['sub_total']?.toString() ?? '',
    );
    final itemSubTotal = items.fold<double>(0, (total, rawItem) {
      final item = _asMap(rawItem);
      final itemTotal = double.tryParse(item['total_price']?.toString() ?? '');
      if (itemTotal != null) return total + itemTotal;

      final quantity =
          int.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
      final unitPrice =
          double.tryParse(
            (item['unit_price'] ?? item['price'] ?? '').toString(),
          ) ??
          0;
      return total + unitPrice * quantity;
    });
    final subTotal =
        receiptSubTotal ?? (itemSubTotal > 0 ? itemSubTotal : null);
    final vatAmount =
        double.tryParse(receiptJson['vat_amount']?.toString() ?? '0') ?? 0;
    final serviceCharge =
        double.tryParse(receiptJson['service_charge']?.toString() ?? '0') ?? 0;
    final discount =
        double.tryParse(receiptJson['discount']?.toString() ?? '0') ?? 0;
    final storedTotal = BillProgressHelper.extractBillTotal(widget.billData);
    final totalAmount = storedTotal > 0
        ? storedTotal
        : _isLoadingBill
        ? 0.0
        : BillProgressHelper.extractBillTotal({
            'bill_participants': widget.billData['bill_participants'],
          });

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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (createdAt.isNotEmpty)
                  Text(
                    'วันที่: $createdAt',
                    style: TextStyle(color: themeColors.textSecondary),
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
                          Text(
                            'ยอดสุทธิ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeColors.textPrimary,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _isLoadingBill
                                    ? 'กำลังโหลดยอดบิล...'
                                    : totalAmount > 0
                                    ? AppFormatters.formatCurrency(totalAmount)
                                    : 'ยังไม่มีข้อมูลยอดบิล',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: themeColors.tealText,
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
                                    color: themeColors.textSecondary,
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
                Text(
                  'รายการที่สั่ง (รายละเอียด)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: themeColors.textPrimary,
                  ),
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
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: themeColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '$qty x ${AppFormatters.formatCurrency(unitPrice)}',
                                        style: TextStyle(
                                          color: themeColors.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  AppFormatters.formatCurrency(totalPrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: themeColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (userQuantities.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '👤 ส่วนตัว: ${userQuantities.entries.map((entry) => '${namesByUserId[entry.key] ?? entry.key}: ${entry.value} ชิ้น').join(', ')}',
                                style: TextStyle(
                                  color: themeColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (sharedUsers.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '🤝 แชร์ร่วมกัน ($sharedQuantity ชิ้น): ${sharedUsers.values.join(', ')}',
                                style: TextStyle(
                                  color: themeColors.textSecondary,
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
                Center(
                  child: Text(
                    'สรุปยอดชำระและสถานะของเพื่อน',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: themeColors.textPrimary,
                    ),
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

  Widget _buildSummaryRow(String label, double? amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.appColors.textSecondary)),
          Text(
            amount == null
                ? 'ไม่มีข้อมูล'
                : AppFormatters.formatCurrency(amount),
            style: TextStyle(color: color ?? context.appColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
