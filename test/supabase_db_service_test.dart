import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:snap2bill/services/data/supabase_db_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'past participants include real shared accounts and rank repeat friends',
    () async {
      final requestedProfileIds = <String>[];
      final client = SupabaseClient(
        'https://snap2bill-test.supabase.co',
        'test-anon-key',
        httpClient: MockClient((request) async {
          final table = request.url.pathSegments.last;
          final selection = request.url.queryParameters['select'];
          Object response;

          if (table == 'bill_participants' && selection == 'bill_id') {
            response = [
              {'bill_id': 'bill-1'},
              {'bill_id': 'bill-2'},
              {'bill_id': 'bill-2'},
              {'bill_id': null},
            ];
          } else if (table == 'bills' && selection == 'id') {
            response = [
              {'id': 'bill-owned'},
            ];
          } else if (table == 'bills') {
            response = [
              {
                'id': 'bill-1',
                'owner_id': 'owner-1',
                'created_at': '2026-10-01T10:00:00Z',
                'sharers_json': {
                  'rice': [
                    {'user_id': 'current-user'},
                    {'user_id': 'friend-repeat'},
                    {'user_id': 'guest_local'},
                    {'user_id': 'guest-remote'},
                    {'user_id': 'friend-recent'},
                    'invalid-sharer',
                    {'name': 'missing id'},
                  ],
                  'invalid': 'not a sharer list',
                },
              },
              {
                'id': 'bill-2',
                'owner_id': 'owner-2',
                'created_at': 'invalid-date',
                'sharers_json': {
                  'drink': [
                    {'user_id': 'current-user'},
                    {'user_id': 'friend-repeat'},
                  ],
                },
              },
              {
                'id': 'bill-owned',
                'owner_id': 'current-user',
                'created_at': '2026-10-03T10:00:00Z',
                'sharers_json': null,
              },
              {
                'id': null,
                'owner_id': 'current-user',
                'created_at': '2026-10-04T10:00:00Z',
              },
            ];
          } else if (table == 'bill_participants' &&
              selection == 'bill_id,profile_id') {
            response = [
              {'bill_id': 'bill-1', 'profile_id': 'current-user'},
              {'bill_id': 'bill-1', 'profile_id': 'friend-recent'},
              {'bill_id': 'bill-1', 'profile_id': 'guest_UPPER'},
              {'bill_id': 'bill-1', 'profile_id': ''},
              {'bill_id': null, 'profile_id': 'missing-bill'},
              {'bill_id': 'bill-2', 'profile_id': 'current-user'},
              {'bill_id': 'bill-2', 'profile_id': 'friend-repeat'},
              {'bill_id': 'bill-outside', 'profile_id': 'not-in-bill-list'},
            ];
          } else if (table == 'profiles') {
            requestedProfileIds.addAll(
              (request.url.queryParameters['id'] ?? '')
                  .replaceAll('in.(', '')
                  .replaceAll(')', '')
                  .replaceAll('"', '')
                  .split(','),
            );
            response = [
              {
                'id': 'friend-repeat',
                'display_name': 'เพื่อนหารบ่อย',
                'email': 'repeat@example.com',
              },
              {
                'id': 'friend-recent',
                'display_name': 'เพื่อนบิลล่าสุด',
                'email': 'recent@example.com',
              },
              {'id': 'guest_UPPER', 'display_name': 'Guest should be filtered'},
              {
                'id': 'current-user',
                'display_name': 'Current user should be filtered',
              },
            ];
          } else {
            return http.Response(
              'Unexpected request: ${request.url}',
              404,
              request: request,
            );
          }

          return http.Response.bytes(
            utf8.encode(jsonEncode(response)),
            200,
            request: request,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(client.dispose);

      final friends = await SupabaseDbService(
        client: client,
      ).getPastParticipants('current-user');

      expect(friends.map((friend) => friend.id).toList(), [
        'friend-repeat',
        'friend-recent',
      ]);
      expect(requestedProfileIds, contains('friend-repeat'));
      expect(requestedProfileIds, contains('friend-recent'));
      expect(requestedProfileIds, isNot(contains('guest_local')));
      expect(requestedProfileIds, isNot(contains('guest-remote')));
      expect(requestedProfileIds, isNot(contains('guest_UPPER')));
    },
  );

  test(
    'past participants returns empty when user has no bill history',
    () async {
      final client = SupabaseClient(
        'https://snap2bill-empty-test.supabase.co',
        'test-anon-key',
        httpClient: MockClient((request) async {
          return http.Response('[]', 200, request: request);
        }),
      );
      addTearDown(client.dispose);

      expect(
        await SupabaseDbService(client: client).getPastParticipants('new-user'),
        isEmpty,
      );
    },
  );
}
