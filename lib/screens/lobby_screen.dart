import 'dart:async';
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

  @override
  void initState() {
    super.initState();
    
    _isHost = widget.receiptData != null;
    // สุ่มเลข 6 หลักถ้ายังไม่มี
    _roomId = widget.lobbyId ?? (100000 + Random().nextInt(900000)).toString();

    _currentUserId = _supabase.auth.currentUser?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final email = _supabase.auth.currentUser?.email;
    _currentUserName = email != null ? email.split('@')[0] : 'ผู้เข้าร่วม';

    // 🚀 สเตป 1: ถ้าเป็น Host ให้สร้างห้องนี้ลงในตาราง lobbies ของ Supabase
    if (_isHost) {
      _createLobbyInDB();
    }

    _setupRealtimeLobby();
  }

  // 🚀 ฟังก์ชันสร้างห้องในฐานข้อมูล
// 🚀 ฟังก์ชันสร้างห้องในฐานข้อมูล (ฉบับแสดง Error บนหน้าจอ)
  Future<void> _createLobbyInDB() async {
    try {
      final existing = await _supabase
          .from('lobbies')
          .select('id')
          .eq('room_code', _roomId)
          .maybeSingle();

      if (existing == null && mounted) {
        // 🚀 ดึงยอดรวมมาใส่ด้วย เผื่อฐานข้อมูลบังคับ (Not Null)
        final rawTotalAmount = double.tryParse(widget.receiptData?['total_amount']?.toString() ?? '0') ?? 0.0;

        await _supabase.from('lobbies').insert({
          'host_id': _supabase.auth.currentUser?.id,
          'room_code': _roomId,
          'shop_name': widget.receiptData?['shop_name'] ?? 'ไม่ระบุชื่อร้าน',
          'total_amount': rawTotalAmount, // ส่งยอดเงินเข้าไปด้วย
          'status': 'waiting',
          'receipt_json': widget.receiptData, 
        });
        debugPrint('✅ สร้างห้องรหัส $_roomId ลงฐานข้อมูลเรียบร้อยแล้ว');
      }
    } catch (e) {
      debugPrint('❌ ตั้งห้องใน DB ไม่สำเร็จ: $e');
      // 🚀 เด้งแถบแดงเตือนบนหน้าจอให้เรารู้ทันทีว่าฐานข้อมูลติดอะไร!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DB Error (Lobby): $e'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          )
        );
      }
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
      }
    });
  }

  @override
  void dispose() {
    _supabase.removeChannel(_lobbyChannel); 
    super.dispose();
  }

  void _startClaiming() async {
    if (!_isHost) return;

    // 🚀 อัปเดตสถานะห้องว่าเริ่มแย่งเมนูแล้ว (เพื่อไม่ให้คนนอกเข้ามั่ว)
    try {
      await _supabase.from('lobbies').update({'status': 'claiming'}).eq('room_code', _roomId);
    } catch (e) {
      debugPrint('อัปเดตสถานะห้องไม่สำเร็จ: $e');
    }

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