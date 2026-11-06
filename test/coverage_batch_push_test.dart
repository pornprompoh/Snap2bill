import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/data/repositories/supabase_auth_repository.dart';
import 'package:snap2bill/data/repositories/supabase_bill_repository.dart';
import 'package:snap2bill/data/repositories/supabase_user_repository.dart';
import 'package:snap2bill/database/tables.dart';
import 'package:snap2bill/domain/repositories/auth_repository.dart';
import 'package:snap2bill/domain/repositories/user_repository.dart';
import 'package:snap2bill/domain/usecases/auth_use_cases.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/bill/summary_screen.dart';
import 'package:snap2bill/services/auth/supabase_auth_service.dart';
import 'package:snap2bill/services/data/supabase_db_service.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:snap2bill/utils/mascot_assets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockUserRepository extends Mock implements UserRepository {}

class _FakeDbService extends SupabaseDbService {
  @override
  String? get currentUserId => 'user-1';

  @override
  Future<UserModel?> getMyProfile() async {
    return UserModel(id: 'user-1', displayName: 'Alice');
  }

  @override
  Future<UserModel> updateUserProfile({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  }) async {
    return UserModel(
      id: 'user-1',
      displayName: displayName,
      paymentInfo: paymentInfo,
    );
  }

  @override
  Future<List<FriendModel>> getMyFriends() async {
    return [FriendModel(id: 'friend-1', userId: 'user-1', friendName: 'Bob')];
  }

  @override
  Future<void> addFriend(String friendName) async {}

  @override
  Future<List<BillModel>> getMyBills() async {
    return [BillModel(id: 'bill-1', ownerId: 'user-1', shopName: 'Cafe')];
  }

  @override
  Future<BillModel> createBill(String shopName, double totalAmount) async {
    return BillModel(
      id: 'bill-1',
      ownerId: 'user-1',
      shopName: shopName,
      totalAmount: totalAmount,
    );
  }

  @override
  Future<List<RoomMember>> getRoomGuestMembers(String roomCode) async {
    return [const RoomMember(id: 'guest-1', name: 'Guest', isGuest: true)];
  }

  @override
  Future<RoomMember> addRoomGuestMember(
    String roomCode,
    RoomMember member,
  ) async {
    return member;
  }
}

class _FakeAuthService extends SupabaseAuthService {
  @override
  Future<AuthResponse?> signInWithGoogle() async => null;

  @override
  Future<void> signInWithFacebook() async {}
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    final documentsDirectory = Directory(
      '${Directory.current.path}\\build\\coverage_batch_push_test_data',
    );
    await documentsDirectory.create(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async =>
              call.method == 'getApplicationDocumentsDirectory'
                  ? documentsDirectory.path
                  : null,
        );

    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'public-key',
    );
  });

  group('Coverage push batch', () {
    test('AppRoutes normalizes hash and query-based routes', () {
      expect(AppRoutes.normalizeRouteName('=_='), AppRoutes.splash);
      expect(AppRoutes.normalizeRouteName('/#/login'), AppRoutes.login);
      expect(
        AppRoutes.normalizeRouteName('https://example.com/#/summary?room=abc123'),
        AppRoutes.summary,
      );
      expect(
        AppRoutes.normalizeRouteName('https://example.com/profile?q=42'),
        AppRoutes.profile,
      );
      expect(AppRoutes.normalizeRouteName('abc'), 'abc');
    });

    test('AppRoutes generates the main route variants', () {
      expect(
        AppRoutes.generateRoute(const RouteSettings(name: AppRoutes.login)),
        isA<MaterialPageRoute>(),
      );
      expect(
        AppRoutes.generateRoute(
          const RouteSettings(name: AppRoutes.join, arguments: {'roomId': 'ABC123'}),
        ),
        isA<MaterialPageRoute>(),
      );
      expect(
        AppRoutes.generateRoute(
          const RouteSettings(
            name: AppRoutes.review,
            arguments: {
              'receiptData': {'shop_name': 'Café', 'items': []},
              'receiptImageBytes': null,
            },
          ),
        ),
        isA<MaterialPageRoute>(),
      );
      expect(
        AppRoutes.generateRoute(
          const RouteSettings(
            name: AppRoutes.summary,
            arguments: {
              'lobbyId': 'ABC123',
              'receiptData': {'items': []},
              'itemSharers': {'1': ['user-1']},
              'roomParticipants': [{'id': 'user-1', 'name': 'Alice'}],
            },
          ),
        ),
        isA<MaterialPageRoute>(),
      );
      expect(
        AppRoutes.generateRoute(
          RouteSettings(
            name: AppRoutes.loading,
            arguments: Uint8List.fromList([1, 2, 3]),
          ),
        ),
        isA<MaterialPageRoute>(),
      );
      expect(
        AppRoutes.generateRoute(const RouteSettings(name: 'missing-route')),
        isA<MaterialPageRoute>(),
      );
    });

    test('Database table definitions expose the expected schema', () {
      expect(() => CachedBills().id, throwsA(isA<UnsupportedError>()));
      expect(() => CachedBills().shopName, throwsA(isA<UnsupportedError>()));
      expect(() => CachedProfiles().id, throwsA(isA<UnsupportedError>()));
      expect(() => CachedRooms().roomCode, throwsA(isA<UnsupportedError>()));
      expect(() => OfflineDrafts().id, throwsA(isA<UnsupportedError>()));
    });

    test('Mascot assets expose the expected file paths', () {
      expect(MascotAssets.fallback, 'assets/images/bunny_mascot.png');
      expect(MascotAssets.waving, 'assets/images/mascots/waving.png');
      expect(MascotAssets.phoneHappy, 'assets/images/mascots/phone_happy.png');
      expect(MascotAssets.cheering, 'assets/images/mascots/cheering.png');
    });

    test('Auth use cases delegate to their repositories', () async {
      final repository = _MockAuthRepository();
      when(() => repository.signInWithGoogle())
          .thenAnswer((_) async => null);
      when(() => repository.signInWithFacebook())
          .thenAnswer((_) async {});
      when(() => repository.signInWithEmail('a@b.com', 'pw'))
          .thenAnswer((_) async => AuthResponse(session: null, user: null));
      when(() => repository.signUp('a@b.com', 'pw'))
          .thenAnswer((_) async => AuthResponse(session: null, user: null));

      final google = SignInWithGoogle(repository);
      final facebook = SignInWithFacebook(repository);
      final email = SignInWithEmail(repository);
      final signUp = SignUp(repository);

      expect(await google.call(), equals(null));
      await facebook.call();
      expect(
        await email.call('a@b.com', 'pw'),
        isA<AuthResponse>(),
      );
      expect(
        await signUp.call('a@b.com', 'pw'),
        isA<AuthResponse>(),
      );
    });

    test('Supabase user repository delegates every profile action', () async {
      final repository = SupabaseUserRepository(service: _FakeDbService());

      final profile = await repository.getMyProfile();
      final updated = await repository.updateUserProfile(
        displayName: 'Alice Updated',
        paymentInfo: {'type': 'phone', 'number': '123'},
      );
      final friends = await repository.getMyFriends();
      await repository.addFriend('Charlie');

      expect(profile?.displayName, 'Alice');
      expect(updated.displayName, 'Alice Updated');
      expect(friends.first.friendName, 'Bob');
      expect(friends.first.userId, 'user-1');
    });

    test('Supabase bill repository delegates all bill operations', () async {
      final repository = SupabaseBillRepository(service: _FakeDbService());

      final bills = await repository.getMyBills();
      final created = await repository.createBill('Cafe', 150.0);
      final guests = await repository.getRoomGuestMembers('ABC123');
      final guest = await repository.addRoomGuestMember(
        'ABC123',
        const RoomMember(id: 'guest-2', name: 'Guest 2', isGuest: true),
      );

      expect(repository.currentUserId, 'user-1');
      expect(bills.first.shopName, 'Cafe');
      expect(created.shopName, 'Cafe');
      expect(guests.first.name, 'Guest');
      expect(guest.name, 'Guest 2');
    });

    test('Supabase auth repository delegates OAuth actions, without network calls', () async {
      final repository = SupabaseAuthRepository(service: _FakeAuthService());

      expect(await repository.signInWithGoogle(), equals(null));
      await repository.signInWithFacebook();
    });

    test('Route arguments carry nested maps for the review and lobby flows', () {
      final reviewRoute = AppRoutes.generateRoute(
        const RouteSettings(
          name: AppRoutes.review,
          arguments: {
            'receiptData': {'shop_name': 'Krua Sam', 'items': []},
            'receiptImageBytes': null,
          },
        ),
      );
      final lobbyRoute = AppRoutes.generateRoute(
        const RouteSettings(
          name: AppRoutes.lobby,
          arguments: {
            'lobbyId': 'ROOM-1',
            'isHost': false,
            'receiptData': {'shop_name': 'Room lobby'},
          },
        ),
      );

      expect(reviewRoute, isA<MaterialPageRoute>());
      expect(lobbyRoute, isA<MaterialPageRoute>());
    });

    test('Route normalization handles a hash prefix plus query string', () {
      expect(
        AppRoutes.normalizeRouteName('#/join?roomId=R-99'),
        AppRoutes.join,
      );
      expect(
        AppRoutes.normalizeRouteName('/#/_=_'),
        AppRoutes.splash,
      );
      expect(
        AppRoutes.normalizeRouteName('room#detail'),
        'room',
      );
    });

    test('Route settings can resolve to the default root landing page', () {
      final route = AppRoutes.generateRoute(const RouteSettings());
      expect(route, isA<MaterialPageRoute>());
    });

    test('BillProvider calculates proportional and equal user shares', () {
      final items = [
        BillItemModel(
          id: 'item-1',
          billId: 'bill-1',
          itemName: 'Burger',
          price: 120,
          quantity: 1,
          userQuantities: {'user-1': 1},
          sharedUsers: ['user-2'],
        ),
        BillItemModel(
          id: 'item-2',
          billId: 'bill-1',
          itemName: 'Drink',
          price: 80,
          quantity: 1,
          userQuantities: {'user-2': 1},
        ),
      ];

      final proportional = BillProvider.calculateUserShares(
        items: items,
        finalTotal: 200,
        splitType: 'proportional',
        participantIds: const ['user-1', 'user-2'],
      );
      final equal = BillProvider.calculateUserShares(
        items: items,
        finalTotal: 200,
        splitType: 'equal',
        participantIds: const ['user-1', 'user-2'],
      );

      expect(proportional['user-1'], greaterThan(0.0));
      expect(proportional['user-2'], greaterThan(0.0));
      expect(equal['user-1'], greaterThan(0.0));
      expect(equal['user-2'], greaterThan(0.0));
    });

    test('UserProvider syncs profile and friends from its repository', () async {
      final profileRepository = _MockUserRepository();
      when(() => profileRepository.getMyProfile())
          .thenAnswer((_) async => UserModel(id: 'user-1', displayName: 'Alice'));
      when(() => profileRepository.getMyFriends())
          .thenAnswer((_) async => [
                FriendModel(id: 'friend-1', userId: 'user-1', friendName: 'Bob'),
              ]);
      when(() => profileRepository.updateUserProfile(
              displayName: any(named: 'displayName'),
              paymentInfo: any(named: 'paymentInfo')))
          .thenAnswer((invocation) async => UserModel(
                id: 'user-1',
                displayName: invocation.namedArguments[#displayName] as String,
                paymentInfo: invocation.namedArguments[#paymentInfo] as Map<String, dynamic>?,
              ));
      when(() => profileRepository.addFriend(any())).thenAnswer((_) async {});

      final provider = UserProvider(userRepository: profileRepository);
      final loadedProfile = await provider.fetchCurrentUserProfile();
      await provider.loadFriends();

      expect(loadedProfile?.displayName, 'Alice');
      expect(provider.currentUser?.displayName, 'Alice');
      expect(provider.friends.first.friendName, 'Bob');
    });

    testWidgets('SummaryScreen renders with share totals and progress states', (tester) async {
      final userRepository = _MockUserRepository();
      when(() => userRepository.getMyProfile())
          .thenAnswer((_) async => UserModel(
                id: 'user-1',
                displayName: 'Alice',
                paymentInfo: {'type': 'phone', 'number': '0812345678'},
              ));
      when(() => userRepository.getMyFriends())
          .thenAnswer((_) async => const []);
      when(() => userRepository.updateUserProfile(
              displayName: any(named: 'displayName'),
              paymentInfo: any(named: 'paymentInfo')))
          .thenAnswer((invocation) async => UserModel(
                id: 'user-1',
                displayName: invocation.namedArguments[#displayName] as String,
                paymentInfo: invocation.namedArguments[#paymentInfo] as Map<String, dynamic>?,
              ));
      when(() => userRepository.addFriend(any())).thenAnswer((_) async {});

      final offlineService = OfflineService();
      offlineService.reportNetworkFailure(const SocketException('offline'));
      final userProvider = UserProvider(userRepository: userRepository)
        ..setOfflineService(offlineService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OfflineService>.value(value: offlineService),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<BillProvider>(
              create: (_) => BillProvider(),
            ),
          ],
          child: MaterialApp(
            home: SummaryScreen(
              lobbyId: 'room-1',
              isHost: true,
              receiptData: {
                'shop_name': 'Test Café',
                'final_total': 200.0,
                'items': [
                  {'item_name': 'Burger', 'unit_price': 120.0, 'qty': 1},
                  {'item_name': 'Drink', 'unit_price': 80.0, 'qty': 1},
                ],
              },
              itemSharers: {
                0: [
                  {'user_id': 'user-1', 'quantity': 1},
                ],
                1: [
                  {'user_id': 'user-2', 'quantity': 1},
                ],
              },
              roomParticipants: [
                {'id': 'user-1', 'name': 'Alice'},
                {'id': 'user-2', 'name': 'Bob'},
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('สรุปยอดและชำระเงิน'), findsOneWidget);
      expect(find.text('Test Café'), findsWidgets);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
