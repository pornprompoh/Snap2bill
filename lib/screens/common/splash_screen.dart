import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/onboarding/onboarding_service.dart';
import '../../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.65, curve: Curves.easeOut),
    );
    _controller.forward();
    _openInitialRoute();
  }

  Future<void> _openInitialRoute() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final destinationRoute =
        Supabase.instance.client.auth.currentSession == null
        ? AppRoutes.login
        : AppRoutes.home;
    final onboardingCompleted = await OnboardingService().hasCompleted();
    if (!mounted) return;

    if (!onboardingCompleted) {
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.onboarding, arguments: destinationRoute);
      return;
    }
    Navigator.of(context).pushReplacementNamed(destinationRoute);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: 0.82 + (_scale.value * 0.18),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/bunny_mascot.png',
                width: 190,
                height: 190,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              const Text(
                'Snap2Bill',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
