import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/utils/validation.dart';

void main() {
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
}
