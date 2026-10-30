import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snap2bill/providers/contact_provider.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  group('ContactProvider contact names', () {
    test('treats names with different case and whitespace as duplicates', () {
      expect(ContactProvider.isSameContactName('  Alice ', 'alice'), isTrue);
    });

    test('keeps different names distinct', () {
      expect(ContactProvider.isSameContactName('Alice', 'Alicia'), isFalse);
    });

    test('does not treat an empty name as a duplicate', () {
      expect(ContactProvider.isSameContactName('', 'Bob'), isFalse);
    });

    test(
      'returns an error when loading contacts without authentication',
      () async {
        final provider = ContactProvider();
        await provider.loadContacts();

        expect(provider.contacts, isEmpty);
        expect(provider.error, contains('ล็อกอิน'));
      },
    );

    test('rejects saving a contact without authentication', () async {
      final provider = ContactProvider();

      await expectLater(
        provider.saveContactIfNotExists('Bob'),
        throwsStateError,
      );
    });

    test(
      'rejects deleting and updating a contact without authentication',
      () async {
        final provider = ContactProvider();
        await expectLater(
          provider.deleteContact('contact-1'),
          throwsStateError,
        );
        await expectLater(
          provider.updateContact(id: 'contact-1', name: 'Bob'),
          throwsStateError,
        );
      },
    );

    test('rejects invalid contact updates', () async {
      final provider = ContactProvider();
      await expectLater(
        provider.updateContact(id: 'contact-1', name: ''),
        throwsStateError,
      );
    });
  });
}
