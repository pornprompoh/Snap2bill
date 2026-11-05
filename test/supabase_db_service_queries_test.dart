import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/services/data/supabase_db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef RequestHandler = Future<http.Response> Function(http.Request request);

Future<SupabaseClient> _authenticatedClient(RequestHandler handler) async {
  final client = SupabaseClient(
    'https://db-service-test.supabase.co',
    'test-anon-key',
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/auth/v1/user')) {
        return _jsonResponse(request, {
          'id': 'user-1',
          'aud': 'authenticated',
          'role': 'authenticated',
          'email': 'user@example.com',
        });
      }
      return handler(request);
    }),
  );
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': 'user-1',
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'user@example.com',
        'iat': now,
        'exp': now + 3600,
      }),
    ),
  );
  final token =
      '$header.$payload.${base64Url.encode(utf8.encode('test-signature'))}';
  await client.auth.setSession('refresh-token', accessToken: token);
  return client;
}

http.Response _jsonResponse(
  http.Request request,
  Object body, {
  int status = 200,
}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    request: request,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  test(
    'maps the current profile and filters the profile query by auth user',
    () async {
      late final http.Request profileRequest;
      final client = await _authenticatedClient((request) async {
        profileRequest = request;
        return _jsonResponse(request, {
          'id': 'user-1',
          'display_name': 'Alice',
          'email': 'alice@example.com',
          'payment_info': {'type': 'phone', 'number': '0812345678'},
        });
      });
      addTearDown(client.dispose);

      final service = SupabaseDbService(client: client);
      final profile = await service.getMyProfile();

      expect(service.currentUserId, 'user-1');
      expect(profile?.displayName, 'Alice');
      expect(profile?.promptPayNumber, '0812345678');
      expect(profileRequest.url.pathSegments.last, 'profiles');
      expect(profileRequest.url.queryParameters['id'], 'eq.user-1');
    },
  );

  test(
    'updates profile fields and rejects unsupported PromptPay types',
    () async {
      var requestCount = 0;
      final client = await _authenticatedClient((request) async {
        requestCount++;
        expect(request.method, 'PATCH');
        expect(request.url.pathSegments.last, 'profiles');
        expect(request.url.queryParameters['id'], 'eq.user-1');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['display_name'], 'Alice');
        expect(body['payment_info'], {'type': 'phone', 'number': '0812345678'});
        expect(body['updated_at'], isA<String>());
        return _jsonResponse(request, {
          'id': 'user-1',
          'display_name': 'Alice',
          'payment_info': {'type': 'phone', 'number': '0812345678'},
        });
      });
      addTearDown(client.dispose);

      final service = SupabaseDbService(client: client);
      final updated = await service.updateUserProfile(
        displayName: 'Alice',
        paymentInfo: {'type': 'phone', 'number': '0812345678'},
      );
      expect(updated.promptPayNumber, '0812345678');

      await expectLater(
        service.updateUserProfile(
          displayName: 'Alice',
          paymentInfo: {'type': 'email', 'number': 'alice@example.com'},
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(requestCount, 1);
    },
  );

  test('queries visible friends and inserts a newly added friend', () async {
    var insertBody = <String, dynamic>{};
    final client = await _authenticatedClient((request) async {
      expect(request.url.pathSegments.last, 'friends');
      if (request.method == 'GET') {
        expect(request.url.queryParameters['user_id'], 'eq.user-1');
        expect(request.url.queryParameters['is_deleted'], 'eq.false');
        expect(
          request.url.queryParameters['order'],
          'created_at.desc.nullslast',
        );
        return _jsonResponse(request, [
          {
            'id': 'friend-1',
            'user_id': 'user-1',
            'friend_name': 'Mina',
            'linked_profile_id': null,
          },
        ]);
      }

      expect(request.method, 'POST');
      insertBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('', 201, request: request);
    });
    addTearDown(client.dispose);

    final service = SupabaseDbService(client: client);
    final friends = await service.getMyFriends();
    expect(friends.map((friend) => friend.friendName), ['Mina']);
    expect(friends.single.userId, 'user-1');

    await service.addFriend('Niran');
    expect(insertBody, {'user_id': 'user-1', 'friend_name': 'Niran'});
  });

  test(
    'filters room guest members and persists additions in the receipt',
    () async {
      Map<String, dynamic> receipt = {
        'room_members': [
          {'id': 'user-2', 'name': 'Mina', 'is_guest': false},
          {'id': 'guest_local', 'name': 'Local guest', 'is_guest': true},
          {'id': '', 'name': 'Missing id', 'is_guest': true},
        ],
      };
      final client = await _authenticatedClient((request) async {
        expect(request.url.pathSegments.last, 'lobbies');
        expect(request.url.queryParameters['room_code'], 'eq.ROOM01');
        if (request.method == 'GET') {
          return _jsonResponse(request, {
            'host_id': 'user-1',
            'receipt_json': receipt,
          });
        }

        expect(request.method, 'PATCH');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        receipt = Map<String, dynamic>.from(body['receipt_json'] as Map);
        return _jsonResponse(request, {'room_code': 'ROOM01'});
      });
      addTearDown(client.dispose);

      final service = SupabaseDbService(client: client);
      final guests = await service.getRoomGuestMembers('ROOM01');
      expect(guests.map((member) => member.id), ['guest_local']);

      const newGuest = RoomMember(
        id: 'guest-2',
        name: 'New guest',
        isGuest: true,
      );
      expect(
        await service.addRoomGuestMember('ROOM01', newGuest),
        same(newGuest),
      );
      final savedMembers = receipt['room_members'] as List;
      expect(savedMembers, hasLength(4));
      expect(savedMembers.last, {
        'id': 'guest-2',
        'name': 'New guest',
        'avatar_url': null,
        'is_guest': true,
      });
    },
  );
}
