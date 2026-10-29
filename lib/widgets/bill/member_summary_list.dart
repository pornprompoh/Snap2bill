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
}

class MemberSummaryList extends StatelessWidget {
  final List<MemberSummaryEntry> members;
  final String? selectedMemberId;
  final ValueChanged<String>? onMemberTap;

  const MemberSummaryList({
    super.key,
    required this.members,
    this.selectedMemberId,
    this.onMemberTap,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
                TextSpan(text: member.name),
                if (member.isGuest)
                  const TextSpan(
                    text: ' (Guest / จ่ายแทน)',
                    style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                  ),
              ],
            ),
          ),
          subtitle: member.subtitle == null ? null : Text(member.subtitle!),
          trailing: Text(AppFormatters.formatCurrency(member.amount)),
        );
      },
    );
  }
}
