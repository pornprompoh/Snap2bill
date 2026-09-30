import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class BillCard extends StatelessWidget {
  final String shopName;
  final double totalAmount;
  final String dateText;
  final String status;
  final VoidCallback? onTap;

  const BillCard({
    super.key,
    required this.shopName,
    required this.totalAmount,
    this.dateText = '',
    this.status = 'pending',
    this.onTap,
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
    final statusColor = _isSettled ? AppColors.success : AppColors.warning;
    final statusLabel = _isSettled ? 'เคลียร์แล้ว' : 'รอเพื่อนโอน';

    return Card(
      color: AppColors.cardBackground,
      elevation: 1,
      shadowColor: AppColors.primaryDark.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (dateText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        dateText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppFormatters.formatCurrency(totalAmount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
