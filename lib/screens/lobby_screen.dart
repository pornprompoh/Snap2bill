import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'claim_screen.dart'; // TODO: สร้างในสเตปต่อไป

class LobbyScreen extends StatefulWidget {
  final Map<String, dynamic> receiptData;
  const LobbyScreen({super.key, required this.receiptData});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _supabase = Supabase.instance.client;
  String? _lobbyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _createLobby();
  }

  Future<void> _createLobby() async {
    try {
      final shopName = widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
      final totalAmount = double.tryParse(widget.receiptData['total_amount']?.toString() ?? '0') ?? 0.0;

      // 1. สร้างห้องใหม่ใน Supabase
      final response = await _supabase.from('lobbies').insert({
        'host_id': '11111111-1111-1111-1111-111111111111', // ใช้ ID จำลองสำหรับ PoC ไปก่อน
        'shop_name': shopName,
        'total_amount': totalAmount,
        'receipt_json': widget.receiptData,
      }).select().single();

      final lobbyId = response['id'];

      // 2. จับตัวเอง (Host) ยัดใส่เข้าห้องเป็นคนแรก
      await _supabase.from('participants').insert({
        'lobby_id': lobbyId,
        'user_name': 'ฉัน (Host)',
        'is_host': true,
      });

      setState(() {
        _lobbyId = lobbyId;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('กำลังสร้างห้อง...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('รอเพื่อนเข้าห้อง (Lobby)')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // ส่วนจำลอง QR Code ให้เพื่อนแสกน
          const Text('ให้เพื่อนสแกน QR Code นี้', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(Icons.qr_code_2, size: 150),
          ),
          const SizedBox(height: 10),
          Text('รหัสห้อง: ${_lobbyId?.substring(0, 8)}...', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('เพื่อนที่อยู่ในห้องตอนนี้:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          
          // ระบบ Real-time ดักฟังตาราง participants
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('participants')
                  .stream(primaryKey: ['id'])
                  .eq('lobby_id', _lobbyId!)
                  .order('joined_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final participants = snapshot.data!;
                return ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final p = participants[index];
                    final isHost = p['is_host'] == true;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isHost ? Colors.amber : Colors.blue.shade100,
                        child: Icon(isHost ? Icons.star : Icons.person, color: isHost ? Colors.white : Colors.blue),
                      ),
                      title: Text(p['user_name']),
                      subtitle: Text(isHost ? 'หัวหน้าห้อง' : 'เข้าร่วมแล้ว'),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
                  if (_lobbyId == null) return;
                  
                  // อัปเดตสถานะห้องเป็น splitting (เริ่มหาร)
                  _supabase.from('lobbies').update({'status': 'splitting'}).eq('id', _lobbyId!);

                  // พาไปหน้า Claim พร้อมแนบรหัสห้อง
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClaimScreen(
                        lobbyId: _lobbyId!,
                        receiptData: widget.receiptData,
                      ),
                    ),
                  );
                },
                child: const Text('เริ่มเลือกเมนูอาหาร', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}