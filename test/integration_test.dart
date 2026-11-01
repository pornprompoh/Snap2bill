import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/utils/bill_progress_helper.dart';

void main() {
  group('Integration Tests: Multi-Member Bill & Payment Lifecycle', () {
    test('end-to-end integration flow from bill creation to 100% settlement', () {
      // Step 1: Initial creation of a bill with 1 owner and 2 participants
      final bill = {
        'id': 'integration-bill-1',
        'shop_name': 'ชาบูชิ บุฟเฟต์',
        'owner_id': 'user-owner',
        'sub_total': 1200.0,
        'status': 'unpaid',
        'bill_participants': [
          {'profile_id': 'user-owner', 'status': 'completed', 'amount_owed': 400.0},
          {'profile_id': 'user-friend-1', 'status': 'pending', 'amount_owed': 400.0},
          {'profile_id': 'user-friend-2', 'status': 'pending', 'amount_owed': 400.0},
        ],
      };

      // Verify Initial Integration State: 0% paid, 2 people pending
      final step1 = BillProgressHelper.calculate(bill);
      expect(step1.totalMembers, 3);
      expect(step1.totalPayingCount, 2);
      expect(step1.paidCount, 0);
      expect(step1.unpaidCount, 2);
      expect(step1.percentage, 0);
      expect(step1.isSettled, isFalse);
      expect(step1.progressPercentageText, 'เก็บเงินแล้ว 0%');
      expect(step1.paidCountText, 'จ่ายแล้ว 0/2 คน');

      // Step 2: Friend 1 uploads slip and owner confirms (Midway state: 50%)
      bill['bill_participants'] = [
        {'profile_id': 'user-owner', 'status': 'completed', 'amount_owed': 400.0},
        {'profile_id': 'user-friend-1', 'status': 'paid', 'amount_owed': 400.0},
        {'profile_id': 'user-friend-2', 'status': 'pending', 'amount_owed': 400.0},
      ];

      final step2 = BillProgressHelper.calculate(bill);
      expect(step2.paidCount, 1);
      expect(step2.unpaidCount, 1);
      expect(step2.percentage, 50);
      expect(step2.isSettled, isFalse);
      expect(step2.progressPercentageText, 'เก็บเงินแล้ว 50%');
      expect(step2.paidCountText, 'จ่ายแล้ว 1/2 คน');

      // Step 3: Friend 2 confirms payment (Final settled state: 100%)
      bill['bill_participants'] = [
        {'profile_id': 'user-owner', 'status': 'completed', 'amount_owed': 400.0},
        {'profile_id': 'user-friend-1', 'status': 'paid', 'amount_owed': 400.0},
        {'profile_id': 'user-friend-2', 'status': 'paid', 'amount_owed': 400.0},
      ];
      bill['status'] = 'completed';

      final step3 = BillProgressHelper.calculate(bill);
      expect(step3.paidCount, 2);
      expect(step3.unpaidCount, 0);
      expect(step3.percentage, 100);
      expect(step3.isSettled, isTrue);
      expect(step3.progressPercentageText, 'เก็บเงินแล้ว 100%');
      expect(step3.paidCountText, 'จ่ายครบแล้ว 2/2 คน');
      expect(step3.waitingText, 'ครบแล้ว 🎉');
    });
  });
}

