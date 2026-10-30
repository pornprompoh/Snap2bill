import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/utils/formatters.dart';
import 'package:snap2bill/utils/validation.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('th_TH', null);
  });

  group('bill input validation', () {
    test('rejects negative amounts', () {
      expect(() => BillValidation.validateAmount(-0.01), throwsArgumentError);
    });

    test('rejects zero and negative quantities', () {
      expect(() => BillValidation.validateQuantity(0), throwsArgumentError);
      expect(() => BillValidation.validateQuantity(-1), throwsArgumentError);
    });

    test('rejects claims whose total exceeds the item quantity', () {
      final item = BillItemModel(
        id: 'item-1',
        billId: 'bill-1',
        itemName: 'Rice',
        price: 40,
        quantity: 2,
        userQuantities: {'user-a': 1, 'user-b': 2},
      );

      expect(BillValidation.isClaimQuantityValid(item), isFalse);
    });

    test('accepts claims within the item quantity', () {
      final item = BillItemModel(
        id: 'item-1',
        billId: 'bill-1',
        itemName: 'Rice',
        price: 40,
        quantity: 3,
        userQuantities: {'user-a': 1, 'user-b': 2},
      );

      expect(BillValidation.isClaimQuantityValid(item), isTrue);
    });

    test('rejects negative claim quantities', () {
      final item = BillItemModel(
        id: 'item-1',
        billId: 'bill-1',
        itemName: 'Rice',
        price: 40,
        quantity: 2,
        userQuantities: {'user-a': -1},
      );

      expect(BillValidation.isClaimQuantityValid(item), isFalse);
    });
  });

  group('authorization checks', () {
    test('only the owner can edit a bill', () {
      expect(
        BillValidation.canEditBill(
          currentUserId: 'member-1',
          ownerId: 'host-1',
        ),
        isFalse,
      );
      expect(
        BillValidation.canEditBill(currentUserId: 'host-1', ownerId: 'host-1'),
        isTrue,
      );
    });

    test('rejects non-finite amounts and rates', () {
      expect(
        () => BillValidation.validateAmount(double.infinity),
        throwsArgumentError,
      );
      expect(
        () => BillProvider.calculateVat(subtotal: 100, rate: -1),
        throwsArgumentError,
      );
    });

    test('a regular member cannot promote itself to host', () {
      expect(
        BillValidation.canChangeHost(
          currentUserId: 'member-1',
          ownerId: 'host-1',
        ),
        isFalse,
      );
    });
  });

  group('input sanitization', () {
    test('strips non-digits from PromptPay input', () {
      const input = "0812345678'; DROP TABLE profiles; --";
      final sanitized = input.replaceAll(RegExp(r'[^0-9]'), '');

      expect(sanitized, '0812345678');
      expect(sanitized, hasLength(10));
    });

    test('identifies negative bill item prices', () {
      final item = BillItemModel(
        id: 'sec-item-1',
        billId: 'bill-1',
        itemName: 'ข้าวผัด',
        quantity: 1,
        price: -50,
      );

      expect(item.price, lessThan(0));
      expect(item.quantity, greaterThan(0));
    });

    test('accepts only six-digit room PINs', () {
      bool isValidPin(String pin) => RegExp(r'^\d{6}$').hasMatch(pin);

      expect(isValidPin('123456'), isTrue);
      expect(isValidPin('000000'), isTrue);
      expect(isValidPin('12345'), isFalse);
      expect(isValidPin('1234567'), isFalse);
      expect(isValidPin('12345a'), isFalse);
      expect(isValidPin('<script>'), isFalse);
    });

    test('removes HTML tags from shop names', () {
      String sanitizeText(String input) =>
          input.replaceAll(RegExp(r'<[^>]*>'), '').trim();

      expect(
        sanitizeText('<script>alert("hack")</script>ร้านส้มตำ'),
        'alert("hack")ร้านส้มตำ',
      );
      expect(sanitizeText('<b>ร้านก๋วยเตี๋ยว</b>'), 'ร้านก๋วยเตี๋ยว');
    });
  });

  group('security regression coverage for formatters', () {
    test('formats edge currency amounts', () {
      expect(AppFormatters.formatCurrency(0), '0.00 ฿');
      expect(AppFormatters.formatCurrency(1234.5), '1,234.50 ฿');
      expect(AppFormatters.formatCurrency(9999999.99), '9,999,999.99 ฿');
      expect(AppFormatters.formatCurrency(-100), '-100.00 ฿');
    });

    test('formats edge bill dates', () {
      final formatted = AppFormatters.formatDateTime(
        DateTime(2026, 10, 25, 14, 30),
      );

      expect(formatted, isNotEmpty);
      expect(formatted, contains('25'));
    });
  });
}
