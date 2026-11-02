import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/mascot_assets.dart';

enum MascotState { empty, offline, error, success, scan, thinking }

class MascotStateView extends StatelessWidget {
  final MascotState state;
  final String message;
  final String? detail;
  final VoidCallback? onRetry;
  final double size;

  const MascotStateView({
    super.key,
    required this.state,
    required this.message,
    this.detail,
    this.onRetry,
    this.size = 132,
  });

  String get _asset {
    switch (state) {
      case MascotState.empty:
        return MascotAssets.waving;
      case MascotState.offline:
        return MascotAssets.phoneHappy;
      case MascotState.error:
        return MascotAssets.worried;
      case MascotState.success:
        return MascotAssets.cheering;
      case MascotState.scan:
        return MascotAssets.happyReceipt;
      case MascotState.thinking:
        return MascotAssets.thinking;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          _asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
          semanticLabel: 'Snap2Bill Bunny',
          errorBuilder: (context, error, stackTrace) => Image.asset(
            MascotAssets.fallback,
            width: size,
            height: size,
            fit: BoxFit.contain,
            semanticLabel: 'Snap2Bill Bunny',
          ),
        ),
        if (message.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(
            detail!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('ลองใหม่')),
        ],
      ],
    );
  }
}
