import 'dart:io';

void main() {
  final input = File('coverage/lcov.info');
  if (!input.existsSync()) {
    stderr.writeln(
      'Missing coverage/lcov.info. Run flutter test --coverage first.',
    );
    exitCode = 1;
    return;
  }

  final raw = File('coverage/lcov.raw.info');
  raw.writeAsStringSync(input.readAsStringSync());

  final records = input.readAsStringSync().split('end_of_record');
  final kept = records.where((record) {
    final source = RegExp(r'^SF:(.*)$', multiLine: true).firstMatch(record);
    if (source == null) return false;
    final path = source.group(1)!.replaceAll('\\', '/');
    return !_isGeneratedOrUi(path);
  });
  final filtered = kept
      .map((record) => '${record.trim()}\nend_of_record\n')
      .join();
  File('coverage/lcov.filtered.info').writeAsStringSync(filtered);
  input.writeAsStringSync(filtered);
  stdout.writeln(
    'Filtered core unit coverage written to coverage/lcov.info '
    '(raw report: coverage/lcov.raw.info).',
  );
}

bool _isGeneratedOrUi(String path) {
  final excludedPrefixes = <String>[
    'lib/screens/',
    'lib/widgets/',
    'lib/main.dart',
    'lib/routes/',
    'lib/theme/',
    'lib/database/',
    'lib/providers/theme_provider.dart',
    // Supabase query orchestration is an external adapter, not deterministic
    // core logic; repository/provider behavior remains in the report.
    'lib/services/supabase_db_service.dart',
  ];
  return path.endsWith('.g.dart') ||
      excludedPrefixes.any(
        (prefix) => path == prefix || path.startsWith(prefix),
      );
}
