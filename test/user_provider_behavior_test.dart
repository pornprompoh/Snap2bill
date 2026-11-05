import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/domain/repositories/user_repository.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this.userId);

  final String userId;
  int profileReads = 0;
  final addedFriends = <String>[];
  final updates = <({String displayName, Map<String, dynamic>? paymentInfo})>[];
  List<FriendModel> friends = [];

  @override
  Future<UserModel?> getMyProfile() async {
    profileReads++;
    return UserModel(
      id: userId,
      displayName: 'Server name',
      email: 'user@example.com',
    );
  }

  @override
  Future<UserModel> updateUserProfile({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  }) async {
    updates.add((displayName: displayName, paymentInfo: paymentInfo));
    return UserModel(
      id: userId,
      displayName: displayName,
      email: 'user@example.com',
      paymentInfo: paymentInfo,
    );
  }

  @override
  Future<List<FriendModel>> getMyFriends() async => friends;

  @override
  Future<void> addFriend(String friendName) async {
    addedFriends.add(friendName);
    friends = [
      ...friends,
      FriendModel(
        id: 'friend-${friends.length + 1}',
        userId: userId,
        friendName: friendName,
      ),
    ];
  }
}

String _testToken(String userId) {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': userId,
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'user@example.com',
        'iat': now,
        'exp': now + 3600,
      }),
    ),
  );
  return '$header.$payload.${base64Url.encode(utf8.encode('test-signature'))}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const userId = 'user-1';
  late _FakeUserRepository repository;
  late UserProvider provider;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final documentsPath = Directory(
      '${Directory.current.path}\\build\\user_provider_test_data',
    );
    if (await documentsPath.exists()) {
      await documentsPath.delete(recursive: true);
    }
    await documentsPath.create(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => call.method == 'getApplicationDocumentsDirectory'
              ? documentsPath.path
              : null,
        );
    try {
      await Supabase.initialize(
        url: 'https://user-provider-test.supabase.co',
        publishableKey: 'user-provider-test-key',
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'id': userId,
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'user@example.com',
            }),
            200,
            request: request,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
    } catch (_) {}
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await Supabase.instance.client.auth.setSession(
      'refresh-token',
      accessToken: _testToken(userId),
    );
    repository = _FakeUserRepository(userId);
    provider = UserProvider(userRepository: repository);
  });

  test('loads and caches a profile for offline reuse', () async {
    final loaded = await provider.fetchCurrentUserProfile();

    expect(loaded?.displayName, 'Server name');
    expect(provider.currentUser?.id, userId);
    expect(provider.isLoading, isFalse);
    expect(repository.profileReads, 1);

    final offline = OfflineService();
    offline.reportNetworkFailure(const SocketException('network unavailable'));
    provider.setOfflineService(offline);

    final cached = await provider.fetchCurrentUserProfile();
    expect(cached?.displayName, 'Server name');
    expect(repository.profileReads, 1);
    await offline.disposeService();
  });

  test('saves trimmed payment details through the repository', () async {
    final saved = await provider.saveProfile(
      name: '  Alice  ',
      promptPayNumber: '  0812345678  ',
      promptPayType: 'phone',
      bankName: '  Example Bank  ',
      bankAccountNumber: '  123-456  ',
      bankAccountName: '  Alice A.  ',
    );

    expect(saved, isTrue);
    expect(repository.updates, hasLength(1));
    expect(repository.updates.single.displayName, '  Alice  ');
    expect(repository.updates.single.paymentInfo, {
      'type': 'phone',
      'number': '0812345678',
      'bank_name': 'Example Bank',
      'bank_account_number': '123-456',
      'bank_account_name': 'Alice A.',
    });
    expect(provider.currentUser?.displayName, '  Alice  ');
    expect(provider.isLoading, isFalse);
  });

  test('queues profile changes locally while offline', () async {
    final offline = OfflineService();
    offline.reportNetworkFailure(const SocketException('network unavailable'));
    provider.setOfflineService(offline);

    final saved = await provider.saveProfile(
      name: 'Offline Alice',
      promptPayNumber: '  0890000000 ',
      promptPayType: 'phone',
    );

    expect(saved, isTrue);
    expect(repository.updates, isEmpty);
    final operations = await OfflineQueue().readAll();
    expect(operations, hasLength(1));
    expect(operations.single.type, 'update_profile');
    expect(operations.single.payload['id'], userId);
    final queuedData =
        operations.single.payload['data'] as Map<String, dynamic>;
    expect(queuedData['display_name'], 'Offline Alice');
    expect(queuedData['payment_info'], {
      'type': 'phone',
      'number': '0890000000',
    });
    expect(queuedData['updated_at'], isA<String>());
    await offline.disposeService();
  });

  test('adds a friend and refreshes the visible friend list', () async {
    repository.friends = [
      FriendModel(id: 'friend-1', userId: userId, friendName: 'Mina'),
    ];

    await provider.loadFriends();
    expect(provider.friends.map((friend) => friend.friendName), ['Mina']);

    await provider.addFriend('Niran');
    expect(repository.addedFriends, ['Niran']);
    expect(provider.friends.map((friend) => friend.friendName), [
      'Mina',
      'Niran',
    ]);
    expect(provider.isLoading, isFalse);
  });
}
