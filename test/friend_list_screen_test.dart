import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/models/contact_model.dart';
import 'package:snap2bill/providers/contact_provider.dart';
import 'package:snap2bill/screens/friends/friend_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://friend-list-test.supabase.co',
        publishableKey: 'friend-list-test-key',
      );
    } catch (_) {}
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('shows saved contact empty state when signed out', (
    tester,
  ) async {
    final provider = ContactProvider(client: Supabase.instance.client);
    await tester.pumpWidget(
      ChangeNotifierProvider<ContactProvider>.value(
        value: provider,
        child: const MaterialApp(home: FriendListScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('เพื่อนที่เคยหารบิล'), findsOneWidget);
    expect(
      find.text('กรุณาล็อกอินเพื่อดูรายชื่อเพื่อนที่บันทึกไว้'),
      findsOneWidget,
    );
  });

  testWidgets('prompts for login in past-participant selection mode', (
    tester,
  ) async {
    final provider = ContactProvider(client: Supabase.instance.client);
    await tester.pumpWidget(
      ChangeNotifierProvider<ContactProvider>.value(
        value: provider,
        child: const MaterialApp(home: FriendListScreen(selectionMode: true)),
      ),
    );
    await tester.pump();

    expect(find.text('เลือกเพื่อนจากบิลก่อนหน้า'), findsOneWidget);
    expect(find.text('กรุณาล็อกอิน'), findsOneWidget);
  });

  testWidgets('renders saved contact notes and confirms cancellation', (
    tester,
  ) async {
    final provider = _FakeContactProvider([
      ContactModel(
        id: 'contact-1',
        userId: 'user-1',
        name: 'Mina',
        note: 'Met at dinner',
        createdAt: DateTime.utc(2026, 11, 1),
      ),
      ContactModel(
        id: 'contact-2',
        userId: 'user-1',
        name: 'Niran',
        createdAt: DateTime.utc(2026, 11, 2),
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<ContactProvider>.value(
        value: provider,
        child: const MaterialApp(home: FriendListScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Met at dinner'), findsOneWidget);
    expect(find.text('ไม่มีหมายเหตุ'), findsOneWidget);
    await tester.drag(find.text('Mina'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('ลบรายชื่อ'), findsOneWidget);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
    expect(provider.contacts, hasLength(2));
  });

  testWidgets('shows failure feedback when contact deletion fails', (
    tester,
  ) async {
    final provider = _FakeContactProvider([
      ContactModel(
        id: 'contact-1',
        userId: 'user-1',
        name: 'Mina',
        createdAt: DateTime.utc(2026, 11, 1),
      ),
    ], failDelete: true);

    await tester.pumpWidget(
      ChangeNotifierProvider<ContactProvider>.value(
        value: provider,
        child: const MaterialApp(home: FriendListScreen()),
      ),
    );
    await tester.pump();
    await tester.drag(find.text('Mina'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ลบ'));
    await tester.pumpAndSettle();

    expect(find.text('ลบรายชื่อไม่สำเร็จ กรุณาลองอีกครั้ง'), findsOneWidget);
    expect(provider.contacts, hasLength(1));
  });
}

class _FakeContactProvider extends ContactProvider {
  _FakeContactProvider(List<ContactModel> contacts, {this.failDelete = false})
    : _contacts = contacts;

  List<ContactModel> _contacts;
  final bool failDelete;

  @override
  List<ContactModel> get contacts => List.unmodifiable(_contacts);

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  Future<void> loadContacts() async {}

  @override
  Future<void> deleteContact(String id) async {
    if (failDelete) throw StateError('delete failed');
    _contacts = _contacts.where((contact) => contact.id != id).toList();
    notifyListeners();
  }
}
