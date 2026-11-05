import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/models/contact_model.dart';
import 'package:snap2bill/providers/contact_provider.dart';
import 'package:snap2bill/widgets/bill/guest_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://guest-dialog-test.supabase.co',
        publishableKey: 'guest-dialog-test-key',
      );
    } catch (_) {}
  });

  testWidgets('selecting a saved contact returns its name', (tester) async {
    final provider = _ContactsProvider();
    final controller = TextEditingController();
    late Future<String?> result;

    await tester.pumpWidget(
      ChangeNotifierProvider<ContactProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  result = showDialog<String>(
                    context: context,
                    builder: (_) => GuestDialog(controller: controller),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved friend'));
    await tester.pumpAndSettle();

    expect(await result, 'Saved friend');
    controller.dispose();
    provider.dispose();
  });
}

class _ContactsProvider extends ContactProvider {
  @override
  List<ContactModel> get contacts => [
    ContactModel(
      id: 'contact-1',
      userId: 'user-1',
      name: 'Saved friend',
      createdAt: DateTime.utc(2026),
    ),
  ];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadContacts() async {}
}
