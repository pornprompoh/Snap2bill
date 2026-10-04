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
import '../../../widgets/friend_item.dart';

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
      if (mounted) setState(() => _participants = users);
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

  Future<void> _shareJoinLink() async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'เข้าร่วมห้อง Snap2Bill',
        text: 'สแกนหรือเปิดลิงก์เพื่อเข้าร่วมห้อง $_roomId\n$_joinLink',
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
      appBar: AppBar(title: const Text('รอเพื่อนเข้าห้อง (Lobby)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.06),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text('สแกนเพื่อเข้าร่วมห้อง', style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(
                    'แชร์ลิงก์หรือให้เพื่อนกรอกรหัสห้อง',
                    style: AppTextStyles.caption,
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
                      data: _joinLink,
                      version: QrVersions.auto,
                      size: 188,
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
                  Text('รหัสห้อง', style: AppTextStyles.caption),
                  const SizedBox(height: 3),
                  SelectableText(
                    _roomId,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 32,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyJoinLink,
                          icon: const Icon(Icons.copy_outlined),
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _shareJoinLink,
                          icon: const Icon(Icons.share_outlined),
                          label: const Text('แชร์ห้อง'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('สมาชิกในห้อง', style: AppTextStyles.title),
                      Text(
                        hostName == null
                            ? '${roomParticipants.length} คนกำลังเข้าร่วม'
                            : 'หัวหน้าห้อง: $hostName',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${roomParticipants.length} คน',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_isHost)
                  IconButton(
                    tooltip: 'ดึงเพื่อนเก่าเข้าห้อง',
                    onPressed: _selectPastParticipants,
                    color: AppColors.primary,
                    icon: const Icon(Icons.person_add_alt_1),
                  ),
              ],
            ),
            if (_isHost)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addGuestMember,
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('+ เพิ่มเพื่อนที่ไม่มีแอป'),
                ),
              ),
            const SizedBox(height: 10),
            SizedBox(
              height: 82,
              child: Align(
                alignment: Alignment.topLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: roomParticipants.map((user) {
                      final userId = user['user_id']?.toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FriendAvatar(
                          name:
                              '${user['user_name']?.toString() ?? 'เพื่อน'}'
                              '${user['is_guest'] == true ? ' (Guest)' : ''}',
                          isHost: user['is_host'] == true,
                          isCurrentUser: userId == _currentUserId,
                          isInvited: user['is_invited'] == true,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            if (_isHost)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: CustomButton(
                  text: 'เพื่อนครบแล้ว เริ่มแย่งเมนูเลย!',
                  onPressed: _startClaiming,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'กำลังรอหัวหน้าห้องกดเริ่ม...',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
