import 'package:flutter/material.dart';
import '../../services/supabase_auth_service.dart'; 
import '../../routes/app_routes.dart'; // 🚀 นำเข้าระบบนำทาง
import '../../widgets/custom_button.dart'; // 🚀 นำเข้าปุ่มสำเร็จรูป
import '../../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseAuthService().signInWithGoogle();
      
      if (!mounted) return;
      
      if (response != null && response.user != null) {
        final userId = response.user!.id;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ล็อกอินสำเร็จ! User ID: $userId')),
        );
        
        // 🚀 เปลี่ยนเป็นใช้ AppRoutes ตามโครงสร้างใหม่
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ล็อกอินล้มเหลว: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 100, color: Colors.deepPurple),
              const SizedBox(height: AppConstants.paddingM),
              const Text(
                'Snap2Bill',
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.deepPurple
                ),
              ),
              const SizedBox(height: 50),
              
              // 🚀 ใช้ CustomButton เชื่อมกับ Google Sign-In พร้อมลูกเล่น Loading
              CustomButton(
                text: 'Login',
                isLoading: _isLoading, 
                backgroundColor: Colors.redAccent, // สีสไตล์ Google
                onPressed: _handleGoogleSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}