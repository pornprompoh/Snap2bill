import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef _Policy = ({
  String name,
  String table,
  String action,
  String roles,
  String body,
});

Future<String> _readMigrations(Directory root) async {
  final directory = Directory('${root.path}\\supabase\\migrations');
  final contents = <String>[];
  await for (final entity in directory.list()) {
    if (entity is File && entity.path.endsWith('.sql')) {
      contents.add(await entity.readAsString());
    }
  }
  return contents.join('\n');
}

List<_Policy> _parsePolicies(String sql) {
  final expression = RegExp(
    r'CREATE\s+POLICY\s+(\w+)\s+ON\s+([\w.]+)\s+FOR\s+(SELECT|INSERT|UPDATE|DELETE)\s+TO\s+([a-z_, ]+?)(?=\s+(?:USING|WITH\s+CHECK)\s*\()([\s\S]*?);',
    caseSensitive: false,
  );
  return expression.allMatches(sql).map((match) {
    return (
      name: match.group(1)!.toLowerCase(),
      table: match.group(2)!.toLowerCase(),
      action: match.group(3)!.toUpperCase(),
      roles: match.group(4)!.toLowerCase().trim(),
      body: match.group(5)!.toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
    );
  }).toList();
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

void main() {
  final root = Directory.current;

  late String migrations;
  late List<_Policy> policies;

  setUpAll(() async {
    migrations = await _readMigrations(root);
    policies = _parsePolicies(migrations);
  });

  test('RLS is enabled on bills, bill_participants, and profiles', () {
    expect(policies, hasLength(15));
    for (final table in ['bills', 'bill_participants', 'profiles']) {
      expect(
        migrations.toLowerCase(),
        contains('alter table public.$table enable row level security;'),
      );
    }
  });

  test('bill SELECT is limited to owners and participants', () {
    final policy = policies.singleWhere(
      (policy) => policy.table == 'public.bills' && policy.action == 'SELECT',
    );

    expect(policy.roles, 'authenticated');
    expect(policy.body, contains('private.can_access_bill(id)'));
    expect(migrations, contains('b.owner_id = (SELECT auth.uid())'));
    expect(migrations, contains('bp.profile_id = (SELECT auth.uid())'));
  });

  test('bill writes are owner-only for INSERT, UPDATE, and DELETE', () {
    final billWrites = policies
        .where(
          (policy) =>
              policy.table == 'public.bills' && policy.action != 'SELECT',
        )
        .toList();

    expect(billWrites.map((policy) => policy.action).toSet(), {
      'INSERT',
      'UPDATE',
      'DELETE',
    });
    expect(
      billWrites.every((policy) => policy.roles == 'authenticated'),
      isTrue,
    );
    expect(
      billWrites.every(
        (policy) =>
            policy.body.contains('owner_id = (select auth.uid())') ||
            policy.body.contains('private.owns_bill'),
      ),
      isTrue,
    );
  });

  test(
    'participant reads follow bill access and mutations require ownership',
    () {
      final participantPolicies = policies
          .where((policy) => policy.table == 'public.bill_participants')
          .toList();

      expect(participantPolicies.map((policy) => policy.action).toSet(), {
        'SELECT',
        'INSERT',
        'UPDATE',
        'DELETE',
      });
      expect(
        participantPolicies
            .singleWhere((policy) => policy.action == 'SELECT')
            .body,
        contains('private.can_access_bill(bill_id)'),
      );
      for (final policy in participantPolicies.where(
        (policy) => policy.action != 'SELECT',
      )) {
        expect(policy.roles, 'authenticated');
        expect(policy.body, contains('private.owns_bill(bill_id)'));
      }
    },
  );

  test('profiles are visible only to self or related bill members', () {
    final profilePolicies = policies
        .where((policy) => policy.table == 'public.profiles')
        .toList();

    expect(profilePolicies.map((policy) => policy.action).toSet(), {
      'SELECT',
      'INSERT',
      'UPDATE',
    });
    expect(
      profilePolicies.singleWhere((policy) => policy.action == 'SELECT').body,
      contains('private.can_view_bill_profile(id)'),
    );
    expect(migrations, contains('CREATE POLICY profiles_insert_self'));
    expect(migrations, contains('CREATE POLICY profiles_update_self'));
    expect(
      profilePolicies
          .where((policy) => policy.action != 'SELECT')
          .every((policy) => policy.body.contains('id = (select auth.uid())')),
      isTrue,
    );
  });

  test(
    'bill_items and item_claims have no schema or policy in repository migrations',
    () {
      for (final absentTable in ['bill_items', 'item_claims']) {
        expect(
          migrations,
          isNot(contains('public.$absentTable')),
          reason:
              '$absentTable is not defined in repository migrations, so its live RLS cannot be verified here.',
        );
        expect(
          policies.any((policy) => policy.table == 'public.$absentTable'),
          isFalse,
        );
      }
    },
  );

  test(
    'receipt Storage access rules are restricted by bucket and user',
    () async {
      final readme = await File('${root.path}\\README.md').readAsString();
      final normalized = _normalize(readme);

      expect(
        RegExp(
          r'\*\*(SELECT|INSERT|UPDATE|DELETE)\*\* —',
          caseSensitive: false,
        ).allMatches(normalized),
        hasLength(4),
      );
      expect(
        normalized,
        contains(
          _normalize(
            "bucket_id = 'receipts' AND private.can_read_receipt_object(name)",
          ),
        ),
      );
      expect(
        normalized,
        contains(
          _normalize(
            "bucket_id = 'receipts' AND split_part(name, '/', 1) = (SELECT auth.uid())::text",
          ),
        ),
      );
      expect(normalized, contains('**update** — expression เดียวกับ insert'));
      expect(normalized, contains('**delete** — expression เดียวกับ insert'));
      expect(
        migrations,
        contains('split_part(p_name, \'/\', 1) = (SELECT auth.uid())::text'),
      );
    },
  );

  test(
    'offline bill creation rejects cross-owner id reuse and returns same-owner id',
    () {
      final sql = _normalize(migrations);

      expect(sql, contains('if existing_owner_id <> caller_id then'));
      expect(sql, contains("raise exception 'bill id is already in use'"));
      expect(sql, contains('return requested_bill_id;'));
      expect(sql, contains('if caller_id is null then'));
    },
  );

  test('migration policies grant no anonymous table access', () {
    expect(policies, isNotEmpty);
    expect(
      policies.every(
        (policy) =>
            policy.roles
                .split(',')
                .map((role) => role.trim())
                .contains('authenticated') &&
            !policy.roles.contains('anon') &&
            !policy.roles.contains('public'),
      ),
      isTrue,
    );
  });
}
