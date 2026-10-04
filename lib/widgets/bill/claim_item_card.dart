import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.07)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : itemClaims.isNotEmpty || sharedUsers.isNotEmpty
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: isSelected
                              ? AppColors.primaryDark
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('ทั้งหมด $itemQuantity ชิ้น',
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'ลดจำนวน $itemName',
                            onPressed: myClaimedQty > 0
                                ? () => onChangeQuantity(-1)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 36,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          SizedBox(
                            width: 26,
                            child: Text(
                              '$myClaimedQty',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'เพิ่มจำนวน $itemName',
                            onPressed: myClaimedQty < maxMyQty
                                ? () => onChangeQuantity(1)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 36,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: onToggleShared,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          foregroundColor: isShared
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        child: Text(
                          isShared ? 'แชร์แล้ว' : 'กินด้วยกัน',
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    AppFormatters.formatCurrency(unitPrice),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (remainingQty > 0 ||
                itemClaims.isNotEmpty ||
                sharedUsers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                sharedUsers.isEmpty
                    ? 'เหลืออีก $remainingQty ชิ้น'
                    : remainingQty > 0
                    ? 'แชร์ $remainingQty ชิ้น หาร ${sharedUsers.length} คน: '
                          'คนละ ฿${sharedPerUser.toStringAsFixed(2)}'
                    : 'ไม่มีชิ้นเหลือสำหรับหารร่วมกัน',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...itemClaims.keys.map(
                    (userId) => _ClaimTag(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      label: '${userNames[userId] ?? 'เพื่อน'} × '
                          '${itemClaims[userId]}',
                    ),
                  ),
                  ...sharedUsers.map(
                    (userId) => _ClaimTag(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      label: '${userNames[userId] ?? 'เพื่อน'} แชร์',
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
}

class _ClaimTag extends StatelessWidget {
  final Color color;
  final String label;

  const _ClaimTag({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
