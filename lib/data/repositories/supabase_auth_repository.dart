import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../services/auth/supabase_auth_service.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseAuthService _service;
  final SupabaseClient _client;

  SupabaseAuthRepository({
    SupabaseAuthService? service,
    SupabaseClient? client,
  })  : _service = service ?? SupabaseAuthService(),
        _client = client ?? Supabase.instance.client;

  @override
  Future<AuthResponse?> signInWithGoogle() => _service.signInWithGoogle();

  @override
  Future<void> signInWithFacebook() => _service.signInWithFacebook();

  @override
  Future<AuthResponse> signInWithEmail(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<AuthResponse> signUp(String email, String password) {
    return _client.auth.signUp(email: email, password: password);
  }
}
