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
import '../../../theme/app_text_styles.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/bill/guest_dialog.dart';

class LobbyScreen extends StatefulWidget {
  final String? lobbyId;
  final Map<String, dynamic>? receiptData;
  final Uint8List? receiptImageBytes;
  final bool isHost; // 🚀 เพิ่มตัวแปรนี้

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

    _isHost = widget.isHost; // 🚀 ใช้ค่าที่ส่งมาตรงๆ
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
        if (!_isHost && mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.claim,
            arguments: {
              'lobbyId': _roomId,
              'receiptData': payload['receiptData'],
              'roomParticipants': payload['roomParticipants'],
              'isHost': false, // 🚀 ส่งต่อให้ Guest
            },
          );
        }
      },
    );

    _lobbyChannel.onBroadcast(
      event: 'add_room_participants',
      callback: _mergeInvitedParticipants,
    );

    _lobbyChannel.onBroadcast(
      event: 'add_guest_member',
      callback: (payload) {
        final rawMember = payload['member'];
        if (rawMember is! Map) return;
        final member = RoomMember.fromMap(Map<String, dynamic>.from(rawMember));
        if (!member.isGuest) return;
        context.read<BillProvider>().mergeRoomMembers([member]);
      },
    );

    _lobbyChannel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _lobbyChannel.track({
          'user_id': _currentUserId,
          'user_name': _currentUserName,
          'is_host': _isHost,
        });
      }
    });
  }

  Future<void> _selectPastParticipants() async {
    final selected = await Navigator.pushNamed<List<UserModel>>(
      context,
      AppRoutes.friends,
      arguments: true,
    );
    if (!mounted || selected == null || selected.isEmpty) return;

    final participants = context.read<BillProvider>().addRoomParticipants(
      _roomId,
      selected,
    );
    final payload = {
      'participants': participants
          .map((participant) => participant.toMap())
          .toList(),
    };
    _mergeInvitedParticipants(payload);
    _lobbyChannel.sendBroadcastMessage(
      event: 'add_room_participants',
      payload: payload,
    );
  }

  Future<void> _addGuestMember() async {
    final nameController = TextEditingController();
    final guestName = await showDialog<String>(
      context: context,
      builder: (_) => GuestDialog(controller: nameController),
    );
    nameController.dispose();
    if (!mounted || guestName == null || guestName.trim().isEmpty) return;

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
        'isHost': true, // 🚀 ส่งต่อให้ Host
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

  Future<void> _shareJoinLink() async {
    final shop = widget.receiptData?['shop_name'] ?? 'โต๊ะนี้';
    await SharePlus.instance.share(
      ShareParams(
        title: 'เข้าร่วมห้อง Snap2Bill',
        text: '🍲 มาหารบิล $shop กัน!\n'
            '📲 แตะลิงก์เข้าร่วมห้อง: $_joinLink\n'
            '🔢 หรือกรอกรหัสห้อง: $_roomId\n'
            '(เปิดเว็บเข้าหารได้ทันที ไม่ต้องโหลดแอป)',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final roomParticipants = _buildRoomParticipantMaps(billProvider);
    final hostName = _participants
        .where((participant) => participant['is_host'] == true)
        .map((participant) => participant['user_name']?.toString())
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Lobby (ชวนเพื่อนเข้าห้อง)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // การ์ด QR Code ขนาดใหญ่ พร้อมรหัสห้อง
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.07),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text('สแกน QR เพื่อเข้าร่วมโต๊ะ', style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    'เพื่อนเปิดกล้องสแกนเข้าร่วมได้ทันทีโดยไม่ต้องติดตั้งแอป',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: _joinLink,
                      version: QrVersions.auto,
                      size: 210,
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
                  const SizedBox(height: 14),
                  Text('รหัสห้อง 6 หลัก', style: AppTextStyles.caption),
                  const SizedBox(height: 4),
                  SelectableText(
                    _roomId,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3 ปุ่มหลัก: คัดลอกลิงก์ | แชร์เข้ากลุ่ม LINE | แชร์อื่นๆ
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyJoinLink,
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          label: const Text('คัดลอกลิงก์'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _shareToLine,
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('แชร์เข้า LINE'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF06C755), // LINE Green
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: _shareJoinLink,
                        tooltip: 'แชร์ผ่านแอปอื่น',
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ],
                  ),
                  if (_isHost) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            onPressed: _addGuestMember,
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('พิมพ์ชื่อเพื่อนเอง'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              backgroundColor: AppColors.secondary.withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _selectPastParticipants,
                          tooltip: 'เลือกจากประวัติเพื่อนเก่า',
                          icon: const Icon(Icons.contacts_outlined, size: 18),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ส่วนแสดงรายชื่อผู้เข้าร่วมและสถานะแบบ Real-time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ผู้เข้าร่วมในห้อง (Real-time)', style: AppTextStyles.title),
                      Text(
                        hostName == null
                            ? '${roomParticipants.length} คนอยู่ในห้อง'
                            : 'เจ้ามือ: $hostName',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${roomParticipants.length} คน',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // รายชื่อเพื่อนแบบ Real-time Card พร้อมสถานะ
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roomParticipants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = roomParticipants[index];
                final userId = user['user_id']?.toString();
                final userName = user['user_name']?.toString() ?? 'เพื่อน';
                final isHostUser = user['is_host'] == true;
                final isGuestUser = user['is_guest'] == true;
                final isSelf = userId == _currentUserId;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelf
                          ? AppColors.primary.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isHostUser
                            ? Colors.amber.shade100
                            : AppColors.secondary.withValues(alpha: 0.8),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isHostUser
                                ? Colors.amber.shade900
                                : AppColors.primaryDark,
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (isSelf)
                                  const Text(
                                    ' (คุณ)',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              isHostUser
                                  ? '👑 เจ้าของห้อง (กำลังคุมตี้)'
                                  : isGuestUser
                                  ? '👤 ไม่มีแอป (เจ้ามือช่วยจิ้ม)'
                                  : '🟢 กำลังเตรียมเลือกอาหาร',
                              style: TextStyle(
                                fontSize: 12,
                                color: isHostUser
                                    ? Colors.amber.shade800
                                    : isGuestUser
                                    ? Colors.grey.shade600
                                    : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isHostUser
                              ? Colors.amber.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isHostUser
                                ? Colors.amber.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          isHostUser ? 'เจ้ามือ' : 'พร้อมจิ้ม ✨',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isHostUser
                                ? Colors.amber.shade900
                                : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            if (_isHost)
              CustomButton(
                text: 'เพื่อนครบแล้ว เริ่มจิ้มอาหารเลย! ✨',
                onPressed: _startClaiming,
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'รอเจ้ามือกดเริ่มจิ้มอาหาร...',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
