import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/friend_item.dart';

class FriendListScreen extends StatefulWidget {
  // ต้องมีบรรทัดนี้ app_routes.dart ถึงจะหา constructor เจอ
  const FriendListScreen({super.key}); 

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    // ดึง ID ของ User ที่ล็อกอินอยู่
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('รายชื่อเพื่อน')),
      body: userId == null
          ? const Center(child: Text('กรุณาล็อกอิน'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              // 🚀 เชื่อมตาราง friends ของจริง
              stream: _supabase
                  .from('friends')
                  .stream(primaryKey: ['id'])
                  .eq('owner_id', userId), // กรองเอาเฉพาะเพื่อนของคนที่ล็อกอิน
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final friends = snapshot.data ?? [];

                // กรณีไม่มีเพื่อนใน Database เลย
                if (friends.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'ยังไม่มีเพื่อนในระบบ\nกดปุ่มด้านล่างเพื่อเพิ่มเพื่อน',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // กรณีมีเพื่อน ให้แสดงผลด้วย FriendItem
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return FriendItem(
                      // ดึงชื่อเพื่อนจากคอลัมน์ในฐานข้อมูล (แก้ชื่อฟิลด์ให้ตรงกับตารางคุณ)
                      name: friend['friend_name'] ?? 'ไม่มีชื่อ', 
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ระบบสแกน QR เพิ่มเพื่อน (กำลังพัฒนา)')),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('เพิ่มเพื่อน'),
      ),
    );
  }
}