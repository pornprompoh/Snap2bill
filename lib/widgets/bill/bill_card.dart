import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

class BillCard extends StatelessWidget {
  final String shopName;
  final double totalAmount;
  final String dateText;
  final String status;
  final bool isPendingSync;
  final int memberCount;
  final int unpaidCount;
  final int? totalPayingCount;
  final int? paidCount;
  final double? averagePerPerson;
  final bool isEqualSplit;
  final String? unpaidMemberName;
  final double? collectedAmount;
  final String? splitType;
  final VoidCallback? onTap;
  final VoidCallback? onRemind;

  const BillCard({
    super.key,
    required this.shopName,
    required this.totalAmount,
    this.dateText = '',
    this.status = 'pending',
    this.isPendingSync = false,
    this.memberCount = 4,
    this.unpaidCount = 0,
    this.totalPayingCount,
    this.paidCount,
    this.averagePerPerson,
    this.isEqualSplit = false,
    this.unpaidMemberName,
    this.collectedAmount,
    this.splitType,
    this.onTap,
    this.onRemind,
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
    final cardBg = isDark
        ? AppColors.darkCardBackground
        : AppColors.cardBackground;
    final borderCol = isDark ? AppColors.darkBorder : const Color(0xFFE5E5E5);
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.black;
    final textSec = isDark ? AppColors.darkTextSecondary : AppColors.gray;

    // Status colors conforming strictly to Design System
    final statusBgColor = _isSettled
        ? AppColors.lightGreen
        : AppColors.paleYellow;
    final statusTextColor = _isSettled
        ? AppColors.tealGreen
        : AppColors.primaryOrange;
    final statusLabel = _isSettled ? 'ชำระเสร็จสิ้น' : 'รอเพื่อนโอน';

    // Calculate real paying members count (excluding owner)
    final effectiveTotalPaying =
        totalPayingCount ?? (memberCount > 1 ? memberCount - 1 : 1);
    final effectivePaid =
        paidCount ??
        (effectiveTotalPaying - unpaidCount).clamp(0, effectiveTotalPaying);
    final progress = effectiveTotalPaying > 0
        ? (effectivePaid / effectiveTotalPaying).clamp(0.0, 1.0)
        : 0.0;
    final int percentage = (progress * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Receipt Icon in Light Pink Container
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF322329)
                            : AppColors.lightPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        color: isDark ? AppColors.pink : AppColors.black,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Shop Name, Date, Status Chip
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shopName,
                            style: TextStyle(
                              color: textPrim,
                              fontWeight: FontWeight.w700,
                              fontSize: 16.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          if (dateText.isNotEmpty)
                            Text(
                              dateText,
                              style: TextStyle(color: textSec, fontSize: 13.5),
                            ),
                          const SizedBox(height: 4),
                          // Status Badge matching Reference Image
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isPendingSync) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'รอบันทึกเมื่อออนไลน์',
                              style: TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Amount & Chevron & Average per person
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              totalAmount > 0
                                  ? AppFormatters.formatCurrency(totalAmount)
                                  : 'ยังไม่มีข้อมูลยอดบิล',
                              style: TextStyle(
                                color: totalAmount > 0 ? textPrim : textSec,
                                fontWeight: FontWeight.w800,
                                fontSize: totalAmount > 0 ? 17.5 : 12.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: textSec,
                              size: 20,
                            ),
                          ],
                        ),
                        if (totalAmount > 0 &&
                            isEqualSplit &&
                            averagePerPerson != null &&
                            averagePerPerson! > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'ตกคนละ ${AppFormatters.formatCurrency(averagePerPerson!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSec,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Active progress bar if bill has active collection
                if (!_isSettled) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFEEEEEE),
                      color: AppColors.primaryOrange,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เก็บเงินแล้ว $percentage%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSec,
                        ),
                      ),
                      Text(
                        'จ่ายแล้ว $effectivePaid/$effectiveTotalPaying คน',
                        style: TextStyle(fontSize: 12, color: textSec),
                      ),
                      Text(
                        'รออีก $unpaidCount คน',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                ] else if (_isSettled && effectiveTotalPaying > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: isDark
                          ? AppColors.darkBorder
                          : const Color(0xFFEEEEEE),
                      color: AppColors.tealGreen,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'เก็บเงินแล้ว 100%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSec,
                        ),
                      ),
                      Text(
                        'จ่ายครบแล้ว $effectiveTotalPaying/$effectiveTotalPaying คน',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.tealGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
