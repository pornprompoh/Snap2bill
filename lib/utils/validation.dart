import '../models/bill_model.dart';

class BillValidation {
  static void validateAmount(double amount, {String field = 'amount'}) {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(
        amount,
        field,
        'Must be a non-negative number.',
      );
    }
  }

  static void validateQuantity(int quantity, {String field = 'quantity'}) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, field, 'Must be greater than zero.');
    }
  }

  static bool isClaimQuantityValid(BillItemModel item) {
    if (item.quantity <= 0 ||
        item.userQuantities.values.any((quantity) => quantity < 0)) {
      return false;
    }
    final personalQuantity = item.userQuantities.values.fold<int>(
      0,
      (total, quantity) => total + quantity,
    );
    return personalQuantity <= item.quantity;
  }

  static bool canEditBill({
    required String currentUserId,
    required String ownerId,
  }) => currentUserId.isNotEmpty && currentUserId == ownerId;

  static bool canChangeHost({
    required String currentUserId,
    required String ownerId,
  }) => canEditBill(currentUserId: currentUserId, ownerId: ownerId);
}
