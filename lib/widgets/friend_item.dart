import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

class FriendItem extends StatelessWidget {
  final String name;
  final bool isHost;
  final String? amountText;
  final String? subtitleText;
  final Widget? trailing;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;

  const FriendItem({
    super.key,
    required this.name,
    this.isHost = false,
    this.amountText,
    this.subtitleText,
    this.trailing,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: 4.0,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onSelectionChanged == null
            ? null
            : () => onSelectionChanged!(!isSelected),
        leading: CircleAvatar(
          backgroundColor: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : isHost
              ? Colors.amber
              : Colors.blue.shade100,
          child: Icon(
            isHost ? Icons.star : Icons.person,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : isHost
                ? Colors.white
                : Colors.blue,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: amountText != null
            ? Text(
                amountText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            : Text(subtitleText ?? (isHost ? 'หัวหน้าห้อง' : 'เข้าร่วมแล้ว')),
        trailing:
            trailing ??
            (onSelectionChanged == null
                ? null
                : Checkbox(value: isSelected, onChanged: onSelectionChanged)),
      ),
    );
  }
}

class FriendAvatar extends StatelessWidget {
  final String name;
  final bool isHost;
  final bool isCurrentUser;
  final bool isInvited;

  const FriendAvatar({
    super.key,
    required this.name,
    this.isHost = false,
    this.isCurrentUser = false,
    this.isInvited = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Tooltip(
        message: [
          name,
          if (isHost) 'หัวหน้าห้อง',
          if (isInvited) 'เพิ่มโดยหัวหน้าห้อง',
        ].join(' • '),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: isCurrentUser
                      ? AppColors.primary
                      : isHost
                      ? AppColors.accent
                      : AppColors.secondary,
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: isHost || isCurrentUser
                          ? AppColors.surface
                          : AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isHost)
                  Positioned(
                    right: -2,
                    top: -3,
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isCurrentUser ? 'คุณ' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: isCurrentUser ? FontWeight.w700 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts
        .take(2)
        .map((part) => String.fromCharCode(part.runes.first))
        .join();
  }
}
