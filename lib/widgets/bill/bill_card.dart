import 'package:flutter/material.dart';
import 'package:snap2bill/theme/app_colors.dart';
import 'package:snap2bill/utils/formatters.dart';

class BillCard extends StatelessWidget {
  final String shopName;
  final double totalAmount;
  final String dateText;
  final String status;
  final VoidCallback? onTap;
  final VoidCallback? onPoke;

  const BillCard({
    super.key,
    required this.shopName,
    required this.totalAmount,
    this.dateText = '',
    this.status = 'pending',
    this.onTap,
    this.onPoke,
  });

  bool get _isSettled {
    return const {
      'paid',
      'settled',
      'cleared',
      'completed',
    }.contains(status.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBackground = isDark
        ? AppColors.darkCardBackground
        : AppColors.cardBackground;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final mutedColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textMuted;
    final statusColor = _isSettled ? AppColors.success : AppColors.warning;
    final statusLabel = _isSettled ? 'เคลียร์แล้ว' : 'รอเพื่อนโอน';
    final statusBackground = isDark
        ? AppColors.darkSurface
        : AppColors.secondary.withValues(alpha: 0.1);

    return Card(
      color: cardBackground,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.secondary.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          shopName,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (dateText.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            dateText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: textSecondary),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppFormatters.formatCurrency(totalAmount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Icon(Icons.chevron_right, color: mutedColor, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
              if (onPoke != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: isDark
                          ? AppColors.warning
                          : Colors.orange.shade900,
                      side: BorderSide(
                        color: isDark
                            ? AppColors.warning.withValues(alpha: 0.6)
                            : Colors.orange.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: onPoke,
                    icon: const Icon(
                      Icons.notifications_active_outlined,
                      size: 15,
                    ),
                    label: const Text(
                      'สะกิดเตือนเพื่อน 🔔',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
