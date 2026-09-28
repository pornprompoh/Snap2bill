import 'dart:async'; // 🚀 นำเข้า async เพื่อใช้ Timer
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class LobbyScreen extends StatefulWidget {
  final String? lobbyId; 
  final Map<String, dynamic>? receiptData; 

  const LobbyScreen({super.key, this.lobbyId, this.receiptData});

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
  Timer? _checkHostTimer; // 🚀 ตัวแปรสำหรับจับเวลาตรวจหาหัวหน้าห้อง

  @override
  void initState() {
    super.initState();
    
    _isHost = widget.receiptData != null;
    _roomId = widget.lobbyId ?? (100000 + Random().nextInt(900000)).toString();

    _currentUserId = _supabase.auth.currentUser?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final email = _supabase.auth.currentUser?.email;
    _currentUserName = email != null ? email.split('@')[0] : 'ผู้เข้าร่วม';

    _setupRealtimeLobby();
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
      }
    });

    _lobbyChannel.onBroadcast(event: 'start_claim', callback: (payload) {
      if (!_isHost && mounted) {
        Navigator.pushReplacementNamed(
          context, 
          AppRoutes.claim,
          arguments: {
            'lobbyId': _roomId,
            'receiptData': payload['receiptData'], 
          }
        );
      }
    });

    _lobbyChannel.subscribe((status, error) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _lobbyChannel.track({
          'user_id': _currentUserId,
          'user_name': _currentUserName,
          'is_host': _isHost,
        });

        // 🚀 ระบบป้องกันการเข้าห้องมั่ว (สำหรับ Guest)
        if (!_isHost) {
          // ให้เวลาดึงข้อมูล 3 วินาที ถ้าไม่เจอ Host จะเด้งออกทันที
          _checkHostTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              final hasHost = _participants.any((p) => p['is_host'] == true);
              if (!hasHost) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('รหัสห้องไม่ถูกต้อง หรือห้องนี้ถูกปิดไปแล้ว'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context); // เตะกลับหน้าแรก
              }
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _checkHostTimer?.cancel(); // 🚀 ล้าง Timer ทิ้งเวลาเปลี่ยนหน้าป้องกัน Error
    _supabase.removeChannel(_lobbyChannel); 
    super.dispose();
  }

  void _startClaiming() {
    if (!_isHost) return;

    _lobbyChannel.sendBroadcastMessage(
      event: 'start_claim',
      payload: {
        'receiptData': widget.receiptData,
      },
    );

    Navigator.pushReplacementNamed(
      context, 
      AppRoutes.claim,
      arguments: {
        'lobbyId': _roomId,
        'receiptData': widget.receiptData,
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รอเพื่อนเข้าห้อง (Lobby)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('ให้เพื่อนสแกน QR Code นี้', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: 'snap2bill://join/$_roomId', 
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                    const SizedBox(height: 16),
                    Text('หรือกรอกรหัสห้อง: $_roomId', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('เพื่อนที่อยู่ในห้องตอนนี้:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('${_participants.length} คน', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: ListView.builder(
                itemCount: _participants.length,
                itemBuilder: (context, index) {
                  final user = _participants[index];
                  final isMe = user['user_id'] == _currentUserId;
                  final isUserHost = user['is_host'] == true;

                  return Card(
                    color: isUserHost ? Colors.orange.shade50 : Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: isUserHost ? Colors.orange.shade200 : Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isUserHost ? Colors.orange : Colors.blue,
                        child: Icon(isUserHost ? Icons.star : Icons.person, color: Colors.white),
                      ),
                      title: Text(
                        '${user['user_name']} ${isMe ? "(ฉัน)" : ""}', 
                        style: const TextStyle(fontWeight: FontWeight.bold)
                      ),
                      subtitle: Text(isUserHost ? 'หัวหน้าห้อง' : 'ผู้เข้าร่วม'),
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
                child: Text('กำลังรอหัวหน้าห้องกดเริ่ม...', style: TextStyle(color: Colors.grey, fontSize: 16)),
              )
          ],
        ),
      ),
    );
  }
}