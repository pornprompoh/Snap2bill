import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/bill_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class ClaimScreen extends StatefulWidget {
  final String lobbyId;
  final Map<String, dynamic> receiptData;
  final Uint8List? receiptImageBytes;
  final bool isHost; // 🚀 เพิ่มตัวแปรนี้
  final List<Map<String, dynamic>> roomParticipants;

  const ClaimScreen({
    super.key,
    required this.lobbyId,
    required this.receiptData,
    this.receiptImageBytes,
    this.isHost = true,
    this.roomParticipants = const [],
  });

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final Map<int, Map<String, int>> _claimedItems = {};
  final Map<int, Set<String>> _sharedItems = {};
  final Map<String, String> _userNames = {};

  final _supabase = Supabase.instance.client;
  late String _currentUserId;
  late String _currentUserName;
  late RealtimeChannel _claimChannel;

  String get _activeClaimingUserId => widget.isHost
      ? context.read<BillProvider>().currentClaimingUserId
      : _currentUserId;

  String get _activeClaimingUserName =>
      _userNames[_activeClaimingUserId] ?? _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUserId =
        _supabase.auth.currentUser?.id ??
        'guest_${DateTime.now().millisecondsSinceEpoch}';
    final email = _supabase.auth.currentUser?.email;
    if (email != null) {
      _currentUserName = email.split('@')[0];
    } else {
      _currentUserName =
          'Guest (${_currentUserId.substring(_currentUserId.length - 4)})';
    }
    _userNames[_currentUserId] = _currentUserName;
    for (final participant in widget.roomParticipants) {
      final userId =
          participant['id']?.toString() ?? participant['user_id']?.toString();
      if (userId == null || userId.isEmpty) {
        continue;
      }
      final displayName =
          participant['name']?.toString() ??
          participant['user_name']?.toString() ??
          participant['display_name']?.toString();
      final emailName = participant['email']?.toString().split('@').first;
      if (displayName?.isNotEmpty == true) {
        _userNames[userId] = displayName!;
      } else if (emailName?.isNotEmpty == true) {
        _userNames[userId] = emailName!;
      } else {
        _userNames[userId] = 'เพื่อน';
      }
    }
    _setupRealtime();
  }

  void _setupRealtime() {
    _claimChannel = _supabase.channel('room_${widget.lobbyId}');

    _claimChannel.onBroadcast(
      event: 'update_claim',
      callback: (payload) {
        final index = int.tryParse(payload['item_index']?.toString() ?? '');
        final userId = payload['user_id']?.toString();
        final userName = payload['user_name']?.toString() ?? 'เพื่อน';
        if (index == null || userId == null || userId.isEmpty) return;

        if (!mounted) return;
        setState(() {
          _userNames[userId] = userName;
          if (payload['claim_type'] == 'shared') {
            final sharedUsers = _sharedItems[index] ?? <String>{};
            if (payload['is_shared'] == true) {
              sharedUsers.add(userId);
            } else {
              sharedUsers.remove(userId);
            }
            _sharedItems[index] = sharedUsers;
          } else {
            final qty = int.tryParse(payload['qty']?.toString() ?? '0') ?? 0;
            final itemClaims = _claimedItems[index] ?? {};
            if (qty > 0) {
              itemClaims[userId] = qty;
            } else {
              itemClaims.remove(userId);
            }
            _claimedItems[index] = itemClaims;
          }
        });
      },
    );

    _claimChannel.onBroadcast(
      event: 'request_sync',
      callback: (_) {
        _claimChannel.sendBroadcastMessage(
          event: 'full_sync',
          payload: {
            'claims': _claimedItems.map((k, v) => MapEntry(k.toString(), v)),
            'shared_users': _sharedItems.map(
              (k, v) => MapEntry(k.toString(), v.toList()),
            ),
            'names': _userNames,
          },
        );
      },
    );

    _claimChannel.onBroadcast(
      event: 'full_sync',
      callback: (payload) {
        setState(() {
          final claimsData = payload['claims'] as Map<String, dynamic>? ?? {};
          _claimedItems.clear();
          claimsData.forEach((key, value) {
            if (value is! Map) return;
            final claims = <String, int>{};
            value.forEach((userId, qty) {
              final parsedQty = int.tryParse(qty.toString()) ?? 0;
              if (parsedQty > 0) claims[userId.toString()] = parsedQty;
            });
            final index = int.tryParse(key);
            if (index != null) _claimedItems[index] = claims;
          });
          _sharedItems.clear();
          final sharedData =
              payload['shared_users'] as Map<String, dynamic>? ?? {};
          sharedData.forEach((key, value) {
            final index = int.tryParse(key);
            if (index != null && value is List) {
              _sharedItems[index] = value.map((id) => id.toString()).toSet();
            }
          });
          final namesData = payload['names'] as Map<String, dynamic>? ?? {};
          namesData.forEach((k, v) => _userNames[k] = v.toString());
        });
      },
    );

    // 🚀 ดักฟังคำสั่งจาก Host เพื่อไปหน้าสรุปยอดพร้อมกัน
    _claimChannel.onBroadcast(
      event: 'go_to_summary',
      callback: (_) {
        if (!widget.isHost && mounted) {
          _navigateToSummaryLocal();
        }
      },
    );

    _claimChannel.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        _claimChannel.sendBroadcastMessage(event: 'request_sync', payload: {});
      }
    });
  }

  @override
  void dispose() {
    _supabase.removeChannel(_claimChannel);
    super.dispose();
  }

  void _broadcastPersonalUpdate(int index, int qty) {
    _claimChannel.sendBroadcastMessage(
      event: 'update_claim',
      payload: {
        'item_index': index,
        'user_id': _activeClaimingUserId,
        'user_name': _activeClaimingUserName,
        'claim_type': 'personal',
        'qty': qty,
      },
    );
  }

  void _broadcastSharedUpdate(int index, bool isShared) {
    _claimChannel.sendBroadcastMessage(
      event: 'update_claim',
      payload: {
        'item_index': index,
        'user_id': _activeClaimingUserId,
        'user_name': _activeClaimingUserName,
        'claim_type': 'shared',
        'is_shared': isShared,
      },
    );
  }

  void _changePersonalQuantity(int index, int itemQuantity, int change) {
    final itemClaims = _claimedItems[index] ?? {};
    final userId = _activeClaimingUserId;
    final currentQty = itemClaims[userId] ?? 0;
    final otherClaims = itemClaims.entries
        .where((entry) => entry.key != userId)
        .fold<int>(0, (total, entry) => total + entry.value);
    final maxPersonalQty = (itemQuantity - otherClaims).clamp(0, itemQuantity);
    final nextQty = (currentQty + change).clamp(0, maxPersonalQty);
    if (nextQty == currentQty) return;

    setState(() {
      if (nextQty == 0) {
        itemClaims.remove(userId);
      } else {
        itemClaims[userId] = nextQty;
      }
      _claimedItems[index] = itemClaims;
      _broadcastPersonalUpdate(index, nextQty);
    });
  }

  void _toggleShared(int index) {
    final sharedUsers = _sharedItems[index] ?? <String>{};
    final userId = _activeClaimingUserId;
    final isShared = !sharedUsers.contains(userId);
    setState(() {
      if (isShared) {
        sharedUsers.add(userId);
      } else {
        sharedUsers.remove(userId);
      }
      _sharedItems[index] = sharedUsers;
      _broadcastSharedUpdate(index, isShared);
    });
  }

  // 🚀 ฟังก์ชันถูกกดโดย Host เพื่อสั่งให้ทุกคนไปต่อ
  void _hostTriggerSummary() {
    _claimChannel.sendBroadcastMessage(event: 'go_to_summary', payload: {});
    _navigateToSummaryLocal();
  }

  void _navigateToSummaryLocal() {
    Map<int, List<Map<String, dynamic>>> itemSharers = {};
    final itemIndexes = {..._claimedItems.keys, ..._sharedItems.keys};
    for (final index in itemIndexes) {
      final userClaims = _claimedItems[index] ?? {};
      final sharedUsers = _sharedItems[index] ?? {};
      List<Map<String, dynamic>> sharersList = [];
      final userIds = {...userClaims.keys, ...sharedUsers};
      for (final userId in userIds) {
        sharersList.add({
          'user_id': userId,
          'user_name': _userNames[userId] ?? 'เพื่อน',
          'quantity': userClaims[userId] ?? 0,
          'is_shared': sharedUsers.contains(userId),
        });
      }
      itemSharers[index] = sharersList;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.summary,
      arguments: {
        'lobbyId': widget.lobbyId,
        'receiptData': widget.receiptData,
        'receiptImageBytes': widget.receiptImageBytes,
        'itemSharers': itemSharers,
        'roomParticipants': widget.roomParticipants,
        'isHost': widget.isHost, // ส่งสถานะต่อ
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final claimingUserId = widget.isHost
        ? billProvider.currentClaimingUserId
        : _currentUserId;
    final memberNames = <String, String>{_currentUserId: _currentUserName};
    for (final participant in widget.roomParticipants) {
      final id =
          participant['id']?.toString() ?? participant['user_id']?.toString();
      if (id == null || id.isEmpty) continue;
      memberNames[id] =
          participant['name']?.toString() ??
          participant['user_name']?.toString() ??
          participant['display_name']?.toString() ??
          'เพื่อน';
    }
    final claimingUserName = memberNames[claimingUserId] ?? _currentUserName;
    final claimingUsers = <String, String>{_currentUserId: _currentUserName};
    for (final entry in memberNames.entries) {
      claimingUsers[entry.key] = entry.value;
    }
    final shopName = widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกเมนูอาหาร (Claim)'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: AppColors.secondary.withValues(alpha: 0.5),
            child: Text(
              'รหัสห้อง: ${widget.lobbyId} | ร้าน: $shopName',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (widget.isHost)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'กำลังเลือกอาหารให้: $claimingUserName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DropdownButton<String>(
                    value: claimingUsers.containsKey(claimingUserId)
                        ? claimingUserId
                        : _currentUserId,
                    items: claimingUsers.entries
                        .map(
                          (entry) => DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              '${entry.value}'
                              '${entry.key.startsWith('guest_') ? ' (Guest)' : ''}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (userId) {
                      if (userId != null) {
                        billProvider.setClaimingUser(userId);
                      }
                    },
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text('เมนูอาหาร', style: AppTextStyles.caption),
                ),
                SizedBox(
                  width: 104,
                  child: Text(
                    'จำนวน',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ),
                SizedBox(
                  width: 78,
                  child: Text(
                    'ราคา/ชิ้น',
                    textAlign: TextAlign.end,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemName = item['item_name'] ?? 'ไม่ระบุชื่อ';
                final maxQty =
                    int.tryParse(
                      (item['qty'] ?? item['quantity'] ?? 1).toString(),
                    ) ??
                    1;
                final unitPrice =
                    double.tryParse(item['unit_price']?.toString() ?? '0') ??
                    0.0;

                final itemClaims = _claimedItems[index] ?? {};
                final sharedUsers = _sharedItems[index] ?? <String>{};
                final myClaimedQty = itemClaims[claimingUserId] ?? 0;
                final totalPersonalQty = itemClaims.values.fold<int>(
                  0,
                  (total, qty) => total + qty,
                );
                final remainingQty = (maxQty - totalPersonalQty).clamp(
                  0,
                  maxQty,
                );
                final otherPersonalQty = totalPersonalQty - myClaimedQty;
                final maxMyQty = (maxQty - otherPersonalQty).clamp(0, maxQty);
                final sharedPerUser = sharedUsers.isEmpty
                    ? 0.0
                    : (unitPrice * remainingQty) / sharedUsers.length;
                final isShared = sharedUsers.contains(claimingUserId);
                final isSelected = myClaimedQty > 0 || isShared;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.07)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : itemClaims.isNotEmpty || sharedUsers.isNotEmpty
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : const [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.body.copyWith(
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ทั้งหมด $maxQty ชิ้น',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 120,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        tooltip: 'ลดจำนวน $itemName',
                                        onPressed: myClaimedQty > 0
                                            ? () => _changePersonalQuantity(
                                                index,
                                                maxQty,
                                                -1,
                                              )
                                            : null,
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 32,
                                              height: 36,
                                            ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      SizedBox(
                                        width: 26,
                                        child: Text(
                                          '$myClaimedQty',
                                          textAlign: TextAlign.center,
                                          style: AppTextStyles.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'เพิ่มจำนวน $itemName',
                                        onPressed: myClaimedQty < maxMyQty
                                            ? () => _changePersonalQuantity(
                                                index,
                                                maxQty,
                                                1,
                                              )
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                        visualDensity: VisualDensity.compact,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 32,
                                              height: 36,
                                            ),
                                        padding: EdgeInsets.zero,
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => _toggleShared(index),
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      foregroundColor: isShared
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                    child: Text(
                                      isShared ? 'แชร์แล้ว' : 'กินด้วยกัน',
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                AppFormatters.formatCurrency(unitPrice),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (remainingQty > 0 ||
                            itemClaims.isNotEmpty ||
                            sharedUsers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            sharedUsers.isEmpty
                                ? 'เหลืออีก $remainingQty ชิ้น'
                                : remainingQty > 0
                                ? 'แชร์ $remainingQty ชิ้น หาร ${sharedUsers.length} คน: '
                                      'คนละ ฿${sharedPerUser.toStringAsFixed(2)}'
                                : 'ไม่มีชิ้นเหลือสำหรับหารร่วมกัน',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              ...itemClaims.keys.map((userId) {
                                final name = _userNames[userId] ?? 'เพื่อน';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$name × ${itemClaims[userId]}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              }),
                              ...sharedUsers.map((userId) {
                                final name = _userNames[userId] ?? 'เพื่อน';
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$name แชร์',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            // 🚀 โชว์ปุ่มตามสถานะ ถ้าเป็น Host กดได้ ถ้าเป็น Guest จะเป็นปุ่มเทาๆ แจ้งให้อยู่เฉยๆ
            child: widget.isHost
                ? CustomButton(
                    text: 'สรุปยอดและเคลียร์บิล',
                    onPressed: _hostTriggerSummary,
                  )
                : CustomButton(
                    text: 'รอหัวหน้าห้องสรุปยอด...',
                    onPressed: null,
                    backgroundColor: Colors.grey,
                  ),
          ),
        ],
      ),
    );
  }
}
