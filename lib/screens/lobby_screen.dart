import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_button.dart';

class LobbyScreen extends StatefulWidget {
  final Map<String, dynamic> receiptData;
  const LobbyScreen({super.key, required this.receiptData});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _supabase = Supabase.instance.client;
  late RealtimeChannel _lobbyChannel;
  List<Map<String, dynamic>> _participants = [];
  late String _lobbyId;
  final bool _isHost = true;

  @override
  void initState() {
    super.initState();
    _lobbyId = (100000 + Random().nextInt(900000)).toString();
    
    // 🚀 เพิ่มตัวเราเอง (Host) เข้าไปในลิสต์ตั้งต้นทันที ตั้งแต่เปิดหน้าจอ
    final userId = _supabase.auth.currentUser?.id ?? 'host_id';
    _participants = [
      {
        'user_id': userId,
        'user_name': 'ฉัน (Host)',
        'is_host': true,
      }
    ];

    _setupRealtime();
  }

  void _setupRealtime() {
    final userId = _supabase.auth.currentUser?.id ?? 'host_id';
    final userName = 'ฉัน (Host)'; 

    _lobbyChannel = _supabase.channel('room_$_lobbyId');

    _lobbyChannel
        .onPresenceSync((payload) {
          final newState = _lobbyChannel.presenceState();
          final List<Map<String, dynamic>> usersInRoom = [];
          
          // บังคับให้มี Host ตั้งต้นเสมอ
          usersInRoom.add({
            'user_id': userId,
            'user_name': userName,
            'is_host': true,
          });

          // ดึงรายชื่อเพื่อนคนอื่นๆ ที่กดเข้ามาเพิ่ม
          for (var presence in newState) {
            for (var item in presence.presences) {
              final pUserId = item.payload['user_id'];
              // ถ้าไม่ใช่ไอดีซ้ำกับ Host ค่อย 
              if (pUserId != userId) {
                usersInRoom.add({
                  'user_id': pUserId,
                  'user_name': item.payload['user_name'],
                  'is_host': item.payload['is_host'] ?? false,
                });
              }
            }
          }
          
          setState(() {
            _participants = usersInRoom;
          });
        })
        .subscribe((status, [error]) async {
          if (status == 'SUBSCRIBED') {
            await _lobbyChannel.track({
              'user_id': userId,
              'user_name': userName,
              'is_host': _isHost,
            });
          }
        });
  }

  @override
  void dispose() {
    _supabase.removeChannel(_lobbyChannel);
    super.dispose();
  }

  void _goToClaimScreen() {
    final data = Map<String, dynamic>.from(widget.receiptData);
    data['lobbyId'] = _lobbyId;

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.claim,
      arguments: data,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รอเพื่อนเข้าห้อง (Lobby)')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Text('ให้เพื่อนสแกน QR Code นี้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: QrImageView(
                data: 'https://snap2bill.com/join/$_lobbyId',
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          Text('หรือกรอกรหัสห้อง: $_lobbyId', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 32),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('เพื่อนที่อยู่ในห้องตอนนี้:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${_participants.length} คน', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: _participants.length,
                      itemBuilder: (context, index) {
                        final p = _participants[index];
                        final isHost = p['is_host'] == true;
                        
                        return Card(
                          elevation: 0,
                          color: isHost ? Colors.orange.shade50 : Colors.grey.shade50,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: isHost ? Colors.orange.shade200 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12)
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isHost ? Colors.orange : Colors.grey,
                              child: Icon(isHost ? Icons.star : Icons.person, color: Colors.white),
                            ),
                            title: Text(p['user_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(isHost ? 'หัวหน้าห้อง' : 'ผู้เข้าร่วม'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'เพื่อนครบแล้ว เริ่มแย่งเมนูเลย!',
              // ปลดล็อกให้กดได้ทันที เพราะมีตัวเราอยู่ในห้องอย่างน้อย 1 คนเสมอ
              onPressed: _goToClaimScreen, 
            ),
          )
        ],
      ),
    );
  }
}