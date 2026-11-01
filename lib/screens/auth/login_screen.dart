import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/supabase_auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isNavigatingHome = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Supabase.instance.client.auth.currentSession != null && mounted) {
        _navigateToHome();
      }
    });
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
          if (data.event == AuthChangeEvent.signedIn && data.session != null) {
            _navigateToHome();
          }
        });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted || _isNavigatingHome) return;
    _isNavigatingHome = true;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (_isLogin) {
        await auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final response = await auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (response.session == null) {
          _showMessage('สมัครสมาชิกสำเร็จ กรุณาตรวจสอบอีเมลเพื่อยืนยันบัญชี');
        } else {
          _navigateToHome();
        }
      }
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('ไม่สามารถดำเนินการได้ กรุณาลองใหม่อีกครั้ง');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    await _runSocialAuth(
      () => SupabaseAuthService().signInWithGoogle(),
      'เข้าสู่ระบบด้วย Google ไม่สำเร็จ',
    );
  }

  Future<void> _handleFacebookSignIn() async {
    await _runSocialAuth(() {
      return Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: Uri.base.origin,
      );
    }, 'เข้าสู่ระบบด้วย Facebook ไม่สำเร็จ');
  }

  Future<void> _runSocialAuth(
    Future<dynamic> Function() action,
    String errorMessage,
  ) async {
    setState(() => _isLoading = true);
    try {
      final response = await action();
      if (!mounted) return;
      if (response is AuthResponse && response.user != null) {
        _navigateToHome();
      }
    } catch (error) {
      if (mounted) _showMessage('$errorMessage: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showMessage('กรุณากรอกอีเมลก่อนขอรีเซ็ตรหัสผ่าน');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _showMessage('ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลแล้ว');
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'กรุณากรอกอีเมล';
    if (!value.contains('@')) return 'กรุณากรอกอีเมลให้ถูกต้อง';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (value.length < 6) return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLogo(),
                    const SizedBox(height: 18),
                    Text(
                      'Snap2Bill',
                      style: AppTextStyles.headline.copyWith(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin
                          ? 'ยินดีต้อนรับกลับมา'
                          : 'สร้างบัญชีเพื่อเริ่มต้นใช้งาน',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                      decoration: _inputDecoration(
                        hint: 'อีเมล',
                        icon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      onFieldSubmitted: (_) => _submitEmailAuth(),
                      decoration: _inputDecoration(
                        hint: 'รหัสผ่าน',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          tooltip: _isPasswordVisible
                              ? 'ซ่อนรหัสผ่าน'
                              : 'แสดงรหัสผ่าน',
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleForgotPassword,
                          child: Text(
                            'ลืมรหัสผ่าน?',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitEmailAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.55),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _socialButton(
                            label: 'Google',
                            icon: const Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : _handleGoogleSignIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _socialButton(
                            label: 'Facebook',
                            icon: const Text(
                              'f',
                              style: TextStyle(
                                color: Color(0xFF1877F2),
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : _handleFacebookSignIn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset();
                            }),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.caption,
                          children: [
                            TextSpan(
                              text: _isLogin
                                  ? 'ยังไม่มีบัญชีใช่ไหม? '
                                  : 'มีบัญชีอยู่แล้ว? ',
                            ),
                            TextSpan(
                              text: _isLogin
                                  ? 'สมัครสมาชิก'
                                  : 'เข้าสู่ระบบ',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Text(
                      'เมื่อดำเนินการต่อ คุณยอมรับข้อกำหนดการใช้งาน\n'
                      'และนโยบายความเป็นส่วนตัวของ Snap2Bill',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 86,
        height: 86,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Image.asset(
            'assets/logo_snap2bill.png',
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.receipt_long_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E2E2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'หรือ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E2E2))),
      ],
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        minimumSize: const Size(0, 48),
        side: const BorderSide(color: Color(0xFFE1E1E1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
