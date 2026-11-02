import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/utils/claim_selection_validator.dart';

void main() {
  const items = [
    {'item_name': 'ข้าวผัด', 'qty': 2},
    {'item_name': 'ชาเย็น', 'qty': 1},
  ];

  test('blocks navigation when any item quantity is unassigned', () {
    expect(
      ClaimSelectionValidator.isComplete(
        items: items,
        claimedItems: {
          0: {'user-1': 1},
          1: {'user-1': 1},
        },
        sharedItems: const {},
      ),
      isFalse,
    );
  });

  test('allows navigation when all quantities are assigned personally', () {
    expect(
      ClaimSelectionValidator.isComplete(
        items: items,
        claimedItems: {
          0: {'user-1': 2},
          1: {'user-1': 1},
        },
        sharedItems: const {},
      ),
      isTrue,
    );
  });

  test('allows shared selection to cover remaining quantity', () {
    expect(
      ClaimSelectionValidator.isComplete(
        items: items,
        claimedItems: {
          0: {'user-1': 1},
          1: {'user-1': 1},
        },
        sharedItems: {
          0: {'user-1', 'user-2'},
        },
      ),
      isTrue,
    );
  });
}
