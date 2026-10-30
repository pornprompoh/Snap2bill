import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/services/firebase_auth_service.dart';

import 'mocks/mock_services.dart';

void main() {
  late MockFirebaseAuthService authService;
  late MockFirebaseDbService dbService;
  late StreamController<User?> authEvents;
  late UserProvider provider;

  setUp(() {
    authService = MockFirebaseAuthService();
    dbService = MockFirebaseDbService();
    authEvents = StreamController<User?>.broadcast();
    when(
      () => authService.authStateChanges,
    ).thenAnswer((_) => authEvents.stream);
    when(() => authService.currentUser).thenReturn(null);
    when(() => authService.currentUserId).thenReturn(null);
    provider = UserProvider(authService: authService, dbService: dbService);
  });

  tearDown(() async {
    provider.dispose();
    await authEvents.close();
  });

  test('tracks Firebase auth state and loads the matching profile', () async {
    final user = MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(() => user.displayName).thenReturn('Mina');
    when(() => user.email).thenReturn('mina@example.com');
    when(() => user.photoURL).thenReturn('https://example.com/avatar.png');
    when(() => authService.currentUserId).thenReturn('user-1');
    when(() => authService.currentUser).thenReturn(user);
    when(() => dbService.getMyProfile()).thenAnswer(
      (_) async => UserModel(
        id: 'user-1',
        displayName: 'Mina from profile',
        email: 'mina@example.com',
      ),
    );

    authEvents.add(user);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(provider.currentUserId, 'user-1');
    expect(provider.firebaseUser, same(user));
    expect(provider.currentUser?.id, 'user-1');
    expect(provider.currentUser?.displayName, 'Mina from profile');
    expect(provider.isLoading, isFalse);
    verify(() => dbService.getMyProfile()).called(1);
  });

  test('clears profile and friends when Firebase signs out', () async {
    final user = MockUser();
    when(() => user.uid).thenReturn('user-1');
    when(
      () => dbService.getMyProfile(),
    ).thenAnswer((_) async => UserModel(id: 'user-1', displayName: 'Mina'));
    authEvents
      ..add(user)
      ..add(null);
    await Future<void>.delayed(Duration.zero);

    expect(provider.currentUser, isNull);
    expect(provider.friends, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('forwards email sign-in and exposes explicit Firebase errors', () async {
    final result = FirebaseAuthResult.failure(
      code: 'invalid-credential',
      message: 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
    );
    when(
      () => authService.signInWithEmailAndPassword(
        email: 'mina@example.com',
        password: 'bad-password',
      ),
    ).thenAnswer((_) async => result);

    final response = await provider.signIn(
      email: 'mina@example.com',
      password: 'bad-password',
    );

    expect(response.errorCode, 'invalid-credential');
    expect(provider.error, 'อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    verify(
      () => authService.signInWithEmailAndPassword(
        email: 'mina@example.com',
        password: 'bad-password',
      ),
    ).called(1);
  });

  test('forwards sign-up and Facebook sign-in to Firebase Auth', () async {
    final failure = FirebaseAuthResult.failure(
      code: 'operation-not-allowed',
      message: 'Provider disabled',
    );
    when(
      () => authService.signUpWithEmailAndPassword(
        email: 'new@example.com',
        password: 'pass1234',
      ),
    ).thenAnswer((_) async => failure);
    when(
      () => authService.signInWithFacebook(),
    ).thenAnswer((_) async => failure);

    expect(
      (await provider.signUp(
        email: 'new@example.com',
        password: 'pass1234',
      )).errorCode,
      'operation-not-allowed',
    );
    expect(
      (await provider.signInWithFacebook()).errorMessage,
      'Provider disabled',
    );
    expect(provider.error, 'Provider disabled');
  });

  test('signs out and clears user state', () async {
    when(() => authService.signOut()).thenAnswer((_) async {});

    await provider.signOut();

    expect(provider.currentUser, isNull);
    expect(provider.error, isNull);
    verify(() => authService.signOut()).called(1);
  });

  test('persists trimmed profile payment details', () async {
    when(
      () => dbService.updateUserProfile(
        displayName: 'Mina',
        paymentInfo: {
          'type': 'phone',
          'number': '0812345678',
          'bank_name': 'SCB',
          'bank_account_number': '123-4',
          'bank_account_name': 'Mina',
        },
      ),
    ).thenAnswer(
      (_) async => UserModel(
        id: 'user-1',
        displayName: 'Mina',
        paymentInfo: {
          'type': 'phone',
          'number': '0812345678',
          'bank_name': 'SCB',
          'bank_account_number': '123-4',
          'bank_account_name': 'Mina',
        },
      ),
    );

    final saved = await provider.saveProfile(
      name: 'Mina',
      promptPayNumber: ' 0812345678 ',
      promptPayType: 'phone',
      bankName: ' SCB ',
      bankAccountNumber: ' 123-4 ',
    );

    expect(saved, isTrue);
    expect(provider.currentUser?.displayName, 'Mina');
    expect(provider.currentUser?.bankAccountNumber, '123-4');
  });

  test('returns failure when profile update throws', () async {
    when(
      () => dbService.updateUserProfile(displayName: 'Mina', paymentInfo: null),
    ).thenThrow(StateError('Firestore unavailable'));

    expect(await provider.saveProfile(name: 'Mina'), isFalse);
    expect(provider.error, 'บันทึกโปรไฟล์ไม่สำเร็จ');
    expect(provider.isLoading, isFalse);
  });

  test('loads and adds Firestore friends', () async {
    when(() => dbService.getMyFriends()).thenAnswer(
      (_) async => [
        FriendModel(id: 'friend-1', userId: 'user-1', friendName: 'Nina'),
      ],
    );
    when(() => dbService.addFriend('Nina')).thenAnswer((_) async {});

    await provider.loadFriends();
    expect(provider.friends.single.friendName, 'Nina');

    await provider.addFriend('Nina');

    verify(() => dbService.addFriend('Nina')).called(1);
    verify(() => dbService.getMyFriends()).called(2);
  });
}
