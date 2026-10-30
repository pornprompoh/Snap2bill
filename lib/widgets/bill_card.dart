import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class BillCard extends StatelessWidget {
  final String shopName;
  final double totalAmount;
  final String dateText;
  final String status;
  final int memberCount;
  final int unpaidCount;
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
    this.memberCount = 4,
    this.unpaidCount = 0,
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
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSec = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final surfaceBg = isDark ? AppColors.darkSurface : AppColors.surface;

    final statusColor = _isSettled ? AppColors.success : AppColors.warning;
    final statusBgColor = _isSettled
        ? AppColors.success.withValues(alpha: 0.12)
        : (isDark ? AppColors.darkSurface : AppColors.secondary);
    final statusLabel = _isSettled ? 'เคลียร์แล้ว' : 'รอชำระเงิน';

    final safeCollected =
        collectedAmount ?? (_isSettled ? totalAmount : totalAmount * 0.7);
    final progress = totalAmount > 0
        ? (safeCollected / totalAmount).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // หัวการ์ด: ไอคอนร้าน + ชื่อร้าน + สถานะ + ยอดเงิน
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.secondary,
                            AppColors.secondary.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  shopName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: textPrim,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBgColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isSettled
                                          ? Icons.check_circle_rounded
                                          : Icons.schedule_rounded,
                                      size: 11,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (dateText.isNotEmpty) ...[
                                Text(
                                  dateText,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: textSec, fontSize: 12),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '•',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                '$memberCount คน',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: textSec, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                AppFormatters.formatCurrency(totalAmount),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: textPrim,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // กรณีบิลที่ยังไม่เสร็จ (Active / Pending): แถบความคืบหน้า + อวาตาร์คนที่ยังไม่จ่าย
                if (!_isSettled) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderCol),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // วงกลมรูปโปรไฟล์ซ้อนกัน
                            SizedBox(
                              width: 64,
                              height: 24,
                              child: Stack(
                                children: [
                                  _buildAvatar(0, Colors.orange.shade200, 'A'),
                                  Positioned(
                                    left: 16,
                                    child: _buildAvatar(
                                      1,
                                      Colors.pink.shade200,
                                      'B',
                                    ),
                                  ),
                                  Positioned(
                                    left: 32,
                                    child: _buildAvatar(
                                      2,
                                      Colors.teal.shade200,
                                      'C',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkCardBackground
                                      : AppColors.secondary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  unpaidMemberName != null
                                      ? '⚡ รออีก 1 คน ($unpaidMemberName)'
                                      : '⚡ รอเพื่อนจ่าย ${unpaidCount > 0 ? unpaidCount : 1} คน',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: borderCol,
                            color: AppColors.primary,
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'เก็บได้แล้ว ${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(fontSize: 10.5, color: textSec),
                            ),
                            Text(
                              '${AppFormatters.formatCurrency(safeCollected)} / ${AppFormatters.formatCurrency(totalAmount)}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: textPrim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onRemind != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onRemind,
                            icon: const Icon(
                              Icons.notifications_active_rounded,
                              size: 14,
                            ),
                            label: const Text(
                              'สะกิดเตือนเพื่อน',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onTap,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrim,
                            side: BorderSide(color: borderCol),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ดูบิล',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 11),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else ...[
                  // กรณีบิลสำเร็จสมบูรณ์ (Settled): แสดงป้ายเก็บเงินครบ และประเภทการหาร
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check,
                              size: 12,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'เก็บเงินครบทุกคนแล้ว',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          splitType ?? 'หารตามสัดส่วนจริง',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                          ),
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

  Widget _buildAvatar(int index, Color color, String initial) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
