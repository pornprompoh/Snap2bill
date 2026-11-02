import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  Future<AuthResponse?> signInWithGoogle();

  Future<void> signInWithFacebook();

  Future<AuthResponse> signInWithEmail(String email, String password);

  Future<AuthResponse> signUp(String email, String password);
}
