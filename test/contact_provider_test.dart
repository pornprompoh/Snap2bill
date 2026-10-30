import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snap2bill/providers/contact_provider.dart';

import 'mocks/mock_services.dart';

void main() {
  late MockFirebaseAuth auth;
  late MockUser user;
  late MockFirebaseDbService dbService;
  late ContactProvider provider;

  setUpAll(registerMockServiceFallbackValues);

  setUp(() {
    auth = MockFirebaseAuth();
    user = MockUser();
    dbService = MockFirebaseDbService();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user-1');
    provider = ContactProvider(auth: auth, dbService: dbService);
  });

  tearDown(() {
    provider.dispose();
  });

  test('loads saved contacts from Firestore service', () async {
    when(() => dbService.getContacts('user-1')).thenAnswer(
      (_) async => [
        {
          'id': 'contact-1',
          'userId': 'user-1',
          'name': 'Mina',
          'note': 'Work',
          'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
        },
      ],
    );

    await provider.loadContacts('user-1');

    expect(provider.contacts, hasLength(1));
    expect(provider.contacts.single.name, 'Mina');
    expect(provider.contacts.single.note, 'Work');
    expect(provider.contacts.single.createdAt, DateTime(2026, 10, 1));
    expect(provider.error, isNull);
    verify(() => dbService.getContacts('user-1')).called(1);
  });

  test('records an error when loading contacts fails', () async {
    when(
      () => dbService.getContacts('user-1'),
    ).thenThrow(StateError('Firestore unavailable'));

    await provider.loadContacts('user-1');

    expect(provider.contacts, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.error, contains('Firestore unavailable'));
  });

  test('saves a new contact with trimmed name and note', () async {
    when(() => dbService.getContacts('user-1')).thenAnswer((_) async => []);
    when(
      () => dbService.saveContact(any()),
    ).thenAnswer((_) async => 'contact-new');

    await provider.saveContactIfNotExists('  Mina  ', '  Coworker  ');

    expect(provider.contacts, hasLength(1));
    expect(provider.contacts.single.name, 'Mina');
    expect(provider.contacts.single.note, 'Coworker');
    final savedContact =
        verify(() => dbService.saveContact(captureAny())).captured.single
            as Map<String, dynamic>;
    expect(savedContact['userId'], 'user-1');
    expect(savedContact['name'], 'Mina');
    expect(savedContact['note'], 'Coworker');
  });

  test('does not save a duplicate contact (case-insensitive)', () async {
    when(() => dbService.getContacts('user-1')).thenAnswer(
      (_) async => [
        {'id': 'contact-1', 'name': 'Mina'},
      ],
    );

    await provider.saveContactIfNotExists('  MINA ');

    expect(provider.contacts, isEmpty);
    verifyNever(() => dbService.saveContact(any()));
  });

  test('deletes a saved contact from Firestore and local state', () async {
    when(() => dbService.getContacts('user-1')).thenAnswer(
      (_) async => [
        {
          'id': 'contact-1',
          'user_id': 'user-1',
          'name': 'Mina',
          'created_at': DateTime(2026, 10, 1).toIso8601String(),
        },
      ],
    );
    when(
      () => dbService.deleteContact('contact-1', userId: 'user-1'),
    ).thenAnswer((_) async {});
    await provider.loadContacts();

    await provider.deleteContact('contact-1');

    expect(provider.contacts, isEmpty);
    verify(
      () => dbService.deleteContact('contact-1', userId: 'user-1'),
    ).called(1);
  });

  test('rejects contact operations without an authenticated user', () async {
    when(() => auth.currentUser).thenReturn(null);

    await provider.loadContacts();

    expect(provider.error, contains('กรุณาล็อกอิน'));
    await expectLater(
      provider.saveContactIfNotExists('Mina'),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      provider.deleteContact('contact-1'),
      throwsA(isA<StateError>()),
    );
  });
}
