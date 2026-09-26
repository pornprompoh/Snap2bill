import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize(
        clientId: '400887731254-ipi7qcbn006uucpuehvc2ur2f18oq6c7.apps.googleusercontent.com',
        serverClientId: '400887731254-1d2b056maqqtsgloh488fg36qe0r0upv.apps.googleusercontent.com',
      );
      _isInitialized = true;
    }
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'http://localhost:3000', 
        );
        return null; 
      }

      await _ensureInitialized();

      // ไม่ต้องเช็ก null แล้ว เพราะถ้าไม่ได้ user มันจะกระโดดไปเข้า catch (e) ด้านล่างแทน
      final googleUser = await _googleSignIn.authenticate(); 

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw 'ไม่สามารถดึงข้อมูล Token จาก Google ได้';
      }

      // ส่งแค่ idToken ตัวเดียวให้ Supabase ก็ล็อกอินผ่านแล้วครับ
      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการล็อกอิน: $e');
      rethrow; // โยน error กลับไปให้หน้า UI จัดการ (เช่น โชว์ป๊อปอัปแจ้งเตือน)
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}