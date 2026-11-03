import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme_colors.dart';

class BouncingMascotLoader extends StatefulWidget {
  final String message;
  final double size;

  const BouncingMascotLoader({
    super.key,
    this.message = 'กำลังโหลด...',
    this.size = 160,
  });

  @override
  State<BouncingMascotLoader> createState() => _BouncingMascotLoaderState();
}

class _BouncingMascotLoaderState extends State<BouncingMascotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shadowWidth = widget.size * 0.48;
    final colors = context.appColors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final phase = _controller.value * math.pi * 2;
        final lift = math.sin(phase) * widget.size * 0.045;
        final tilt = math.sin(phase) * 0.035;
        final shadowScale = 0.86 + ((math.sin(phase) + 1) * 0.07);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, -lift),
              child: Transform.rotate(angle: tilt, child: child),
            ),
            const SizedBox(height: 4),
            Transform.scale(
              scaleX: shadowScale,
              child: Container(
                width: shadowWidth,
                height: widget.size * 0.055,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(widget.size),
                ),
              ),
            ),
            if (widget.message.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
      child: Image.asset(
        'assets/images/bunny_mascot.png',
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      ),
    );
  }
}
