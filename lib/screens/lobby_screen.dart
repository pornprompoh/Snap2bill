import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../providers/bill_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class LobbyScreen extends StatefulWidget {
  final String? lobbyId;
  final Map<String, dynamic>? receiptData;
  final bool isHost; // 🚀 เพิ่มตัวแปรนี้

  const LobbyScreen({
    super.key,
    this.lobbyId,
    this.receiptData,
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
    context.read<BillProvider>().setActiveRoom(_roomId);

    _currentUserId =
        _supabase.auth.currentUser?.id ??
        'guest_${DateTime.now().millisecondsSinceEpoch}';
    final email = _supabase.auth.currentUser?.email;
    _currentUserName = email != null
        ? email.split('@')[0]
        : 'Guest (${_currentUserId.substring(_currentUserId.length - 4)})';

    if (_isHost) {
      _createLobbyInDB();
    }

    _setupRealtimeLobby();
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
    final roomParticipants = context
        .read<BillProvider>()
        .roomParticipants
        .map((participant) => participant.toMap())
        .toList();
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

  @override
  Widget build(BuildContext context) {
    final invitees = context.watch<BillProvider>().roomParticipants;
    final presentIds = _participants
        .map((participant) => participant['user_id']?.toString())
        .whereType<String>()
        .toSet();
    final roomParticipants = [
      ..._participants,
      ...invitees
          .where((participant) => !presentIds.contains(participant.id))
          .map((participant) {
            final displayName = participant.displayName?.trim();
            return {
              'user_id': participant.id,
              'user_name': displayName?.isNotEmpty == true
                  ? displayName
                  : participant.email?.split('@').first ?? 'เพื่อน',
              'is_host': false,
              'is_invited': true,
            };
          }),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('รอเพื่อนเข้าห้อง (Lobby)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'ให้เพื่อนสแกน QR Code นี้',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: _joinLink,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'หรือกรอกรหัสห้อง: $_roomId',
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'สมาชิกในห้อง:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  '${roomParticipants.length} คน',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isHost)
                  IconButton(
                    tooltip: 'ดึงเพื่อนเก่าเข้าห้อง',
                    onPressed: _selectPastParticipants,
                    icon: const Icon(Icons.person_add_alt_1),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: roomParticipants.length,
                itemBuilder: (context, index) {
                  final user = roomParticipants[index];
                  final isMe = user['user_id'] == _currentUserId;
                  final isUserHost = user['is_host'] == true;
                  final isInvited = user['is_invited'] == true;

                  return Card(
                    color: isUserHost
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isUserHost
                            ? Colors.orange.shade200
                            : Colors.blue.shade200,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isUserHost
                            ? Colors.orange
                            : Colors.blue,
                        child: Icon(
                          isUserHost ? Icons.star : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        '${user['user_name']} ${isMe ? "(ฉัน)" : ""}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        isUserHost
                            ? 'หัวหน้าห้อง'
                            : isInvited
                            ? 'เพิ่มโดยหัวหน้าห้อง'
                            : 'ผู้เข้าร่วม',
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isHost)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: CustomButton(
                  text: 'เพื่อนครบแล้ว เริ่มแย่งเมนูเลย!',
                  onPressed: _startClaiming,
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
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
