import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bill_provider.dart';
import '../providers/user_provider.dart';
import '../services/supabase_auth_service.dart';
import 'auth/login_screen.dart';
import 'friends/friend_list_screen.dart';
import 'scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // สั่งให้ Provider โหลดข้อมูลทันทีที่เปิดหน้านี้ขึ้นมา
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadProfile();
      Provider.of<BillProvider>(context, listen: false).loadMyBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = Provider.of<BillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap2Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendListScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseAuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
          ),
        ],
      ),
      body: billProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : billProvider.bills.isEmpty
              ? const Center(child: Text('ยังไม่มีบิล กดปุ่ม + ด้านล่างเพื่อจำลองการสร้างบิลเลย'))
              : ListView.builder(
                  itemCount: billProvider.bills.length,
                  itemBuilder: (context, index) {
                    final bill = billProvider.bills[index];
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(bill.shopName ?? 'บิลไม่มีชื่อร้าน'),
                      subtitle: Text('ยอดสุทธิ: ${bill.totalAmount} บาท'),
                      trailing: Text(bill.status),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // ทดสอบระบบ: พอกด + จะสร้างบิลจำลองส่งไป Supabase ทันที (จะเปลี่ยนเป็นไปหน้ากล้องใน Step 5)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanScreen()),
          );
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}