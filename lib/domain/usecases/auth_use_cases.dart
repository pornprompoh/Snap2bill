import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

class SignInWithGoogle {
  final AuthRepository repository;

  const SignInWithGoogle(this.repository);

  Future<AuthResponse?> call() => repository.signInWithGoogle();
}

class SignInWithFacebook {
  final AuthRepository repository;

  const SignInWithFacebook(this.repository);

  Future<void> call() => repository.signInWithFacebook();
}

class SignInWithEmail {
  final AuthRepository repository;

  const SignInWithEmail(this.repository);

  Future<AuthResponse> call(String email, String password) =>
      repository.signInWithEmail(email, password);
}

class SignUp {
  final AuthRepository repository;

  const SignUp(this.repository);

  Future<AuthResponse> call(String email, String password) =>
      repository.signUp(email, password);
}
