import 'package:flutter/material.dart';
import '../../services/supabase_auth_service.dart'; // เช็ก path ให้ตรงกับโฟลเดอร์ของคุณนะครับ
import '../home_screen.dart'; // [เพิ่ม] import หน้า HomeScreen เข้ามา

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ทดสอบระบบ Login')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                // TODO: (ฝากเพื่อนฝั่ง UI) ตกแต่งปุ่มนี้ให้เป็นปุ่ม "Continue with Google" สวยๆ
                // ห้ามลบ/แก้ไขโค้ดใน onPressed เด็ดขาด เพราะผูกหลังบ้านไว้แล้ว
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    final response = await SupabaseAuthService().signInWithGoogle();
                    
                    if (!context.mounted) return;
                    
                    if (response != null && response.user != null) {
                      // ดึง User ID ออกมาโชว์เพื่อยืนยันว่าหลังบ้านทำงานสำเร็จ
                      final userId = response.user!.id;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('ล็อกอินสำเร็จ! User ID: $userId')),
                      );
                      
                      // [แก้ไข] เปลี่ยนจากคอมเมนต์ TODO เป็นคำสั่งพาไปหน้า Home
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ล็อกอินล้มเหลว: $e')),
                    );
                  } finally {
                    if (context.mounted) setState(() => _isLoading = false);
                  }
                },
                child: const Text('Sign in with Google'),
              ),
      ),
    );
  }
}