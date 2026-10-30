import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/bill_model.dart';
import '../../../providers/bill_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/bill/claim_item_card.dart';

class ClaimScreen extends StatefulWidget {
  final String lobbyId;
  final Map<String, dynamic> receiptData;
  final Uint8List? receiptImageBytes;
  final bool isHost;
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

  void _hostTriggerSummary() {
    _claimChannel.sendBroadcastMessage(event: 'go_to_summary', payload: {});
    _navigateToSummaryLocal();
  }

  Future<void> _showAddGuestDialog(BuildContext context) async {
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'เพิ่มเพื่อนที่ไม่มีแอป',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สำหรับเพื่อนที่ไม่ได้พกมือถือมา เพื่อให้เจ้ามือเลือกอาหารและคิดยอดให้',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'ชื่อเพื่อน',
                hintText: 'เช่น ต้น, นนท์',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) Navigator.pop(dialogCtx, val);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('เพิ่มเพื่อน'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && mounted) {
      RoomMember newMember;
      try {
        newMember = await billProvider.addGuestMember(name);
      } catch (_) {
        newMember = RoomMember(
          id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          isGuest: true,
        );
        billProvider.mergeRoomMembers([newMember]);
      }
      setState(() {
        _userNames[newMember.id] = newMember.name;
      });
      billProvider.setClaimingUser(newMember.id);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'เพิ่มเพื่อน "${newMember.name}" แล้ว สามารถเลือกอาหารแทนเพื่อนได้ทันที ✅',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
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

    final allParticipants = <Map<String, dynamic>>[...widget.roomParticipants];
    final existingIds = allParticipants
        .map((p) => p['id']?.toString() ?? p['user_id']?.toString() ?? '')
        .toSet();

    final billProvider = context.read<BillProvider>();
    for (final member in billProvider.roomMembers) {
      if (!existingIds.contains(member.id)) {
        allParticipants.add(member.toMap());
        existingIds.add(member.id);
      }
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.summary,
      arguments: {
        'lobbyId': widget.lobbyId,
        'receiptData': widget.receiptData,
        'receiptImageBytes': widget.receiptImageBytes,
        'itemSharers': itemSharers,
        'roomParticipants': allParticipants,
        'isHost': widget.isHost,
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
    for (final member in billProvider.roomMembers) {
      if (member.id.isNotEmpty) {
        memberNames[member.id] = member.name;
      }
    }
    final claimingUsers = <String, String>{_currentUserId: _currentUserName};
    for (final entry in memberNames.entries) {
      claimingUsers[entry.key] = entry.value;
    }
    final shopName = widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];

    // คำนวณยอดเงินของคนที่กำลังเลือกอยู่
    double currentClaimingTotal = 0.0;
    int selectedDishCount = 0;
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final price =
          double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
      final myQty = _claimedItems[i]?[claimingUserId] ?? 0;
      if (myQty > 0) {
        currentClaimingTotal += (myQty * price);
        selectedDishCount++;
      }
      if (_sharedItems[i]?.contains(claimingUserId) == true) {
        final totalPersonal = (_claimedItems[i]?.values ?? []).fold<int>(
          0,
          (a, b) => a + b,
        );
        final maxQty =
            int.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ??
            1;
        final remaining = (maxQty - totalPersonal).clamp(0, maxQty);
        final sharersCount = _sharedItems[i]?.length ?? 1;
        if (sharersCount > 0) {
          currentClaimingTotal += (remaining * price) / sharersCount;
          selectedDishCount++;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('จิ้มเลือกอาหารที่คุณกินจริง'),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // แถบด้านบน: Step + Shop Name + Real-time ticker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ขั้นตอน 4/6',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.restaurant_menu_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shopName,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ticker ซิงค์สด
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ซิงค์สด Real-time',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'ห้อง #${widget.lobbyId}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // การ์ดยอดของคุณตอนนี้ (Sticky Personal Total Card)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.secondary.withValues(alpha: 0.7),
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ยอดของ ${_userNames[claimingUserId] ?? "คุณ"} ตอนนี้',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'รายการที่เลือก ($selectedDishCount รายการ)',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(currentClaimingTotal),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      'ยังไม่รวม Vat/Svc',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // กรณี Host มีดรอปดาวน์สลับเลือกจานให้เพื่อน
          if (widget.isHost)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.switch_account_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      underline: const SizedBox(),
                      value: claimingUsers.containsKey(claimingUserId)
                          ? claimingUserId
                          : _currentUserId,
                      items: claimingUsers.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(
                                'เลือกจานให้: ${entry.value}'
                                '${entry.key == _currentUserId ? ' (คุณ)' : ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
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
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _showAddGuestDialog(context),
                    icon: const Icon(
                      Icons.person_add_alt,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      '+ เพื่อน',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // รายการอาหารให้จิ้มเลือก
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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

                final itemClaims = _claimedItems[index] ?? <String, int>{};
                final sharedUsers = _sharedItems[index] ?? <String>{};

                return ClaimItemCard(
                  itemName: itemName.toString(),
                  itemQuantity: maxQty,
                  unitPrice: unitPrice,
                  claimingUserId: claimingUserId,
                  itemClaims: itemClaims,
                  sharedUsers: sharedUsers,
                  userNames: _userNames,
                  onChangeQuantity: (change) =>
                      _changePersonalQuantity(index, maxQty, change),
                  onToggleShared: () => _toggleShared(index),
                );
              },
            ),
          ),

          // Sticky Bottom Summary Bar
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ยอดของคุณตอนนี้',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(currentClaimingTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: widget.isHost ? _hostTriggerSummary : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isHost
                              ? 'สรุปยอดและเคลียร์บิล'
                              : 'รอเจ้ามือสรุปยอด...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.isHost) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
