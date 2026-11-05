import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme_colors.dart';
import '../../utils/formatters.dart';
import '../common/cached_avatar.dart';

class MemberDishItem {
  final String itemName;
  final int quantity;
  final bool isShared;
  final int totalSharers;
  final double unitPrice;
  final double totalPrice;

  const MemberDishItem({
    required this.itemName,
    required this.quantity,
    this.isShared = false,
    this.totalSharers = 1,
    required this.unitPrice,
    required this.totalPrice,
  });
}

class MemberSummaryEntry {
  final String id;
  final String name;
  final double amount;
  final String status; // 'pending', 'reviewing', 'paid'
  final bool isPaid;
  final bool isReviewing;
  final bool isGuest;
  final bool isOwner;
  final String? subtitle;
  final int itemsCount;
  final String? slipUrl;
  final String? localSlipPath;
  final String? avatarUrl;
  final String? localAvatarPath;
  final List<MemberDishItem> dishes;

  const MemberSummaryEntry({
    required this.id,
    required this.name,
    required this.amount,
    this.status = 'pending',
    bool? isPaid,
    bool? isReviewing,
    this.isGuest = false,
    this.isOwner = false,
    this.subtitle,
    this.itemsCount = 0,
    this.slipUrl,
    this.localSlipPath,
    this.avatarUrl,
    this.localAvatarPath,
    this.dishes = const [],
  }) : isPaid = isPaid ?? (status == 'paid'),
       isReviewing =
           isReviewing ??
           (status == 'reviewing' || status == 'pending_verification');

  MemberSummaryEntry copyWith({
    String? id,
    String? name,
    double? amount,
    String? status,
    bool? isPaid,
    bool? isReviewing,
    bool? isGuest,
    bool? isOwner,
    String? subtitle,
    int? itemsCount,
    String? slipUrl,
    String? localSlipPath,
    String? avatarUrl,
    String? localAvatarPath,
    List<MemberDishItem>? dishes,
  }) {
    return MemberSummaryEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      isPaid: isPaid ?? (status != null ? (status == 'paid') : this.isPaid),
      isReviewing:
          isReviewing ??
          (status != null
              ? (status == 'reviewing' || status == 'pending_verification')
              : this.isReviewing),
      isGuest: isGuest ?? this.isGuest,
      isOwner: isOwner ?? this.isOwner,
      subtitle: subtitle ?? this.subtitle,
      itemsCount: itemsCount ?? this.itemsCount,
      slipUrl: slipUrl ?? this.slipUrl,
      localSlipPath: localSlipPath ?? this.localSlipPath,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      localAvatarPath: localAvatarPath ?? this.localAvatarPath,
      dishes: dishes ?? this.dishes,
    );
  }
}

class MemberSummaryList extends StatelessWidget {
  final List<MemberSummaryEntry> members;
  final String? selectedMemberId;
  final ValueChanged<String>? onMemberTap;
  final ValueChanged<MemberSummaryEntry>? onStatusToggle;
  final bool isCurrentViewerOwner;

  const MemberSummaryList({
    super.key,
    required this.members,
    this.selectedMemberId,
    this.onMemberTap,
    this.onStatusToggle,
    this.isCurrentViewerOwner = true,
  });

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isSelected = member.id == selectedMemberId;
        return Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            selected: isSelected,
            selectedTileColor: AppColors.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: onMemberTap == null ? null : () => onMemberTap!(member.id),
            leading: CircleAvatar(
              backgroundColor: member.isOwner
                  ? const Color(0xFFFEF3C7) // amber 100
                  : (member.isPaid
                        ? Colors.green.shade50
                        : (member.isReviewing
                              ? Colors.blue.shade50
                              : Colors.orange.shade50)),
              child:
                  _isValidImageUrl(member.avatarUrl) ||
                      member.localAvatarPath != null
                  ? ClipOval(
                      child: CachedAvatar(
                        imageUrl: member.avatarUrl,
                        localImagePath: member.localAvatarPath,
                        size: 40,
                        placeholder: Center(
                          child: Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: member.isPaid
                                  ? Colors.green.shade700
                                  : (member.isReviewing
                                        ? Colors.blue.shade700
                                        : Colors.orange.shade800),
                            ),
                          ),
                        ),
                      ),
                    )
                  : (member.isOwner
                        ? const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFD97706),
                            size: 22,
                          )
                        : Text(
                            member.name.isNotEmpty
                                ? member.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: member.isPaid
                                  ? Colors.green.shade700
                                  : (member.isReviewing
                                        ? Colors.blue.shade700
                                        : Colors.orange.shade800),
                            ),
                          )),
            ),
            title: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: member.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (member.isOwner)
                    const TextSpan(
                      text: ' (เจ้าของ)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (member.isGuest)
                    const TextSpan(
                      text: ' (Guest / จ่ายแทน)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (member.itemsCount > 0)
                  Text(
                    '${member.itemsCount} รายการ',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else if (member.subtitle != null)
                  Text(member.subtitle!),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppFormatters.formatCurrency(member.amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: themeColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // 1. เจ้าของรายการ
                    if (member.isOwner)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB), // amber 50
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFCD34D),
                          ), // amber 300
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFB45309),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'เจ้าของ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      )
                    // 2. จ่ายแล้ว
                    else if (member.isPaid)
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: (isCurrentViewerOwner && onStatusToggle != null)
                            ? () => onStatusToggle!(member)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 13,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'จ่ายแล้ว',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    // 3. รอตรวจสอบ (แนบสลิปแล้ว)
                    else if (member.isReviewing)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.hourglass_top_rounded,
                              size: 13,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'รอตรวจสอบ',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    // 4. ยังไม่ชำระ / รอจ่าย
                    else
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: (isCurrentViewerOwner && onStatusToggle != null)
                            ? () => onStatusToggle!(member)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 13,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'รอจ่าย',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: themeColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isValidImageUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}
