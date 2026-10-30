import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:snap2bill/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('th_TH', null);
  });

  group('formatCurrency', () {
    test('formats zero and whole currency amounts to two decimals', () {
      expect(AppFormatters.formatCurrency(0), '0.00 ฿');
      expect(AppFormatters.formatCurrency(25), '25.00 ฿');
    });

    test('formats decimals and adds grouping separators', () {
      expect(AppFormatters.formatCurrency(1234.5), '1,234.50 ฿');
      expect(AppFormatters.formatCurrency(9999999.99), '9,999,999.99 ฿');
    });

    test('rounds fractional amounts and preserves negative values', () {
      expect(AppFormatters.formatCurrency(12.345), '12.35 ฿');
      expect(AppFormatters.formatCurrency(-100), '-100.00 ฿');
    });
  });

  group('formatDateTime', () {
    test('formats date and time using Thai locale conventions', () {
      expect(
        AppFormatters.formatDateTime(DateTime(2026, 1, 2, 3, 4)),
        '02 ม.ค. 2026 03:04',
      );
    });

    test('pads single-digit day, month, hour, and minute values', () {
      expect(
        AppFormatters.formatDateTime(DateTime(2026, 9, 8, 7, 6)),
        '08 ก.ย. 2026 07:06',
      );
    });
  });
}
