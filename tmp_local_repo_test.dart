import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/data/repositories/local_bill_repository.dart';

void main() {
  test('save local bill minimal', () async {
    print('before');
    final repo = LocalBillRepository();
    await repo.saveLocalBill(
      bill: {
        'id': 'bill-1',
        'owner_id': 'user-1',
        'shop_name': 'Cafe Aroma',
        'created_at': '2026-11-05T10:00:00Z',
        'status': 'completed',
        'total_amount': 200,
      },
      participants: [
        {'profile_id': 'user-1', 'status': 'paid', 'amount_owed': 0},
        {'profile_id': 'friend-1', 'status': 'paid', 'amount_owed': 200},
      ],
    );
    print('after');
  });
}
