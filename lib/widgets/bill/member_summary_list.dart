import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

class MemberSummaryEntry {
  final String id;
  final String name;
  final double amount;
  final bool isPaid;
  final bool isGuest;
  final String? subtitle;

  const MemberSummaryEntry({
    required this.id,
    required this.name,
    required this.amount,
    this.isPaid = false,
    this.isGuest = false,
    this.subtitle,
  });

  MemberSummaryEntry copyWith({
    String? id,
    String? name,
    double? amount,
    bool? isPaid,
    bool? isGuest,
    String? subtitle,
  }) {
    return MemberSummaryEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      isGuest: isGuest ?? this.isGuest,
      subtitle: subtitle ?? this.subtitle,
    );
  }
}

class MemberSummaryList extends StatelessWidget {
  final List<MemberSummaryEntry> members;
  final String? selectedMemberId;
  final ValueChanged<String>? onMemberTap;
  final ValueChanged<MemberSummaryEntry>? onStatusToggle;

  const MemberSummaryList({
    super.key,
    required this.members,
    this.selectedMemberId,
    this.onMemberTap,
    this.onStatusToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isSelected = member.id == selectedMemberId;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            backgroundColor: member.isPaid
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: Icon(
              member.isPaid
                  ? Icons.check_circle_outline
                  : Icons.pending_outlined,
              color: member.isPaid
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
            ),
          ),
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: member.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (member.isGuest)
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
          subtitle: member.subtitle == null ? null : Text(member.subtitle!),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppFormatters.formatCurrency(member.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onStatusToggle == null
                    ? null
                    : () => onStatusToggle!(member),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: member.isPaid
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: member.isPaid
                          ? Colors.green.shade300
                          : Colors.orange.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        member.isPaid ? Icons.check_circle : Icons.schedule,
                        size: 13,
                        color: member.isPaid
                            ? Colors.green.shade700
                            : Colors.orange.shade800,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.isPaid ? 'จ่ายแล้ว' : 'รอจ่าย',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: member.isPaid
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                      ),
                      if (onStatusToggle != null) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.swap_horiz,
                          size: 12,
                          color: member.isPaid
                              ? Colors.green.shade700
                              : Colors.orange.shade800,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
