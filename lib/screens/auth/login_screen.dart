import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_auth_service.dart'; 
import '../../routes/app_routes.dart'; 
import '../../widgets/custom_button.dart'; 
import '../../utils/constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    
    // 🚀 1. เช็กว่าล็อกอินค้างไว้ไหม "หลังจากวาดหน้าจอเสร็จแล้ว" (แก้ปัญหาจอดำ)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });

    // 🚀 2. ดักฟังจังหวะที่เว็บ Redirect กลับมาจาก Google แล้วได้ Token
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      
      // ถ้าพบว่าล็อกอินสำเร็จ ให้เด้งไปหน้า Home ทันที
      if (event == AuthChangeEvent.signedIn || session != null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel(); // ปิดตัวดักฟังเมื่อเปลี่ยนหน้า
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseAuthService().signInWithGoogle();
      
      if (!mounted) return;
      
      // ถ้ารันบนมือถือและล็อกอินผ่าน (ป๊อปอัพ) จะได้ response กลับมา
      if (response != null && response.user != null) {
        final userId = response.user!.id;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ล็อกอินสำเร็จ! User ID: $userId')),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
      // หมายเหตุ: บนเว็บ โค้ดจะหยุดทำแค่นี้ เพราะมัน Redirect โยนไปหน้า Google แล้ว
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
              
              CustomButton(
                text: 'Login',
                isLoading: _isLoading, 
                backgroundColor: Colors.redAccent, 
                onPressed: _handleGoogleSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}