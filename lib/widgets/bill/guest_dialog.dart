import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/contact_model.dart';
import '../../providers/contact_provider.dart';

class GuestDialog extends StatefulWidget {
  final TextEditingController controller;

  const GuestDialog({super.key, required this.controller});

  @override
  State<GuestDialog> createState() => _GuestDialogState();
}

class _GuestDialogState extends State<GuestDialog> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<ContactProvider>().loadContacts());
  }

  void _selectContact(ContactModel contact) {
    Navigator.pop(context, contact.name);
  }

  void _returnManualEntry() {
    final name = widget.controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();

    return AlertDialog(
      title: const Text('เพิ่มเพื่อนที่ไม่มีแอป'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'ชื่อเพื่อน',
                hintText: 'เช่น มิน',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _returnManualEntry(),
            ),
            const SizedBox(height: 20),
            Text(
              'หรือเลือกจากรายชื่อที่บันทึกไว้',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (contactProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (contactProvider.error != null)
              Text(
                contactProvider.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (contactProvider.contacts.isEmpty)
              const Text('ยังไม่มีรายชื่อที่บันทึกไว้')
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final contact in contactProvider.contacts)
                        ActionChip(
                          avatar: const Icon(Icons.person_outline, size: 18),
                          label: Text(contact.name),
                          onPressed: () => _selectContact(contact),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed:
              widget.controller.text.trim().isEmpty ? null : _returnManualEntry,
          child: const Text('เพิ่มชื่อที่พิมพ์'),
        ),
      ],
    );
  }
}
