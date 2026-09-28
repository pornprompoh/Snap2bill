import 'package:flutter/material.dart';
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
