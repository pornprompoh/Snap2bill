import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FriendItem extends StatelessWidget {
  final String name;
  final bool isHost;
  final String? amountText;
  final Widget? trailing;

  const FriendItem({
    super.key,
    required this.name,
    this.isHost = false,
    this.amountText,
    this.trailing,
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
        leading: CircleAvatar(
          backgroundColor: isHost ? Colors.amber : Colors.blue.shade100,
          child: Icon(
            isHost ? Icons.star : Icons.person, 
            color: isHost ? Colors.white : Colors.blue,
          ),
        ),
        title: Text(
          name, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: amountText != null 
            ? Text(
                amountText!, 
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
              )
            : Text(isHost ? 'หัวหน้าห้อง' : 'เข้าร่วมแล้ว'),
        trailing: trailing,
      ),
    );
  }
}