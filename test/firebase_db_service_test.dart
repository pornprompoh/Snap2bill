import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snap2bill/services/firebase_db_service.dart';

import 'mocks/mock_services.dart';

void main() {
  late MockFirebaseFirestore firestore;
  late MockFirebaseAuth auth;
  late MockUser user;
  late FirebaseDbService service;
  late Map<String, MockCollectionReference> collections;
  late Map<String, Map<String, MockDocumentReference>> documents;
  late Map<String, MockQuerySnapshot> querySnapshots;
  late MockWriteBatch batch;

  setUpAll(registerMockServiceFallbackValues);

  setUp(() {
    firestore = MockFirebaseFirestore();
    auth = MockFirebaseAuth();
    user = MockUser();
    collections = {};
    documents = {};
    querySnapshots = {};
    batch = MockWriteBatch();
    service = FirebaseDbService(firestore: firestore, auth: auth);
    when(() => firestore.batch()).thenReturn(batch);
    when(batch.commit).thenAnswer((_) async {});
    when(() => batch.set(any(), any(), any())).thenAnswer((_) {});
    when(() => batch.update(any(), any())).thenAnswer((_) {});
    when(() => batch.delete(any())).thenAnswer((_) {});

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user-1');
    when(() => user.email).thenReturn('user@example.com');
    when(() => user.displayName).thenReturn('Test User');
    when(() => user.photoURL).thenReturn(null);

    for (final name in [
      'profiles',
      'users',
      'bills',
      'bill_participants',
      'saved_contacts',
      'lobbies',
      'friends',
    ]) {
      final collection = MockCollectionReference();
      collections[name] = collection;
      documents[name] = {};
      querySnapshots[name] = MockQuerySnapshot();
      when(() => firestore.collection(name)).thenReturn(collection);
      when(() => collection.doc(any())).thenAnswer((invocation) {
        final id = invocation.positionalArguments.first as String;
        return documents[name]!.putIfAbsent(id, MockDocumentReference.new);
      });
      when(() => collection.doc()).thenAnswer((_) {
        final reference = documents[name]!.putIfAbsent(
          'generated',
          MockDocumentReference.new,
        );
        when(() => reference.id).thenReturn('generated');
        return reference;
      });
      when(
        () => collection.where(any(), isEqualTo: any(named: 'isEqualTo')),
      ).thenReturn(collection);
      when(
        () => collection.orderBy(any(), descending: any(named: 'descending')),
      ).thenReturn(collection);
      when(
        () => collection.get(),
      ).thenAnswer((_) async => querySnapshots[name]!);
    }
    when(
      () => collections['profiles']!.where(
        FieldPath.documentId,
        whereIn: any(named: 'whereIn'),
      ),
    ).thenReturn(collections['profiles']!);
  });

  test('creates a user profile with the document ID', () async {
    final reference = documents['users']!.putIfAbsent(
      'user-1',
      MockDocumentReference.new,
    );
    when(() => reference.set(any(), any())).thenAnswer((_) async {});

    expect(
      await service.createUser('user-1', {'display_name': 'Test'}),
      'user-1',
    );

    final savedData =
        verify(() => reference.set(captureAny(), any())).captured.single
            as Map<String, dynamic>;
    expect(savedData['userId'], 'user-1');
    expect(savedData['display_name'], 'Test');
  });

  test('gets user data and returns null for a missing profile', () async {
    final reference = documents['users']!.putIfAbsent(
      'user-1',
      MockDocumentReference.new,
    );
    final snapshot = MockDocumentSnapshot();
    when(() => reference.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.exists).thenReturn(true);
    when(() => snapshot.id).thenReturn('user-1');
    when(() => snapshot.data()).thenReturn({'display_name': 'Test'});

    expect(await service.getUserById('user-1'), {
      'id': 'user-1',
      'display_name': 'Test',
    });

    when(() => snapshot.exists).thenReturn(false);
    expect(await service.getUserById('user-1'), isNull);
  });

  test('returns the authenticated user profile with profile fields', () async {
    final reference = documents['profiles']!.putIfAbsent(
      'user-1',
      MockDocumentReference.new,
    );
    final snapshot = MockDocumentSnapshot();
    when(() => reference.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.data()).thenReturn({
      'display_name': 'Saved Name',
      'email': 'saved@example.com',
      'payment_info': {'type': 'phone', 'number': '0812345678'},
    });
    when(() => snapshot.id).thenReturn('user-1');

    final profile = await service.getMyProfile();

    expect(profile?.displayName, 'Saved Name');
    expect(profile?.email, 'saved@example.com');
    expect(profile?.promptPayNumber, '0812345678');

    when(() => snapshot.data()).thenReturn(null);
    final fallbackProfile = await service.getMyProfile();
    expect(fallbackProfile?.displayName, 'Test User');
    expect(fallbackProfile?.email, 'user@example.com');
  });

  test('loads and validates profile documents', () async {
    final reference = documents['profiles']!.putIfAbsent(
      'user-2',
      MockDocumentReference.new,
    );
    final snapshot = MockDocumentSnapshot();
    when(() => reference.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.data()).thenReturn({'display_name': 'Friend'});
    when(() => snapshot.id).thenReturn('user-2');

    expect((await service.getProfile('user-2')).displayName, 'Friend');

    when(() => snapshot.data()).thenReturn(null);
    await expectLater(service.getProfile('user-2'), throwsStateError);
  });

  test('loads unique non-empty profiles by document ID', () async {
    final snapshot = querySnapshots['profiles']!;
    final profile = MockQueryDocumentSnapshot();
    when(() => snapshot.docs).thenReturn([profile]);
    when(() => profile.id).thenReturn('user-2');
    when(() => profile.data()).thenReturn({'display_name': 'Friend'});

    final result = await service.getProfiles(['user-2', '', 'user-2']);

    expect(result, [
      {'id': 'user-2', 'display_name': 'Friend'},
    ]);
  });

  test('updates profile and rejects unsupported payment types', () async {
    final reference = documents['profiles']!.putIfAbsent(
      'user-1',
      MockDocumentReference.new,
    );
    when(() => reference.set(any(), any())).thenAnswer((_) async {});

    final profile = await service.updateUserProfile(
      displayName: 'Updated',
      paymentInfo: {'type': 'phone', 'number': '0812345678'},
    );
    expect(profile.displayName, 'Updated');
    expect(profile.promptPayNumber, '0812345678');

    await expectLater(
      service.updateUserProfile(
        displayName: 'Updated',
        paymentInfo: {'type': 'unsupported'},
      ),
      throwsArgumentError,
    );
  });

  test('reads saved contacts from both supported user ID fields', () async {
    final snapshot = querySnapshots['saved_contacts']!;
    final contact = MockQueryDocumentSnapshot();
    final olderContact = MockQueryDocumentSnapshot();
    when(() => snapshot.docs).thenReturn([olderContact, contact]);
    when(() => contact.id).thenReturn('contact-1');
    when(() => contact.data()).thenReturn({
      'userId': 'user-1',
      'name': 'Friend',
      'createdAt': DateTime(2026, 1, 2),
    });
    when(() => olderContact.id).thenReturn('contact-older');
    when(() => olderContact.data()).thenReturn({
      'userId': 'user-1',
      'name': 'Older Friend',
      'createdAt': DateTime(2026, 1, 1),
    });

    final contacts = await service.getContacts('user-1');

    expect(contacts, hasLength(2));
    expect(contacts.first['id'], 'contact-1');
    expect(contacts.first['name'], 'Friend');
    expect(contacts.last['name'], 'Older Friend');
    verify(
      () => collections['saved_contacts']!.where('userId', isEqualTo: 'user-1'),
    ).called(1);
    verify(
      () =>
          collections['saved_contacts']!.where('user_id', isEqualTo: 'user-1'),
    ).called(1);
  });

  test('saves and deletes contacts only for their owner', () async {
    final reference = documents['saved_contacts']!.putIfAbsent(
      'contact-1',
      MockDocumentReference.new,
    );
    when(() => reference.set(any(), any())).thenAnswer((_) async {});
    when(() => reference.id).thenReturn('contact-1');
    when(() => reference.get()).thenAnswer((_) async {
      final snapshot = MockDocumentSnapshot();
      when(
        () => snapshot.data(),
      ).thenReturn({'user_id': 'user-1', 'name': 'Friend'});
      return snapshot;
    });
    when(() => reference.delete()).thenAnswer((_) async {});

    expect(
      await service.saveContact({'id': 'contact-1', 'name': 'Friend'}),
      'contact-1',
    );
    await service.deleteContact('contact-1', userId: 'user-1');
    verify(() => reference.delete()).called(1);

    await expectLater(
      service.deleteContact('contact-1', userId: 'another-user'),
      throwsStateError,
    );
  });

  test('maps bill documents and their item subcollection', () async {
    final billReference = documents['bills']!.putIfAbsent(
      'bill-1',
      MockDocumentReference.new,
    );
    final billSnapshot = MockDocumentSnapshot();
    when(() => billReference.get()).thenAnswer((_) async => billSnapshot);
    when(() => billSnapshot.exists).thenReturn(true);
    when(() => billSnapshot.id).thenReturn('bill-1');
    when(
      () => billSnapshot.data(),
    ).thenReturn({'userId': 'user-1', 'shop_name': 'Cafe'});

    final itemCollection = MockCollectionReference();
    final itemSnapshot = MockQuerySnapshot();
    final item = MockQueryDocumentSnapshot();
    when(() => billReference.collection('items')).thenReturn(itemCollection);
    when(() => itemCollection.get()).thenAnswer((_) async => itemSnapshot);
    when(() => itemSnapshot.docs).thenReturn([item]);
    when(() => item.id).thenReturn('item-1');
    when(() => item.data()).thenReturn({'item_name': 'Coffee', 'price': 50});

    final result = await service.getBillById('bill-1');

    expect(result?['id'], 'bill-1');
    expect(result?['owner_id'], 'user-1');
    expect((result?['items'] as List).single['item_name'], 'Coffee');

    when(() => billSnapshot.exists).thenReturn(false);
    expect(await service.getBillById('bill-1'), isNull);
  });

  test(
    'maps user bills from legacy and current owner fields by date',
    () async {
      final snapshot = querySnapshots['bills']!;
      final newer = MockQueryDocumentSnapshot();
      final older = MockQueryDocumentSnapshot();
      when(() => snapshot.docs).thenReturn([older, newer]);
      when(() => older.id).thenReturn('bill-old');
      when(() => older.data()).thenReturn({
        'owner_id': 'user-1',
        'created_at': '2026-01-01T10:00:00Z',
        'shop_name': 'Old',
      });
      when(() => newer.id).thenReturn('bill-new');
      when(() => newer.data()).thenReturn({
        'userId': 'user-1',
        'createdAt': DateTime.utc(2026, 1, 2),
        'shop_name': 'New',
      });

      final bills = await service.getUserBills('user-1');

      expect(bills.map((bill) => bill['id']), ['bill-new', 'bill-old']);
      expect(bills.first['owner_id'], 'user-1');
      verify(
        () => collections['bills']!.where('userId', isEqualTo: 'user-1'),
      ).called(1);
      verify(
        () => collections['bills']!.where('owner_id', isEqualTo: 'user-1'),
      ).called(1);
    },
  );

  test('loads current-user bills and returns bills shared with them', () async {
    final billSnapshot = querySnapshots['bills']!;
    final bill = MockQueryDocumentSnapshot();
    when(() => billSnapshot.docs).thenReturn([bill]);
    when(() => bill.id).thenReturn('bill-1');
    when(() => bill.data()).thenReturn({
      'owner_id': 'user-1',
      'shop_name': 'Cafe',
      'total_amount': 50,
    });
    when(() => querySnapshots['bill_participants']!.docs).thenReturn([]);

    final ownBills = await service.getMyBills();
    expect(ownBills.single.shopName, 'Cafe');

    final sharedBills = await service.getBillsForUser('user-1');
    expect(sharedBills.single['id'], 'bill-1');
    verify(
      () => collections['bill_participants']!.where(
        'profile_id',
        isEqualTo: 'user-1',
      ),
    ).called(1);
  });

  test('creates and retrieves a lobby document', () async {
    final reference = documents['lobbies']!.putIfAbsent(
      'room-1',
      MockDocumentReference.new,
    );
    final snapshot = MockDocumentSnapshot();
    when(() => reference.set(any())).thenAnswer((_) async {});
    when(() => reference.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.data()).thenReturn({'shop_name': 'Cafe'});
    when(() => snapshot.id).thenReturn('room-1');

    await service.createLobby(
      roomCode: 'room-1',
      hostId: 'user-1',
      shopName: 'Cafe',
      totalAmount: 100,
      receiptData: {'items': []},
    );
    expect(await service.getLobby('room-1'), {
      'id': 'room-1',
      'shop_name': 'Cafe',
    });
    when(() => snapshot.data()).thenReturn(null);
    expect(await service.getLobby('room-1'), isNull);
  });

  test('updates participant status when matching rows exist', () async {
    final snapshot = querySnapshots['bill_participants']!;
    final row = MockQueryDocumentSnapshot();
    final reference = MockDocumentReference();
    when(() => snapshot.docs).thenReturn([row]);
    when(() => row.reference).thenReturn(reference);

    await service.updateParticipantStatus('bill-1', 'user-1', 'paid');

    verify(() => batch.commit()).called(1);
  });

  test('reads guest members from lobby receipt data', () async {
    final reference = documents['lobbies']!.putIfAbsent(
      'room-1',
      MockDocumentReference.new,
    );
    final snapshot = MockDocumentSnapshot();
    when(() => reference.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.id).thenReturn('room-1');
    when(() => snapshot.data()).thenReturn({
      'receipt_json': {
        'room_members': [
          {'id': 'guest_1', 'name': 'Guest', 'is_guest': true},
          {'id': 'user-2', 'name': 'Signed in', 'is_guest': false},
          {'name': 'Invalid'},
        ],
      },
    });

    final members = await service.getRoomGuestMembers('room-1');

    expect(members, hasLength(1));
    expect(members.single.id, 'guest_1');
    expect(members.single.isGuest, isTrue);

    when(() => snapshot.data()).thenReturn({'receipt_json': []});
    expect(await service.getRoomGuestMembers('room-1'), isEmpty);
    when(() => snapshot.data()).thenReturn({
      'receipt_json': {'room_members': 'invalid'},
    });
    expect(await service.getRoomGuestMembers('room-1'), isEmpty);
  });

  test(
    'creates Firestore bills and validates input and authentication',
    () async {
      final bill = await service.createBill({
        'id': 'bill-1',
        'owner_id': 'user-1',
        'shop_name': 'Cafe',
        'total_amount': 50,
      });

      expect(bill.id, 'bill-1');
      expect(bill.ownerId, 'user-1');
      verify(() => batch.commit()).called(1);

      final shorthandBill = await service.createBill('Cafe', 25);
      expect(shorthandBill.id, 'generated');
      expect(shorthandBill.totalAmount, 25);

      await expectLater(
        service.createBill({'items': 'not a list'}),
        throwsArgumentError,
      );
      await expectLater(service.createBill(42), throwsArgumentError);

      when(() => auth.currentUser).thenReturn(null);
      await expectLater(
        service.createBill({'shop_name': 'Cafe'}),
        throwsStateError,
      );
    },
  );

  test('saves completed bills while omitting guest participants', () async {
    final reference = documents['bills']!.putIfAbsent(
      'completed-1',
      MockDocumentReference.new,
    );
    when(() => reference.id).thenReturn('completed-1');

    final result = await service.saveCompletedBill(
      billId: 'completed-1',
      bill: {'owner_id': 'user-1', 'shop_name': 'Cafe'},
      participantTotals: {'user-2': 40, 'guest_1': 10},
    );

    expect(result, 'completed-1');
    verify(() => batch.commit()).called(1);

    await expectLater(
      service.saveCompletedBill(
        billId: 'invalid-bill',
        bill: {
          'receipt_json': {
            'items': ['invalid item'],
          },
        },
        participantTotals: {},
      ),
      throwsArgumentError,
    );
  });

  test('updates bill fields and rejects missing participant rows', () async {
    await service.updateBill('bill-1', {'shop_name': 'Updated'});
    verify(() => batch.commit()).called(1);

    when(() => querySnapshots['bill_participants']!.docs).thenReturn([]);
    await expectLater(
      service.updateParticipantStatus('bill-1', 'user-2', 'paid'),
      throwsStateError,
    );
  });

  test('replaces bill items when updating bill contents', () async {
    final billReference = documents['bills']!.putIfAbsent(
      'bill-items',
      MockDocumentReference.new,
    );
    final itemCollection = MockCollectionReference();
    final itemReference = MockDocumentReference();
    final itemSnapshot = MockQuerySnapshot();
    when(() => billReference.collection('items')).thenReturn(itemCollection);
    when(() => itemCollection.get()).thenAnswer((_) async => itemSnapshot);
    when(() => itemSnapshot.docs).thenReturn([]);
    when(() => itemCollection.doc('item-1')).thenReturn(itemReference);

    await service.updateBill('bill-items', {
      'items': [
        {'id': 'item-1', 'item_name': 'Coffee', 'price': 50},
      ],
    });

    verify(() => batch.commit()).called(1);
  });

  test('loads and creates friends for the signed-in user', () async {
    final snapshot = querySnapshots['friends']!;
    final friend = MockQueryDocumentSnapshot();
    final collection = collections['friends']!;
    final createdReference = MockDocumentReference();
    when(() => snapshot.docs).thenReturn([friend]);
    when(() => friend.id).thenReturn('friend-1');
    when(
      () => friend.data(),
    ).thenReturn({'user_id': 'user-1', 'friend_name': 'Alex'});
    when(() => collection.add(any())).thenAnswer((_) async => createdReference);

    final friends = await service.getMyFriends();
    await service.addFriend('Alex');

    expect(friends.single.friendName, 'Alex');
    verify(() => collection.add(any())).called(1);
  });

  test('returns no authenticated-user bills when signed out', () async {
    when(() => auth.currentUser).thenReturn(null);

    expect(await service.getMyBills(), isEmpty);
    expect(await service.getMyFriends(), isEmpty);
    expect(await service.getMyProfile(), isNull);
    await expectLater(service.addFriend('Alex'), throwsStateError);
    await expectLater(service.saveContact({'name': 'Alex'}), throwsStateError);
  });
}
