import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snap2bill/services/storage/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'uploads compressed images into the authenticated user folder',
    () async {
      final pngBytes = Uint8List.fromList(
        img.encodePng(img.Image(width: 4, height: 4)),
      );
      final client = await _authenticatedClient((request) async {
        if (request.url.path.endsWith('/auth/v1/user')) {
          return http.Response(
            jsonEncode({
              'id': 'user-1',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'user@example.test',
            }),
            200,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }
        expect(request.method, 'POST');
        expect(request.url.pathSegments, [
          'storage',
          'v1',
          'object',
          'receipts',
          'user-1',
          'room-1',
          'receipt.jpg',
        ]);
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        expect(
          utf8.decode(request.bodyBytes, allowMalformed: true),
          contains('image/jpeg'),
        );
        expect(request.bodyBytes, isNotEmpty);
        return http.Response(
          jsonEncode({'Key': 'receipts/user-1/room-1/receipt.jpg'}),
          200,
          request: request,
          headers: const {'content-type': 'application/json'},
        );
      });
      addTearDown(client.dispose);

      final service = SupabaseStorageService(client: client);
      final result = await service.uploadReceiptBytes(
        pngBytes,
        'room-1',
        fileName: 'receipt.jpg',
      );

      expect(
        result,
        'https://snap2bill-test.supabase.co/storage/v1/object/public/'
        'receipts/user-1/room-1/receipt.jpg',
      );
    },
  );

  test(
    'rejects unauthenticated uploads and unsafe object path segments',
    () async {
      final client = SupabaseClient(
        'https://snap2bill-test.supabase.co',
        'test-anon-key',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/auth/v1/user')) {
            return httpResponse({
              'id': 'user-1',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'user@example.test',
            });
          }
          fail('Invalid uploads must not reach Storage.');
        }),
      );
      addTearDown(client.dispose);

      final service = SupabaseStorageService(client: client);
      await expectLater(
        service.uploadReceiptBytes(Uint8List(0), 'room-1'),
        throwsA(isA<StateError>()),
      );

      await _setTestSession(client);
      for (final invalid in ['.', '..', 'room/1', r'room\1', '']) {
        await expectLater(
          service.uploadReceiptBytes(Uint8List(0), invalid),
          throwsA(isA<ArgumentError>()),
        );
      }
      await expectLater(
        service.uploadReceiptBytes(
          Uint8List(0),
          'room-1',
          fileName: '../file.jpg',
        ),
        throwsA(isA<ArgumentError>()),
      );
    },
  );

  test('compresses valid images and rejects malformed image bytes', () async {
    final client = SupabaseClient(
      'https://snap2bill-test.supabase.co',
      'test-anon-key',
    );
    addTearDown(client.dispose);
    final service = SupabaseStorageService(client: client);
    final pngBytes = Uint8List.fromList(
      img.encodePng(img.Image(width: 3, height: 2)),
    );

    final compressed = await service.compressImageBytes(pngBytes);
    expect(img.decodeImage(compressed), isNotNull);
    await expectLater(
      service.compressImageBytes(
        Uint8List.fromList(utf8.encode('not an image')),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'signs legacy receipt URLs with the bucket-relative object path',
    () async {
      final client = SupabaseClient(
        'https://snap2bill-test.supabase.co',
        'test-anon-key',
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.pathSegments, [
            'storage',
            'v1',
            'object',
            'sign',
            'receipts',
            'receipts',
            '303795',
            '1790784098581.jpg',
          ]);
          return httpResponse({
            'signedURL':
                '/object/sign/receipts/receipts/303795/'
                '1790784098581.jpg?token=test',
          });
        }),
      );
      addTearDown(client.dispose);

      final resolvedUrl = await SupabaseStorageService(client: client)
          .resolveReceiptImageUrl(
            'https://snap2bill-test.supabase.co/storage/v1/object/public/'
            'receipts/receipts/303795/1790784098581.jpg',
          );

      expect(
        resolvedUrl,
        'https://snap2bill-test.supabase.co/storage/v1/object/sign/'
        'receipts/receipts/303795/1790784098581.jpg?token=test',
      );
    },
  );

  test('signs current receipt URLs with the user folder path', () async {
    final client = SupabaseClient(
      'https://snap2bill-test.supabase.co',
      'test-anon-key',
      httpClient: MockClient((request) async {
        expect(request.url.pathSegments, [
          'storage',
          'v1',
          'object',
          'sign',
          'receipts',
          'user-1',
          'room-1',
          'receipt.jpg',
        ]);
        return httpResponse({
          'signedURL': '/object/sign/receipts/user-1/room-1/receipt.jpg',
        });
      }),
    );
    addTearDown(client.dispose);

    final resolvedUrl = await SupabaseStorageService(client: client)
        .resolveReceiptImageUrl(
          'https://snap2bill-test.supabase.co/storage/v1/object/public/'
          'receipts/user-1/room-1/receipt.jpg',
        );

    expect(
      resolvedUrl,
      'https://snap2bill-test.supabase.co/storage/v1/object/sign/'
      'receipts/user-1/room-1/receipt.jpg',
    );
  });

  test('leaves non-Supabase storage image URLs unchanged', () async {
    final client = SupabaseClient(
      'https://snap2bill-test.supabase.co',
      'test-anon-key',
      httpClient: MockClient((_) async {
        fail('No storage request should be made for an external URL.');
      }),
    );
    addTearDown(client.dispose);

    const externalUrl = 'https://images.example.com/receipt.jpg';
    final resolvedUrl = await SupabaseStorageService(
      client: client,
    ).resolveReceiptImageUrl(externalUrl);

    expect(resolvedUrl, externalUrl);
  });

  test(
    'rejects malformed receipt URLs and preserves unrelated storage objects',
    () async {
      final client = SupabaseClient(
        'https://snap2bill-test.supabase.co',
        'test-anon-key',
        httpClient: MockClient((_) async {
          fail('No request should be made for an unrelated storage URL.');
        }),
      );
      addTearDown(client.dispose);
      final service = SupabaseStorageService(client: client);

      for (final invalid in ['', 'not a URL', '/relative/path']) {
        await expectLater(
          service.resolveReceiptImageUrl(invalid),
          throwsA(isA<FormatException>()),
        );
      }
      expect(
        await service.resolveReceiptImageUrl(
          'https://snap2bill-test.supabase.co/storage/v1/object/public/avatars/u.png',
        ),
        'https://snap2bill-test.supabase.co/storage/v1/object/public/avatars/u.png',
      );
      await expectLater(
        service.resolveReceiptImageUrl(
          'https://snap2bill-test.supabase.co/storage/v1/object/public/receipts/',
        ),
        throwsA(isA<FormatException>()),
      );
    },
  );
}

typedef _RequestHandler = Future<http.Response> Function(http.Request request);

Future<SupabaseClient> _authenticatedClient(_RequestHandler handler) async {
  final client = SupabaseClient(
    'https://snap2bill-test.supabase.co',
    'test-anon-key',
    httpClient: MockClient(handler),
  );
  await _setTestSession(client);
  return client;
}

Future<void> _setTestSession(SupabaseClient client) async {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': 'user-1',
        'aud': 'authenticated',
        'role': 'authenticated',
        'email': 'user@example.test',
        'iat': now,
        'exp': now + 3600,
      }),
    ),
  );
  await client.auth.setSession(
    'test-refresh-token',
    accessToken: '$header.$payload.${base64Url.encode(utf8.encode('sig'))}',
  );
}

http.Response httpResponse(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);
