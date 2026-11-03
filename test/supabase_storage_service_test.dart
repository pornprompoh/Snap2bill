import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snap2bill/services/storage/supabase_storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
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
}

http.Response httpResponse(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);
