import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class ClaimScreen extends StatefulWidget {
  final String lobbyId;
  final Map<String, dynamic> receiptData;
  final bool isHost; // 🚀 เพิ่มตัวแปรนี้
  final List<Map<String, dynamic>> roomParticipants;

  const ClaimScreen({
    super.key,
    required this.lobbyId,
    required this.receiptData,
    this.isHost = true,
    this.roomParticipants = const [],
  });

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final Map<int, Map<String, int>> _claimedItems = {};
  final Map<String, String> _userNames = {};

  final _supabase = Supabase.instance.client;
  late String _currentUserId;
  late String _currentUserName;
  late RealtimeChannel _claimChannel;

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
      final displayName = participant['display_name']?.toString();
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
        final index = payload['item_index'] as int;
        final userId = payload['user_id'] as String;
        final userName = payload['user_name'] as String;
        final qty = payload['qty'] as int;

        if (userId == _currentUserId) return;

        setState(() {
          _userNames[userId] = userName;
          final itemClaims = _claimedItems[index] ?? {};
          if (qty > 0) {
            itemClaims[userId] = qty;
          } else {
            itemClaims.remove(userId);
          }
          _claimedItems[index] = itemClaims;
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
          claimsData.forEach(
            (k, v) =>
                _claimedItems[int.parse(k)] = Map<String, int>.from(v as Map),
          );
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

  void _broadcastUpdate(int index, int qty) {
    _claimChannel.sendBroadcastMessage(
      event: 'update_claim',
      payload: {
        'item_index': index,
        'user_id': _currentUserId,
        'user_name': _currentUserName,
        'qty': qty,
      },
    );
  }

  void _increment(int index, int maxQty) {
    final itemClaims = _claimedItems[index] ?? {};
    int totalClaimed = itemClaims.values.fold(0, (sum, qty) => sum + qty);
    if (totalClaimed < maxQty) {
      setState(() {
        final newQty = (itemClaims[_currentUserId] ?? 0) + 1;
        itemClaims[_currentUserId] = newQty;
        _claimedItems[index] = itemClaims;
        _broadcastUpdate(index, newQty);
      });
    }
  }

  void _decrement(int index) {
    final itemClaims = _claimedItems[index] ?? {};
    final myClaimedQty = itemClaims[_currentUserId] ?? 0;
    if (myClaimedQty > 0) {
      setState(() {
        final newQty = myClaimedQty - 1;
        if (newQty == 0) {
          itemClaims.remove(_currentUserId);
        } else {
          itemClaims[_currentUserId] = newQty;
        }
        _claimedItems[index] = itemClaims;
        _broadcastUpdate(index, newQty);
      });
    }
  }

  // 🚀 ฟังก์ชันถูกกดโดย Host เพื่อสั่งให้ทุกคนไปต่อ
  void _hostTriggerSummary() {
    _claimChannel.sendBroadcastMessage(event: 'go_to_summary', payload: {});
    _navigateToSummaryLocal();
  }

  void _navigateToSummaryLocal() {
    Map<int, List<Map<String, dynamic>>> itemSharers = {};
    _claimedItems.forEach((index, userClaims) {
      List<Map<String, dynamic>> sharersList = [];
      userClaims.forEach((userId, qty) {
        for (int i = 0; i < qty; i++) {
          sharersList.add({
            'user_id': userId,
            'user_name': _userNames[userId] ?? 'เพื่อน',
          });
        }
      });
      itemSharers[index] = sharersList;
    });

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.summary,
      arguments: {
        'lobbyId': widget.lobbyId,
        'receiptData': widget.receiptData,
        'itemSharers': itemSharers,
        'isHost': widget.isHost, // ส่งสถานะต่อ
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
                final unitPrice =
                    double.tryParse(item['unit_price']?.toString() ?? '0') ??
                    0.0;

                final itemClaims = _claimedItems[index] ?? {};
                final myClaimedQty = itemClaims[_currentUserId] ?? 0;
                final totalClaimed = itemClaims.values.fold(
                  0,
                  (sum, qty) => sum + qty,
                );
                final isFullyClaimed = totalClaimed >= maxQty;
                final isSelected = myClaimedQty > 0;

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
                          : isFullyClaimed
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
                              width: 104,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _QuantityButton(
                                    icon: Icons.remove,
                                    semanticLabel: 'ลดจำนวน $itemName',
                                    color: myClaimedQty > 0
                                        ? AppColors.error
                                        : AppColors.textMuted,
                                    onPressed: myClaimedQty > 0
                                        ? () => _decrement(index)
                                        : null,
                                  ),
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '$myClaimedQty',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.body.copyWith(
                                        color: isSelected
                                            ? AppColors.primaryDark
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _QuantityButton(
                                    icon: Icons.add,
                                    semanticLabel: 'เพิ่มจำนวน $itemName',
                                    color: isFullyClaimed
                                        ? AppColors.textMuted
                                        : AppColors.primary,
                                    onPressed: isFullyClaimed
                                        ? null
                                        : () => _increment(index, maxQty),
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
                        if (itemClaims.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: itemClaims.entries.map((entry) {
                              final userId = entry.key;
                              final qty = entry.value;
                              final name = _userNames[userId] ?? 'เพื่อน';
                              final isMe = userId == _currentUserId;
                              final claimColor = isMe
                                  ? AppColors.primary
                                  : AppColors.accent;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: claimColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$name × $qty',
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.2,
                                    color: isMe
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (isFullyClaimed && !isSelected) ...[
                          const SizedBox(height: 9),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'รายการนี้ถูกเลือกครบแล้ว',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final Color color;
  final VoidCallback? onPressed;

  const _QuantityButton({
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: semanticLabel,
      onPressed: onPressed,
      icon: Icon(icon),
      color: color,
      iconSize: 19,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 32, height: 36),
    );
  }
}
