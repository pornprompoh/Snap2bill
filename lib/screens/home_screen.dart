import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_routes.dart';
import '../utils/formatters.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  
  late final Future<List<Map<String, dynamic>>> _billsFuture;
  bool _isCheckingRoom = false; 

  @override
  void initState() {
    super.initState();
    final currentUserId = _supabase.auth.currentUser?.id ?? '';
    
    _billsFuture = _supabase
        .from('bills')
        .select()
        .eq('owner_id', currentUserId)
        .order('created_at', ascending: false);
  }

  // 🚀 สเตป 2: ฟังก์ชันเช็กรหัสห้องจากตาราง lobbies โดยตรง ไม่ง้อการแอบส่องแล้ว
  Future<void> _joinRoom(String roomCode) async {
    if (roomCode.length != 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสห้องให้ครบ 6 หลัก')),
      );
      return;
    }

    setState(() => _isCheckingRoom = true);

    try {
      // ค้นหาห้องจากคอลัมน์ room_code ที่เราเพิ่งสร้าง
      final response = await _supabase
          .from('lobbies')
          .select()
          .eq('room_code', roomCode)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        // ถ้ารหัสถูกต้อง พบห้องในระบบ ให้ดึงข้อมูลบิล (receipt_json) ส่งไปให้ Guest ด้วย
        final shopName = response['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
        final receiptData = response['receipt_json'] as Map<String, dynamic>?;
        
        Navigator.pushNamed(
          context, 
          AppRoutes.lobby,
          arguments: {
            'lobbyId': roomCode, 
            'shop_name': shopName,
            'receiptData': receiptData, // ส่งข้อมูลบิลไปให้ Guest เลย
            'isHost': false,
          } 
        );
      } else {
        // ถ้าไม่พบรหัสห้อง ให้แจ้งเตือนทันที
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รหัสไม่ถูกต้อง หรือไม่มีห้องนี้อยู่จริง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการตรวจสอบห้อง: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingRoom = false);
      }
    }
  }

  void _showJoinRoomDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('เข้าร่วมห้องหารบิล'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'กรอกรหัส 6 หลัก',
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text('ยกเลิก')
          ),
          ElevatedButton(
            onPressed: _isCheckingRoom 
                ? null 
                : () {
                    Navigator.pop(dialogContext); 
                    _joinRoom(codeController.text); 
                  },
            child: _isCheckingRoom 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                : const Text('เข้าร่วม'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap2Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            tooltip: 'เข้าร่วมห้องด้วยรหัส',
            onPressed: () => _showJoinRoomDialog(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _showJoinRoomDialog(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('มีเพื่อนสร้างห้องไว้แล้ว?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('กรอกรหัส 6 หลักเพื่อเข้าร่วม', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('ประวัติการหารบิล', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _billsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError) {
                    return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }
                  
                  final bills = snapshot.data ?? [];
                  
                  if (bills.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text('ยังไม่มีประวัติบิล', style: TextStyle(color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: bills.length,
                    itemBuilder: (context, index) {
                      final bill = bills[index];
                      final shopName = bill['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
                      final totalAmount = double.tryParse(bill['sub_total']?.toString() ?? '0') ?? 0.0;
                      final date = bill['created_at']?.toString().split('T')[0] ?? '';

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.receipt),
                          ),
                          title: Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(date),
                          trailing: Text(
                            AppFormatters.formatCurrency(totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context, 
                              AppRoutes.detail,
                              arguments: bill,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}