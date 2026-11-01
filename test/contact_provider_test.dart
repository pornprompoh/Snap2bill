import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/providers/contact_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://mock.supabase.co',
        // ignore: deprecated_member_use
        anonKey: 'mock-key',
      );
    } catch (_) {
      // Already initialized
    }
  });

  group('ContactProvider Tests', () {
    late ContactProvider provider;

    setUp(() {
      provider = ContactProvider();
    });

    test('initial state has empty contacts and no error', () {
      expect(provider.contacts, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);
    });

    test('loadContacts requires logged in user', () async {
      await provider.loadContacts();
      expect(provider.contacts, isEmpty);
      expect(provider.error, contains('กรุณาล็อกอิน'));
      expect(provider.isLoading, isFalse);
    });

    test('saveContactIfNotExists throws when user is unauthenticated', () {
      expect(
        () => provider.saveContactIfNotExists('Mina'),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteContact throws when user is unauthenticated', () {
      expect(
        () => provider.deleteContact('contact-1'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
