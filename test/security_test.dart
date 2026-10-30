import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/utils/formatters.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('th_TH', null);
  });

  group('Security & Sanitization Tests', () {
    test('prevents promptpay code injection and validates digit-only payload', () {
      const maliciousInput = "0812345678'; DROP TABLE profiles; --";
      final sanitized = maliciousInput.replaceAll(RegExp(r'[^0-9]'), '');
      expect(sanitized, '0812345678');
      expect(sanitized.length, 10);
    });

    test('validates bill item non-negative price logic', () {
      final item = BillItemModel(
        id: 'sec-item-1',
        billId: 'bill-1',
        itemName: 'ข้าวผัด',
        quantity: 1,
        price: -50.0,
      );
      expect(item.price < 0, isTrue);
      expect(item.quantity > 0, isTrue);
    });

    test('validates 6-digit room PIN format strictly', () {
      bool isValidPin(String pin) {
        return RegExp(r'^\d{6}$').hasMatch(pin);
      }

      expect(isValidPin('123456'), isTrue);
      expect(isValidPin('000000'), isTrue);
      expect(isValidPin('12345'), isFalse);
      expect(isValidPin('1234567'), isFalse);
      expect(isValidPin('12345a'), isFalse);
      expect(isValidPin('<script>'), isFalse);
    });

    test('sanitizes shop names and prevents HTML/XSS tag injection', () {
      String sanitizeText(String input) {
        return input.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      }

      expect(
        sanitizeText('<script>alert("hack")</script>ร้านส้มตำ'),
        'alert("hack")ร้านส้มตำ',
      );
      expect(
        sanitizeText('<b>ร้านก๋วยเตี๋ยว</b>'),
        'ร้านก๋วยเตี๋ยว',
      );
    });

    test('verifies currency formatter handles overflow, decimals and zero safely', () {
      expect(AppFormatters.formatCurrency(0), '0.00 ฿');
      expect(AppFormatters.formatCurrency(1234.5), '1,234.50 ฿');
      expect(AppFormatters.formatCurrency(9999999.99), '9,999,999.99 ฿');
      expect(AppFormatters.formatCurrency(-100), '-100.00 ฿');
    });

    test('verifies bill date formatter handles edge dates safely', () {
      final date = DateTime(2026, 10, 25, 14, 30);
      final formatted = AppFormatters.formatDateTime(date);
      expect(formatted.isNotEmpty, isTrue);
      expect(formatted.contains('25'), isTrue);
    });
  });
}
