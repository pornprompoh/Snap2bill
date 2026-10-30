import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  bool _isInitialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  Future<FirebaseAuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _saveProfile(credential.user);
      return FirebaseAuthResult.success(credential);
    } on FirebaseAuthException catch (error) {
      return FirebaseAuthResult.failure(
        code: error.code,
        message: _messageFor(error),
      );
    }
  }

  Future<FirebaseAuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _saveProfile(credential.user);
      return FirebaseAuthResult.success(credential);
    } on FirebaseAuthException catch (error) {
      return FirebaseAuthResult.failure(
        code: error.code,
        message: _messageFor(error),
      );
    }
  }

  Future<FirebaseAuthResult> signInWithFacebook() async {
    try {
      final provider = FacebookAuthProvider();
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      await _saveProfile(credential.user);
      return FirebaseAuthResult.success(credential);
    } on FirebaseAuthException catch (error) {
      return FirebaseAuthResult.failure(
        code: error.code,
        message: _messageFor(error),
      );
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isInitialized) return;
    await _googleSignIn.initialize(
      clientId: dotenv.env['GOOGLE_CLIENT_ID'],
      serverClientId: dotenv.env['GOOGLE_SERVER_CLIENT_ID'],
    );
    _isInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final credential = await _auth.signInWithPopup(GoogleAuthProvider());
        await _saveProfile(credential.user);
        return credential;
      }

      await _ensureGoogleSignInInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw StateError('ไม่สามารถดึงข้อมูล Token จาก Google ได้');
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      await _saveProfile(userCredential.user);
      return userCredential;
    } catch (error) {
      debugPrint('เกิดข้อผิดพลาดในการล็อกอิน: $error');
      rethrow;
    }
  }

  Future<void> _saveProfile(User? user) async {
    if (user == null) return;
    await FirebaseFirestore.instance.collection('profiles').doc(user.uid).set({
      'id': user.uid,
      'display_name': user.displayName,
      'email': user.email,
      'avatar_url': user.photoURL,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  String _messageFor(FirebaseAuthException error) {
    return switch (error.code) {
      'invalid-email' => 'รูปแบบอีเมลไม่ถูกต้อง',
      'user-disabled' => 'บัญชีนี้ถูกปิดใช้งาน',
      'user-not-found' ||
      'invalid-credential' ||
      'wrong-password' => 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      'email-already-in-use' => 'อีเมลนี้มีบัญชีผู้ใช้แล้ว',
      'weak-password' => 'รหัสผ่านไม่ปลอดภัยเพียงพอ',
      'operation-not-allowed' => 'ยังไม่ได้เปิดใช้งานวิธีเข้าสู่ระบบนี้',
      'network-request-failed' => 'เชื่อมต่อเครือข่ายไม่สำเร็จ',
      _ => error.message ?? 'เข้าสู่ระบบไม่สำเร็จ (${error.code})',
    };
  }
}

class FirebaseAuthResult {
  final UserCredential? credential;
  final String? errorCode;
  final String? errorMessage;

  const FirebaseAuthResult._({
    this.credential,
    this.errorCode,
    this.errorMessage,
  });

  factory FirebaseAuthResult.success(UserCredential credential) =>
      FirebaseAuthResult._(credential: credential);

  factory FirebaseAuthResult.failure({
    required String code,
    required String message,
  }) => FirebaseAuthResult._(errorCode: code, errorMessage: message);

  bool get isSuccess => credential != null;
  User? get user => credential?.user;
}
