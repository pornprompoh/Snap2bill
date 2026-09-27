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
  
  // 🚀 1. เปลี่ยนจาก Stream เป็น Future
  late final Future<List<Map<String, dynamic>>> _billsFuture;

  @override
  void initState() {
    super.initState();
    final currentUserId = _supabase.auth.currentUser?.id ?? '';
    
    // 🚀 2. ใช้ .select() ดึงข้อมูลครั้งเดียวจบ (ไม่ต้องง้อ Realtime บนฐานข้อมูล)
    _billsFuture = _supabase
        .from('bills')
        .select()
        .eq('owner_id', currentUserId)
        .order('created_at', ascending: false);
  }

  void _joinRoom(BuildContext context, String roomCode) {
    if (roomCode.length == 6) {
      Navigator.pushNamed(
        context, 
        AppRoutes.lobby,
        arguments: {'lobbyId': roomCode, 'shop_name': 'กำลังโหลดข้อมูล...'} 
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสห้องให้ครบ 6 หลัก'))
      );
    }
  }

  void _showJoinRoomDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinRoom(context, codeController.text);
            },
            child: const Text('เข้าร่วม'),
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
              // 🚀 3. เปลี่ยนมาใช้ FutureBuilder แทน
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