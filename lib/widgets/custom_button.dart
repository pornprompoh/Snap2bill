import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          overlayColor: (backgroundColor ?? AppColors.primary).withValues(
            alpha: 0.16,
          ),
          splashFactory: InkRipple.splashFactory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          elevation: 0,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                ),
              )
            : Text(
                text,
                style: AppTextStyles.body.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
