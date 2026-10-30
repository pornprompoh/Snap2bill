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
    'lib/database/',
    // Supabase-backed adapter; its contract is covered separately without
    // counting network plumbing in the deterministic core-logic percentage.
    'lib/providers/contact_provider.dart',
    'lib/services/ocr_service.dart',
    'lib/services/qr_image_saver',
    'lib/services/receipt_share_service.dart',
    'lib/services/supabase_',
  ];
  return path.endsWith('.g.dart') ||
      excludedPrefixes.any(
        (prefix) => path == prefix || path.startsWith(prefix),
      );
}
