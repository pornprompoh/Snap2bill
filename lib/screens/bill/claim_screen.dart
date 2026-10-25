import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/bill_model.dart';
import '../../../providers/bill_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/bill/claim_item_card.dart';
import '../../../widgets/custom_button.dart';

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

  Future<void> _showAddGuestDialog(BuildContext context) async {
    final billProvider = context.read<BillProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1, color: AppColors.primary),
            SizedBox(width: 8),
            Text('เพิ่มเพื่อนที่ไม่มีแอป', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'สำหรับเพื่อนที่ไม่ได้พกมือถือมา หรือไม่มีแอป Snap2Bill เพื่อให้หัวหน้าห้องเลือกอาหารและหารยอดให้',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ชื่อเพื่อน',
                hintText: 'เช่น ต้น, น้องบิว',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) Navigator.pop(dialogCtx, val);
            },
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
            content: Text('เพิ่มเพื่อน "${newMember.name}" แล้ว สามารถเลือกอาหารแทนเพื่อนได้ทันที ✅'),
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
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: Colors.blue.shade50.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
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
                                'เลือกอาหารให้: ${entry.value}'
                                '${entry.key.startsWith('guest_') ? ' (Guest)' : ''}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showAddGuestDialog(context),
                    icon: const Icon(Icons.person_add, size: 15),
                    label: const Text('+ เพื่อนไม่มีแอป', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
