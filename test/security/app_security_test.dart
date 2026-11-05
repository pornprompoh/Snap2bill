import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/data/repositories/local_bill_repository.dart';
import 'package:snap2bill/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<List<File>> _dartFilesUnder(Directory directory) async {
  final files = <File>[];
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) files.add(entity);
  }
  return files;
}

void main() {
  final root = Directory.current;

  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await Supabase.initialize(
      url: 'https://app-security-test.supabase.co',
      publishableKey: 'app-security-test-key',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/auth/v1/user')) {
          return http.Response(
            jsonEncode({
              'id': 'signed-out-user',
              'aud': 'authenticated',
              'role': 'authenticated',
              'email': 'security@example.test',
            }),
            200,
            request: request,
            headers: const {'content-type': 'application/json'},
          );
        }
        return http.Response('', 204, request: request);
      }),
    );
  });

  test('lib contains no hardcoded secret-shaped credentials', () async {
    final libFiles = await _dartFilesUnder(Directory('${root.path}\\lib'));
    final secretPatterns = [
      RegExp(r'AIza[0-9A-Za-z_-]{30,}'),
      RegExp(r'sb_secret_[0-9A-Za-z_-]{16,}'),
      RegExp(r'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{8,}'),
      RegExp(
        r'''(?:SUPABASE_ANON_KEY|SUPABASE_SERVICE_ROLE_KEY|GEMINI_API_KEY)\s*[:=]\s*['"][^'"\r\n]{8,}['"]''',
        caseSensitive: false,
      ),
    ];

    final findings = <String>[];
    for (final file in libFiles) {
      final contents = await file.readAsString();
      for (final pattern in secretPatterns) {
        if (pattern.hasMatch(contents)) {
          findings.add(file.path);
          break;
        }
      }
    }

    expect(
      findings,
      isEmpty,
      reason: 'Potential credential literals: $findings',
    );
  });

  test(
    'required app configuration is environment-only and fails closed',
    () async {
      final bootstrap = await File(
        '${root.path}\\lib\\app\\app_bootstrap.dart',
      ).readAsString();
      final template = await File('${root.path}\\.env.example').readAsString();
      final gitignore = await File('${root.path}\\.gitignore').readAsString();

      expect(bootstrap, contains("dotenv.load(fileName: '.env')"));
      expect(bootstrap, contains("dotenv.env['SUPABASE_URL']!"));
      expect(bootstrap, contains("dotenv.env['SUPABASE_ANON_KEY']!"));
      expect(template, matches(RegExp(r'^SUPABASE_URL=\s*$', multiLine: true)));
      expect(
        template,
        matches(RegExp(r'^SUPABASE_ANON_KEY=\s*$', multiLine: true)),
      );
      expect(
        template,
        matches(RegExp(r'^GEMINI_API_KEY=\s*$', multiLine: true)),
      );
      expect(gitignore, contains('.env'));
      expect(gitignore, contains('.env*'));
    },
  );

  test(
    'offline bill retries retain the local id used by the idempotent RPC',
    () async {
      final offlineSource = await File(
        '${root.path}\\lib\\services\\offline\\offline_service.dart',
      ).readAsString();
      final idempotencyMigration = await File(
        '${root.path}\\supabase\\migrations\\20261105000000_support_idempotent_offline_bill_sync.sql',
      ).readAsString();

      expect(offlineSource, contains("'create_bill_with_participants'"));
      expect(offlineSource, contains("'p_bill': bill"));
      expect(offlineSource, contains("payload['local_id']?.toString()"));
      expect(idempotencyMigration, contains("requested_bill_id"));
      expect(
        idempotencyMigration,
        contains('IF existing_owner_id <> caller_id THEN'),
      );
      expect(idempotencyMigration, contains('RETURN requested_bill_id;'));
    },
  );

  test(
    'sign out clears the Supabase session and anonymous cache reads stay empty',
    () async {
      final authService = await File(
        '${root.path}\\lib\\services\\auth\\supabase_auth_service.dart',
      ).readAsString();
      expect(authService, contains('await _supabase.auth.signOut();'));

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none'})));
      final payload = base64Url.encode(
        utf8.encode(
          jsonEncode({
            'sub': 'signed-out-user',
            'aud': 'authenticated',
            'role': 'authenticated',
            'email': 'security@example.test',
            'iat': now,
            'exp': now + 3600,
          }),
        ),
      );
      await Supabase.instance.client.auth.setSession(
        'test-refresh-token',
        accessToken: '$header.$payload.${base64Url.encode(utf8.encode('sig'))}',
      );
      expect(Supabase.instance.client.auth.currentUser?.id, 'signed-out-user');
      await Supabase.instance.client.auth.signOut();
      expect(Supabase.instance.client.auth.currentUser, isNull);

      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = LocalBillRepository(db: database);
      await repository.saveLocalBill(
        bill: {
          'id': 'private-bill',
          'owner_id': 'signed-out-user',
          'receipt_json': <String, dynamic>{'items': <dynamic>[]},
        },
        participants: const [],
      );

      expect(await repository.getCachedBills(userId: ''), isEmpty);
      expect(
        await repository.getCachedBillData('private-bill'),
        isNotNull,
        reason:
            'Sign out clears auth state but currently leaves the SQLite row on disk.',
      );
    },
  );
}
