import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/bill_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/bill_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/bill/guest_dialog.dart';

class LobbyScreen extends StatefulWidget {
  final String? lobbyId;
  final Map<String, dynamic>? receiptData;
  final Uint8List? receiptImageBytes;
  final bool isHost;

  const LobbyScreen({
    super.key,
    this.lobbyId,
    this.receiptData,
    this.receiptImageBytes,
    this.isHost = true,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _supabase = Supabase.instance.client;
  late String _roomId;
  late bool _isHost;
  late RealtimeChannel _lobbyChannel;

  List<Map<String, dynamic>> _participants = [];
  late String _currentUserId;
  late String _currentUserName;

  @override
  void initState() {
    super.initState();

    _isHost = widget.isHost;
    _roomId = widget.lobbyId ?? (100000 + Random().nextInt(900000)).toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeRoomMembers();
    });

    _currentUserId =
        _supabase.auth.currentUser?.id ??
        'guest_${DateTime.now().millisecondsSinceEpoch}';
    final email = _supabase.auth.currentUser?.email;
    _currentUserName = email != null
        ? email.split('@')[0]
        : 'Guest (${_currentUserId.substring(_currentUserId.length - 4)})';

    _setupRealtimeLobby();
  }

  Future<void> _initializeRoomMembers() async {
    final provider = context.read<BillProvider>();
    provider.setActiveRoom(_roomId);
    if (_isHost) await _createLobbyInDB();
    try {
      await provider.loadRoomMembers(_roomId);
    } catch (error) {
      debugPrint('โหลดสมาชิกจำลองไม่สำเร็จ: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('โหลดรายชื่อเพื่อนไม่สำเร็จ: $error')),
        );
      }
    }
  }

  Future<void> _createLobbyInDB() async {
    try {
      final existing = await _supabase
          .from('lobbies')
          .select('id')
          .eq('room_code', _roomId)
          .maybeSingle();
      if (existing == null && mounted) {
        final rawTotalAmount =
            double.tryParse(
              widget.receiptData?['total_amount']?.toString() ?? '0',
            ) ??
            0.0;
        await _supabase.from('lobbies').insert({
          'host_id': _supabase.auth.currentUser?.id,
          'room_code': _roomId,
          'shop_name': widget.receiptData?['shop_name'] ?? 'ไม่ระบุชื่อร้าน',
          'total_amount': rawTotalAmount,
          'status': 'waiting',
          'receipt_json': widget.receiptData,
        });
      }
    } catch (e) {
      debugPrint('ตั้งห้องใน DB ไม่สำเร็จ: $e');
    }
  }

  void _setupRealtimeLobby() {
    _lobbyChannel = _supabase.channel(
      'room_$_roomId',
      opts: const RealtimeChannelConfig(key: 'presence'),
    );

    _lobbyChannel.onPresenceSync((_) {
      final newState = _lobbyChannel.presenceState();
      final List<Map<String, dynamic>> users = [];
      for (final state in newState) {
        for (final presence in state.presences) {
          final payload = presence.payload;
          users.add({
            'user_id': payload['user_id'],
            'user_name': payload['user_name'],
            'is_host': payload['is_host'] == true,
          });
        }
      }
      if (mounted) {
        setState(() => _participants = users);
        unawaited(
          context.read<BillProvider>().saveRoomMemberContacts(
            users.map(RoomMember.fromMap),
          ),
        );
      }
    });

    _lobbyChannel.onBroadcast(
      event: 'start_claim',
      callback: (payload) {
        if (!mounted) return;
        final receiptData = payload['receiptData'] as Map<String, dynamic>?;
        final rawParticipants = payload['roomParticipants'];
        final roomParticipants = <Map<String, dynamic>>[];
        if (rawParticipants is Iterable) {
          for (final participant in rawParticipants) {
            if (participant is Map) {
              roomParticipants.add(Map<String, dynamic>.from(participant));
            }
          }
        }
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.claim,
          arguments: {
            'lobbyId': _roomId,
            'receiptData': receiptData ?? widget.receiptData,
            'receiptImageBytes': widget.receiptImageBytes,
            'roomParticipants': roomParticipants,
            'isHost': _isHost,
          },
        );
      },
    );

    _lobbyChannel.onBroadcast(
      event: 'add_guest_member',
      callback: (payload) {
        final memberData = payload['member'] as Map<String, dynamic>?;
        if (memberData == null) return;
        final member = RoomMember.fromMap(memberData);
        context.read<BillProvider>().addGuestMember(member.name);
      },
    );

    _lobbyChannel.onBroadcast(
      event: 'invite_participants',
      callback: (payload) {
        if (!mounted) return;
        _mergeInvitedParticipants(payload);
      },
    );

    _lobbyChannel.subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _lobbyChannel.track({
          'user_id': _currentUserId,
          'user_name': _currentUserName,
          'is_host': _isHost,
        });
      }
    });
  }

  Future<void> _addGuestMember() async {
    final controller = TextEditingController();
    final guestName = await showDialog<String>(
      context: context,
      builder: (context) => GuestDialog(controller: controller),
    );

    if (guestName == null || guestName.trim().isEmpty || !mounted) return;

    try {
      final member = await context.read<BillProvider>().addGuestMember(
        guestName,
      );
      _lobbyChannel.sendBroadcastMessage(
        event: 'add_guest_member',
        payload: {'member': member.toMap()},
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เพิ่มเพื่อนไม่สำเร็จ: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mergeInvitedParticipants(Map<String, dynamic> payload) {
    final rawParticipants = payload['participants'];
    if (rawParticipants is! Iterable) return;

    final selected = <UserModel>[];
    for (final rawParticipant in rawParticipants) {
      if (rawParticipant is Map) {
        selected.add(
          UserModel.fromMap(Map<String, dynamic>.from(rawParticipant)),
        );
      }
    }
    if (selected.isEmpty) return;

    final participants = context.read<BillProvider>().addRoomParticipants(
      _roomId,
      selected,
    );
    if (participants.isEmpty) return;
  }

  @override
  void dispose() {
    _supabase.removeChannel(_lobbyChannel);
    super.dispose();
  }

  void _startClaiming() async {
    if (!_isHost) return;
    final roomParticipants = _buildRoomParticipantMaps(
      context.read<BillProvider>(),
    );
    _lobbyChannel.sendBroadcastMessage(
      event: 'start_claim',
      payload: {
        'receiptData': widget.receiptData,
        'roomParticipants': roomParticipants,
      },
    );

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.claim,
      arguments: {
        'lobbyId': _roomId,
        'receiptData': widget.receiptData,
        'receiptImageBytes': widget.receiptImageBytes,
        'roomParticipants': roomParticipants,
        'isHost': true,
      },
    );
  }

  String get _joinLink => Uri(
    scheme: 'snap2bill',
    host: 'join',
    pathSegments: [_roomId],
  ).toString();

  List<Map<String, dynamic>> _buildRoomParticipantMaps(BillProvider provider) {
    final participantsById = <String, Map<String, dynamic>>{};
    for (final participant in _participants) {
      final userId = participant['user_id']?.toString() ?? '';
      if (userId.isEmpty) continue;
      participantsById[userId] = Map<String, dynamic>.from(participant);
    }
    for (final participant in provider.roomParticipants) {
      final displayName = participant.displayName?.trim();
      participantsById.putIfAbsent(
        participant.id,
        () => {
          'id': participant.id,
          'user_id': participant.id,
          'user_name': displayName?.isNotEmpty == true
              ? displayName
              : participant.email?.split('@').first ?? 'เพื่อน',
          'display_name': displayName,
          'avatar_url': participant.avatarUrl,
          'is_host': false,
          'is_invited': true,
          'is_guest': false,
        },
      );
    }
    for (final member in provider.roomMembers) {
      participantsById.putIfAbsent(
        member.id,
        () => {
          ...member.toMap(),
          'user_id': member.id,
          'user_name': member.name,
          'display_name': member.name,
        },
      );
    }
    return participantsById.values.toList();
  }

  Future<void> _copyJoinLink() async {
    await Clipboard.setData(ClipboardData(text: _joinLink));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('คัดลอกลิงก์เข้าห้องแล้ว')));
  }

  Future<void> _shareToLine() async {
    final shop = widget.receiptData?['shop_name'] ?? 'โต๊ะนี้';
    final message = '🍲 เข้าตี้หารบิลร้าน $shop กัน!\n'
        '📲 แตะลิงก์เพื่อเข้าห้องทันที: $_joinLink\n'
        '🔢 หรือใส่รหัส 6 หลัก: $_roomId\n'
        '✨ ไม่ต้องโหลดแอป เปิดผ่านเบราว์เซอร์แล้วจิ้มอาหารได้เลย!';
    await SharePlus.instance.share(
      ShareParams(
        title: 'แชร์เข้ากลุ่ม LINE',
        text: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final roomParticipants = _buildRoomParticipantMaps(billProvider);
    final shopName = widget.receiptData?['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final totalAmount = double.tryParse(
      (widget.receiptData?['final_total'] ?? widget.receiptData?['total_amount'])?.toString() ?? '0',
    ) ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ชวนเพื่อนเข้าห้องตี้'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
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
                    'ขั้นตอน 3/6  ห้องล็อบบี้ตี้',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('ห้องเปิดอยู่', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mini Restaurant Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'ยอดสุทธิจากใบเสร็จ',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Clean QR Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'สแกนเข้าห้องได้ทันที',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'สแกนเพื่อเข้าตี้เคลมอาหาร',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'หรือให้เพื่อนเปิดกล้องสแกนได้ทันทีโดยไม่ต้องโหลดแอปก็ได้ สะดวก รวดเร็ว',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 16),

                  // QR Frame
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: QrImageView(
                      data: _joinLink,
                      version: QrVersions.auto,
                      size: 190,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.primary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Room Code Pill with copy
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _copyJoinLink,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('รหัสตี้: ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text(
                            '#SB-$_roomId',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Quick Actions Cards
            _buildActionCard(
              icon: Icons.link_rounded,
              iconBg: AppColors.secondary,
              iconColor: AppColors.primary,
              title: 'คัดลอกลิงก์ Copy Link',
              subtitle: 'snap2bill.app/party/$_roomId',
              trailingIcon: Icons.copy_rounded,
              onTap: _copyJoinLink,
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              icon: Icons.share_rounded,
              iconBg: const Color(0xFFE8F8EE),
              iconColor: const Color(0xFF06C755),
              title: 'แชร์เข้า LINE กลุ่ม',
              subtitle: 'ส่งการ์ดเชิญสวยๆ ให้เพื่อนแตะจิ้มอาหาร',
              trailingIcon: Icons.send_rounded,
              onTap: _shareToLine,
            ),
            if (_isHost) ...[
              const SizedBox(height: 8),
              _buildActionCard(
                icon: Icons.person_add_alt_1_rounded,
                iconBg: AppColors.butterPeach,
                iconColor: AppColors.primary,
                title: 'เพิ่มชื่อเพื่อนเองด้วยมือ',
                subtitle: 'เจ้ามือกรอกชื่อและเลือกจานแทนเพื่อนได้',
                trailingIcon: Icons.add_rounded,
                onTap: _addGuestMember,
              ),
            ],
            const SizedBox(height: 20),

            // Real-time Members section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'เพื่อนที่เข้าร่วมแล้ว ${roomParticipants.length} คน',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 7, color: AppColors.success),
                      SizedBox(width: 4),
                      Text('Real-time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Member list
            ...roomParticipants.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final userName = user['user_name']?.toString() ?? 'เพื่อน';
              final isHostUser = user['is_host'] == true || index == 0;
              final isSelf = user['user_id']?.toString() == _currentUserId;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelf ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isHostUser ? AppColors.secondary : const Color(0xFFF0FDF4),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isHostUser ? AppColors.primary : AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              if (isSelf)
                                const Text(' (คุณ)', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                              if (isHostUser) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('เจ้ามือ', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHostUser
                                ? '✓ พร้อมเลือกอาหารแล้ว'
                                : 'กำลังออนไลน์ในห้อง...',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isHostUser ? AppColors.success : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isHostUser
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isHostUser ? 'พร้อม ✨' : 'ออนไลน์',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isHostUser ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),
            const Text(
              '👥 เพื่อนเข้าเกือบครบแล้ว สามารถเริ่มจิ้มอาหารได้เลย',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            if (_isHost)
              CustomButton(
                text: 'เข้าสู่หน้าจิ้มอาหาร (Start Claiming) ➔',
                onPressed: _startClaiming,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                    SizedBox(width: 10),
                    Text(
                      'รอเจ้ามือกดเริ่มจิ้มอาหาร...',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(trailingIcon, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
