import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snap2bill/providers/contact_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef RequestHandler = Future<http.Response> Function(http.Request request);

Future<SupabaseClient> _authenticatedClient(RequestHandler handler) async {
  final client = SupabaseClient(
    'https://contacts-test.supabase.co',
    'test-anon-key',
    httpClient: MockClient(handler),
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
  final signature = base64Url.encode(utf8.encode('test-signature'));
  final token = '$header.$payload.$signature';
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

Map<String, dynamic> _contact(String id, String name) => {
  'id': id,
  'user_id': 'user-1',
  'name': name,
  'note': null,
  'created_at': '2026-11-01T10:00:00Z',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'loads, deduplicates, saves, sorts and deletes saved contacts',
    () async {
      final rows = <Map<String, dynamic>>[
        _contact('contact-b', 'Bee'),
        _contact('contact-a', 'Amy'),
      ];
      var insertCount = 0;
      late final SupabaseClient client;
      client = await _authenticatedClient((request) async {
        if (request.url.path.endsWith('/auth/v1/user')) {
          return _jsonResponse(request, {
            'id': 'user-1',
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'user@example.com',
          });
        }

        if (request.url.path.endsWith('/rest/v1/saved_contacts')) {
          if (request.method == 'GET') {
            return _jsonResponse(request, rows);
          }
          if (request.method == 'POST') {
            insertCount++;
            final inserted = _contact('contact-c', 'Cara');
            rows.add(inserted);
            return _jsonResponse(request, inserted);
          }
          if (request.method == 'DELETE') {
            final id = request.url.queryParameters['id']?.replaceFirst(
              'eq.',
              '',
            );
            final found = rows.where((row) => row['id'] == id).toList();
            rows.removeWhere((row) => row['id'] == id);
            return _jsonResponse(
              request,
              found.map((row) => {'id': row['id']}).toList(),
            );
          }
        }
        return _jsonResponse(request, {
          'message': 'unexpected request',
        }, status: 404);
      });
      addTearDown(client.dispose);

      final provider = ContactProvider(client: client);
      await provider.loadContacts();
      expect(provider.contacts.map((contact) => contact.name), ['Bee', 'Amy']);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);

      await provider.saveContactIfNotExists('  aMY  ');
      expect(insertCount, 0);

      await provider.saveContactIfNotExists('Cara');
      expect(insertCount, 1);
      expect(provider.contacts.map((contact) => contact.name).toList(), [
        'Amy',
        'Bee',
        'Cara',
      ]);

      await provider.deleteContact('contact-b');
      expect(provider.contacts.map((contact) => contact.name), ['Amy', 'Cara']);
      await expectLater(
        provider.deleteContact('not-found'),
        throwsA(isA<StateError>()),
      );
      expect(provider.contacts.map((contact) => contact.name), ['Amy', 'Cara']);
    },
  );

  test(
    'reports load failures and rejects invalid or blank contact names',
    () async {
      final client = await _authenticatedClient((request) async {
        if (request.url.path.endsWith('/auth/v1/user')) {
          return _jsonResponse(request, {
            'id': 'user-1',
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'user@example.com',
          });
        }
        if (request.method == 'DELETE') {
          return _jsonResponse(request, []);
        }
        return _jsonResponse(request, {
          'message': 'server unavailable',
        }, status: 500);
      });
      addTearDown(client.dispose);

      final provider = ContactProvider(client: client);
      await provider.loadContacts();
      expect(provider.error, contains('โหลดรายชื่อเพื่อนไม่สำเร็จ'));
      expect(provider.isLoading, isFalse);

      await expectLater(
        provider.saveContactIfNotExists('  '),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        provider.deleteContact('contact-1'),
        throwsA(isA<StateError>()),
      );
    },
  );
}
