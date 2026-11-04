import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../services/onboarding/onboarding_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/mascot_assets.dart';

class OnboardingScreen extends StatefulWidget {
  final String destinationRoute;
  final OnboardingService onboardingService;

  const OnboardingScreen({
    super.key,
    required this.destinationRoute,
    this.onboardingService = const OnboardingService(),
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = [
    _OnboardingStep(
      title: 'เริ่มจากสแกนใบเสร็จ',
      description:
          'ถ่ายรูปหรือเลือกรูปใบเสร็จ แล้ว Snap2Bill จะช่วยอ่านรายการอาหารและยอดเงินให้',
      mascot: MascotAssets.happyReceipt,
      icon: Icons.document_scanner_outlined,
      label: 'สแกนบิล',
    ),
    _OnboardingStep(
      title: 'ชวนเพื่อนเข้ามาหารบิล',
      description:
          'สร้างห้องแล้วแชร์รหัสหรือ QR ให้เพื่อนเข้าร่วม เลือกได้ว่าใครจะหารบิลด้วยกัน',
      mascot: MascotAssets.phoneHappy,
      icon: Icons.group_add_outlined,
      label: 'ชวนเพื่อน',
    ),
    _OnboardingStep(
      title: 'เลือกเมนูที่แต่ละคนกิน',
      description:
          'สมาชิกเลือกอาหารของตัวเอง ระบบจะคำนวณยอดแยกให้ และต้องเลือกให้ครบก่อนสรุปบิล',
      mascot: MascotAssets.thinking,
      icon: Icons.restaurant_menu_outlined,
      label: 'เลือกเมนู',
    ),
    _OnboardingStep(
      title: 'ตรวจยอดและชำระเงิน',
      description:
          'ดูยอดของแต่ละคน สแกน PromptPay QR และติดตามสถานะการชำระเงินได้ในบิลเดียว',
      mascot: MascotAssets.cheering,
      icon: Icons.qr_code_2_rounded,
      label: 'สรุปและจ่าย',
    ),
  ];

  int _currentStep = 0;
  bool _isFinishing = false;

  Future<void> _finish() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      await widget.onboardingService.markCompleted();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(widget.destinationRoute, (_) => false);
    } catch (error) {
      debugPrint('บันทึกการตั้งค่าเริ่มต้นไม่สำเร็จ: $error');
      if (!mounted) return;
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'บันทึกการตั้งค่าไม่สำเร็จ กรุณาตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _next() {
    if (_currentStep == _steps.length - 1) {
      _finish();
      return;
    }
    setState(() => _currentStep++);
  }

  void _previous() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.pink,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Snap2Bill',
                        style: TextStyle(
                          color: isDark ? Colors.white : AppColors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (kIsWeb)
                        TextButton(
                          onPressed: _isFinishing ? null : _finish,
                          child: const Text(
                            'ข้าม',
                            style: TextStyle(color: AppColors.pink),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Image.asset(
                            step.mascot,
                            width: screenSize.width < 380 ? 150 : 190,
                            height: screenSize.height * 0.27,
                            fit: BoxFit.contain,
                            semanticLabel: 'Snap2Bill Bunny',
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  MascotAssets.fallback,
                                  width: 170,
                                  height: screenSize.height * 0.27,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Snap2Bill Bunny',
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightPink,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(step.icon, size: 18, color: AppColors.pink),
                              const SizedBox(width: 6),
                              Text(
                                step.label,
                                style: const TextStyle(
                                  color: AppColors.pink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.gray,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentStep ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentStep
                              ? AppColors.pink
                              : AppColors.pink.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: _isFinishing ? null : _previous,
                          child: const Text(
                            'ย้อนกลับ',
                            style: TextStyle(color: AppColors.gray),
                          ),
                        )
                      else
                        const SizedBox(width: 76),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _isFinishing ? null : _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.pink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 13,
                          ),
                        ),
                        icon: _isFinishing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _currentStep == _steps.length - 1
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                        label: Text(
                          _currentStep == _steps.length - 1
                              ? 'เริ่มใช้งาน'
                              : 'ถัดไป',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String description;
  final String mascot;
  final IconData icon;
  final String label;

  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.mascot,
    required this.icon,
    required this.label,
  });
}
