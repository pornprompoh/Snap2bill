import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        // ล้างประวัติหน้าจอทั้งหมดแล้วเด้งกลับไปหน้า Login
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถออกจากระบบได้ กรุณาลองใหม่')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลผู้ใช้ปัจจุบัน
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'ไม่พบข้อมูลอีเมล';

    return Scaffold(
      appBar: AppBar(title: const Text('โปรไฟล์ส่วนตัว')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingM),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.paddingXL),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: AppConstants.paddingL),
            const Text(
              'ข้อมูลบัญชีของคุณ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.paddingS),
            Text(
              email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Spacer(), // ดันปุ่มลงไปด้านล่างสุด
            CustomButton(
              text: 'ออกจากระบบ',
              backgroundColor: Colors.red.shade400,
              onPressed: () => _logout(context),
            ),
            const SizedBox(height: AppConstants.paddingL),
          ],
        ),
      ),
    );
  }
}