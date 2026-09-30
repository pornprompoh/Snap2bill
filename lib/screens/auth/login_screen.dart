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
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((data) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')));
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
      // หมายเหตุ: บนเว็บ โค้ดจะหยุดทำแค่นี้ เพราะมัน Redirect โยนไปหน้า Google แล้ว
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ล็อกอินล้มเหลว: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minHeight = (constraints.maxHeight - 40)
                .clamp(0.0, constraints.maxHeight)
                .toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryDark.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Snap2Bill',
                                  style: AppTextStyles.headline.copyWith(
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'สแกนบิล แบ่งรายการ และสรุปยอดกับเพื่อน',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleGoogleSignIn,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.surface,
                                      foregroundColor: AppColors.textPrimary,
                                      disabledBackgroundColor:
                                          AppColors.surface,
                                      disabledForegroundColor:
                                          AppColors.textSecondary,
                                      elevation: 0,
                                      overlayColor: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      splashFactory: InkRipple.splashFactory,
                                      side: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      key: ValueKey('loading'),
                                                      width: 22,
                                                      height: 22,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: AppColors
                                                                .primary,
                                                            strokeWidth: 2.4,
                                                            strokeCap:
                                                                StrokeCap.round,
                                                          ),
                                                    )
                                                  : const Center(
                                                      key: ValueKey('google'),
                                                      child: Text(
                                                        'G',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF4285F4,
                                                          ),
                                                          fontSize: 23,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 38,
                                          ),
                                          child: Text(
                                            _isLoading
                                                ? 'กำลังเข้าสู่ระบบ...'
                                                : 'เข้าสู่ระบบด้วย Google',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isLoading) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'กำลังเชื่อมต่อบัญชี Google อย่างปลอดภัย',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: Text(
                            'เมื่อเข้าสู่ระบบ คุณยอมรับข้อกำหนดการใช้งานและนโยบายความเป็นส่วนตัวของ Snap2Bill',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
