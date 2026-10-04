import 'package:flutter/material.dart';

class GuestDialog extends StatelessWidget {
  final TextEditingController controller;

  const GuestDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เพิ่มเพื่อนที่ไม่มีแอป'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'ชื่อเพื่อน',
          hintText: 'เช่น มิน',
        ),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('เพิ่ม'),
        ),
      ],
    );
  }
}
