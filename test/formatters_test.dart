import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:snap2bill/utils/formatters.dart';

void main() {
  setUpAll(initializeDateFormatting);

  group('AppFormatters.formatCurrency', () {
    test('formats whole, decimal, zero, and negative amounts', () {
      expect(AppFormatters.formatCurrency(1234), '1,234.00 ฿');
      expect(AppFormatters.formatCurrency(12.5), '12.50 ฿');
      expect(AppFormatters.formatCurrency(0), '0.00 ฿');
      expect(AppFormatters.formatCurrency(-42.75), '-42.75 ฿');
    });
  });

  test('formats date and time consistently', () {
    final value = DateTime(2025, 1, 2, 13, 4);
    expect(AppFormatters.formatDateTime(value), contains('02'));
    expect(AppFormatters.formatDateTime(value), contains('13:04'));
  });
}
