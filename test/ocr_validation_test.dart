import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/services/media/ocr_service.dart';

void main() {
  test(
    'normalizes legacy item fields and keeps unreconciled totals visible',
    () {
      final normalized = OcrService.validateAndNormalizeReceipt({
        'shop_name': ' Cafe ',
        'service_charge': '10',
        'vat_amount': '7',
        'discount': '5',
        'total_amount': '120',
        'items': [
          null,
          {'name': '  Latte ', 'price': '50', 'quantity': '2'},
          {
            'item_name': 'Tea',
            'unit_price': '20',
            'qty': '-1',
            'total_price': '30',
          },
        ],
      });

      expect(normalized['sub_total'], 130.0);
      expect(normalized['final_total'], 120.0);
      expect(normalized['total_amount'], 120.0);
      expect(normalized['is_vat_included'], isFalse);
      expect(normalized['vat_amount'], 7.0);
      expect(normalized['calculated_total'], 142.0);
      expect(normalized['receipt_difference'], -22.0);
      expect(normalized['totals_reconciled'], isFalse);
      final items = normalized['items'] as List<Map<String, dynamic>>;
      expect(items[0]['item_name'], 'Latte');
      expect(items[0]['qty'], 2);
      expect(items[0]['quantity'], 2);
      expect(items[1]['qty'], 1);
      expect(items[1]['quantity'], 1);
      expect(normalized['shop_name'], ' Cafe ');
    },
  );

  test('recognizes VAT-included totals and normalizes zero VAT', () {
    final normalized = OcrService.validateAndNormalizeReceipt({
      'is_vat_included': true,
      'vat_amount': 20,
      'final_total': 100,
      'items': [
        {'item_name': 'Rice', 'unit_price': 100},
      ],
    });

    expect(normalized['is_vat_included'], isTrue);
    expect(normalized['vat_amount'], 0.0);
    expect(normalized['calculated_total'], 100.0);
    expect(normalized['totals_reconciled'], isTrue);
  });

  test(
    'rejects invalid item lists, empty payable items and missing totals',
    () {
      expect(
        () => OcrService.validateAndNormalizeReceipt({
          'items': 'not a list',
          'final_total': 100,
        }),
        throwsFormatException,
      );
      expect(
        () => OcrService.validateAndNormalizeReceipt({
          'items': [
            {'item_name': 'Free', 'unit_price': 0},
            {'item_name': '  ', 'unit_price': 20},
            'not an item',
          ],
          'final_total': 100,
        }),
        throwsFormatException,
      );
      expect(
        () => OcrService.validateAndNormalizeReceipt({
          'items': [
            {'item_name': 'Meal', 'unit_price': 20},
          ],
        }),
        throwsFormatException,
      );
    },
  );

  test(
    'filters unusable rows and applies legacy quantity and total defaults',
    () {
      final normalized = OcrService.validateAndNormalizeReceipt({
        'shop_name': null,
        'service_charge': 'bad number',
        'discount': null,
        'sub_total': 999,
        'final_total': '15',
        'items': [
          {'name': 'Free item', 'price': 0, 'qty': 1},
          {'name': 'No price', 'qty': 2},
          {
            'name': '  Noodles  ',
            'price': '5',
            'qty': 'bad',
            'total_price': null,
          },
          {'name': 'Tea', 'price': 10, 'quantity': 1, 'total_price': '10'},
          {'name': 'Bad map value', 'price': 1},
        ],
      });

      final items = normalized['items'] as List<Map<String, dynamic>>;
      expect(items, hasLength(3));
      expect(items[0]['item_name'], 'Noodles');
      expect(items[0]['qty'], 1);
      expect(items[0]['total_price'], 5.0);
      expect(items[1]['qty'], 1);
      expect(items[2]['qty'], 1);
      expect(normalized['shop_name'], isNull);
      expect(normalized['service_charge'], 'bad number');
      expect(normalized['sub_total'], 16.0);
      expect(normalized['is_vat_included'], isFalse);
      expect(normalized['vat_amount'], 0.0);
      expect(normalized['totals_reconciled'], isFalse);
    },
  );

  test(
    'infers VAT inclusion when item and service totals equal final total',
    () {
      final normalized = OcrService.validateAndNormalizeReceipt({
        'vat_amount': 7,
        'service_charge': 2,
        'discount': 1,
        'total_amount': 11,
        'items': [
          {'name': 'Coffee', 'price': 10},
        ],
      });

      expect(normalized['is_vat_included'], isTrue);
      expect(normalized['vat_amount'], 0.0);
      expect(normalized['calculated_total'], 11.0);
      expect(normalized['receipt_difference'], 0.0);
      expect(normalized['totals_reconciled'], isTrue);
    },
  );
}
