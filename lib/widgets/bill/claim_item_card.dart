import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

class ClaimItemCard extends StatelessWidget {
  final String itemName;
  final int itemQuantity;
  final double unitPrice;
  final String claimingUserId;
  final Map<String, int> itemClaims;
  final Set<String> sharedUsers;
  final Map<String, String> userNames;
  final ValueChanged<int> onChangeQuantity;
  final VoidCallback onToggleShared;

  const ClaimItemCard({
    super.key,
    required this.itemName,
    required this.itemQuantity,
    required this.unitPrice,
    required this.claimingUserId,
    required this.itemClaims,
    required this.sharedUsers,
    required this.userNames,
    required this.onChangeQuantity,
    required this.onToggleShared,
  });

  IconData _getDishIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ชา') ||
        lower.contains('น้ำ') ||
        lower.contains('กาแฟ') ||
        lower.contains('เบียร์')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('เนื้อ') ||
        lower.contains('หมู') ||
        lower.contains('วากิว') ||
        lower.contains('แซลมอน')) {
      return Icons.set_meal_rounded;
    }
    if (lower.contains('ผัก') || lower.contains('สลัด')) {
      return Icons.eco_rounded;
    }
    if (lower.contains('ข้าว')) {
      return Icons.rice_bowl_rounded;
    }
    return Icons.ramen_dining_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final myClaimedQty = itemClaims[claimingUserId] ?? 0;
    final totalPersonalQty = itemClaims.values.fold<int>(
      0,
      (total, qty) => total + qty,
    );
    final remainingQty = (itemQuantity - totalPersonalQty).clamp(
      0,
      itemQuantity,
    );
    final otherPersonalQty = totalPersonalQty - myClaimedQty;
    final maxMyQty = (itemQuantity - otherPersonalQty).clamp(0, itemQuantity);
    final sharedPerUser = sharedUsers.isEmpty
        ? 0.0
        : (unitPrice * remainingQty) / sharedUsers.length;
    final isShared = sharedUsers.contains(claimingUserId);
    final isSelected = myClaimedQty > 0 || isShared;
    final isFullyClaimed = remainingQty == 0;

    final isDrink =
        itemName.contains('เบียร์') ||
        itemName.contains('แอลกอฮอล์') ||
        itemName.contains('ไวน์');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.secondary.withValues(alpha: 0.35)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แถวบน: รูปไอคอนอาหาร + ชื่อ + ราคา + Stepper [ - ] qty [ + ]
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.warmCream,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getDishIcon(itemName),
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${AppFormatters.formatCurrency(unitPrice)} / จาน (มีทั้งหมด $itemQuantity จาน)',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // ตัวปรับจำนวน Stepper [ - ] qty [ + ]
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: myClaimedQty > 0
                            ? () => onChangeQuantity(-1)
                            : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.remove_rounded,
                            size: 16,
                            color: myClaimedQty > 0
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          '$myClaimedQty',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: myClaimedQty > 0
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: myClaimedQty < maxMyQty
                            ? () => onChangeQuantity(1)
                            : null,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: myClaimedQty < maxMyQty
                                ? AppColors.primary
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: myClaimedQty < maxMyQty
                                ? Colors.white
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ทิปเครื่องดื่มแอลกอฮอล์
            if (isDrink) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🚫🍺', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 4),
                    Text(
                      'คนไม่ดื่ม ไม่ต้องจ่าย! ปล่อยไว้ที่ 0 ได้เลย',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ปุ่มแชร์กินด้วยกัน
            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onToggleShared,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isShared
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isShared ? AppColors.success : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isShared
                              ? Icons.check_circle_rounded
                              : Icons.people_outline_rounded,
                          size: 14,
                          color: isShared
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isShared
                              ? 'กินด้วยกัน (แชร์จานนี้)'
                              : 'กดกินด้วยกัน (หารเท่า)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isShared
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (isFullyClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '✓ เคลมครบแล้ว ✨',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  )
                else
                  Text(
                    'เหลือ $remainingQty จาน',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),

            // แสดงรายชื่อคนที่จิ้มแล้ว & รายละเอียดแชร์
            if (itemClaims.isNotEmpty || sharedUsers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...itemClaims.entries.map((e) {
                    final name = userNames[e.key] ?? 'เพื่อน';
                    return _buildClaimChip(
                      name,
                      '${e.value} จาน',
                      isShared: false,
                    );
                  }),
                  if (sharedUsers.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        'หารร่วมกัน ${sharedUsers.length} คน (คนละ ${AppFormatters.formatCurrency(sharedPerUser)})',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClaimChip(
    String name,
    String qtyText, {
    required bool isShared,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$name ($qtyText)',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
