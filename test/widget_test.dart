import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/widgets/bill_card.dart';
import 'package:snap2bill/widgets/custom_button.dart';
import 'package:snap2bill/widgets/bill/member_summary_list.dart';
import 'package:snap2bill/utils/bill_progress_helper.dart';

void main() {
  group('BillCard Widget Tests (Week 1 & 2)', () {
    testWidgets('renders shop name, formatted price, date and handles tap',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BillCard(
              shopName: 'Shabu Shabu Buffet',
              totalAmount: 1250.50,
              dateText: '25 ต.ค. 2026',
              status: 'completed',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      // Verify that shop name and date are displayed
      expect(find.text('Shabu Shabu Buffet'), findsOneWidget);
      expect(find.text('25 ต.ค. 2026'), findsOneWidget);

      // Verify that formatted price with THB is displayed
      expect(find.textContaining('1,250.50'), findsOneWidget);

      // Tap on the card
      await tester.tap(find.byType(BillCard));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('CustomButton Widget Tests (Week 3 UI/UX)', () {
    testWidgets('renders button text and triggers onPressed',
        (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'ยืนยันรายการ',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('ยืนยันรายการ'), findsOneWidget);

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows loading spinner when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'กำลังโหลด',
              isLoading: true,
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('MemberSummaryList Payment Status Tests (Week 9 Cloud & State)', () {
    testWidgets('renders payment status badges and triggers onStatusToggle',
        (WidgetTester tester) async {
      MemberSummaryEntry? toggledMember;

      final testMembers = [
        const MemberSummaryEntry(
          id: 'user_1',
          name: 'สมชาย',
          amount: 350.0,
          isPaid: false,
        ),
        const MemberSummaryEntry(
          id: 'user_2',
          name: 'สมหญิง',
          amount: 450.0,
          isPaid: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberSummaryList(
              members: testMembers,
              onStatusToggle: (member) {
                toggledMember = member;
              },
            ),
          ),
        ),
      );

      expect(find.text('สมชาย'), findsOneWidget);
      expect(find.text('สมหญิง'), findsOneWidget);
      expect(find.text('รอจ่าย'), findsOneWidget);
      expect(find.text('จ่ายแล้ว'), findsOneWidget);

      // Tap status toggle on the first member
      await tester.tap(find.text('รอจ่าย'));
      await tester.pump();

      expect(toggledMember, isNotNull);
      expect(toggledMember!.id, equals('user_1'));
    });

    testWidgets('renders owner badge for owner and disables payment toggle button',
        (WidgetTester tester) async {
      bool toggleCalled = false;

      final testMembers = [
        const MemberSummaryEntry(
          id: 'owner_1',
          name: 'หญิง (เจ้าของ)',
          amount: 250.0,
          isOwner: true,
        ),
        const MemberSummaryEntry(
          id: 'user_2',
          name: 'ไข่มุก',
          amount: 250.0,
          isPaid: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberSummaryList(
              members: testMembers,
              isCurrentViewerOwner: true,
              onStatusToggle: (_) {
                toggleCalled = true;
              },
            ),
          ),
        ),
      );

      // Verify that owner shows 'เจ้าของ' badge
      expect(find.text('เจ้าของ'), findsWidgets);
      // Owner should NOT have 'รอจ่าย' or 'จ่ายแล้ว'
      expect(find.text('รอจ่าย'), findsOneWidget); // Only from user_2

      // Tap owner row or owner badge should NOT trigger status toggle
      await tester.tap(find.text('เจ้าของ').first);
      await tester.pump();
      expect(toggleCalled, isFalse);
    });

    testWidgets('regular members see read-only status when isCurrentViewerOwner is false',
        (WidgetTester tester) async {
      bool toggleCalled = false;

      final testMembers = [
        const MemberSummaryEntry(
          id: 'user_2',
          name: 'ไข่มุก',
          amount: 250.0,
          isPaid: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberSummaryList(
              members: testMembers,
              isCurrentViewerOwner: false, // Viewer is not owner
              onStatusToggle: (_) {
                toggleCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('รอจ่าย'), findsOneWidget);
      // Should not have swap icon
      expect(find.byIcon(Icons.swap_horiz), findsNothing);

      // Tapping should not trigger status toggle
      await tester.tap(find.text('รอจ่าย'));
      await tester.pump();
      expect(toggleCalled, isFalse);
    });
  });

  group('Bill Calculation Algorithm Unit Tests (Week 5 State & Logic)', () {
    test('calculates user shares with proportional VAT and service charge', () {
      final items = [
        BillItemModel(
          id: '1',
          billId: 'bill_1',
          itemName: 'Salmon Sushi',
          price: 200,
          quantity: 1,
          userQuantities: {'user_a': 1},
        ),
        BillItemModel(
          id: '2',
          billId: 'bill_1',
          itemName: 'Beef Steak',
          price: 400,
          quantity: 1,
          userQuantities: {'user_b': 1},
        ),
      ];

      // Total menu value = 600. Final total with 10% SC = 660.
      final shares = BillProvider.calculateUserShares(
        items: items,
        finalTotal: 660,
        splitType: 'proportional',
        participantIds: ['user_a', 'user_b'],
      );

      // User A (200/600 * 60 = 20 extra) -> 220
      // User B (400/600 * 60 = 40 extra) -> 440
      expect(shares['user_a'], closeTo(220.0, 0.01));
      expect(shares['user_b'], closeTo(440.0, 0.01));
    });

    test('calculates user shares with equal split for extra charges', () {
      final items = [
        BillItemModel(
          id: '1',
          billId: 'bill_1',
          itemName: 'Ramen A',
          price: 200,
          quantity: 1,
          userQuantities: {'user_a': 1},
        ),
        BillItemModel(
          id: '2',
          billId: 'bill_1',
          itemName: 'Ramen B',
          price: 400,
          quantity: 1,
          userQuantities: {'user_b': 1},
        ),
      ];

      // Total menu value = 600. Final total with 60 baht delivery fee = 660.
      final shares = BillProvider.calculateUserShares(
        items: items,
        finalTotal: 660,
        splitType: 'equal',
        participantIds: ['user_a', 'user_b'],
      );

      // Extra 60 split equally: 30 each
      // User A: 200 + 30 = 230
      // User B: 400 + 30 = 430
      expect(shares['user_a'], closeTo(230.0, 0.01));
      expect(shares['user_b'], closeTo(430.0, 0.01));
    });
  });

  group('BillProgressHelper and Progress Calculation Unit Tests', () {
    test('calculates 50% for 3 members (1 owner, 2 friends) with 1 paid and 1 unpaid', () {
      final billData = {
        'id': 'bill_test_1',
        'shop_name': 'Sushi Express',
        'owner_id': 'owner_ying',
        'sub_total': 750.0,
        'bill_participants': [
          {'profile_id': 'owner_ying', 'status': 'paid', 'amount_owed': 250.0},
          {'profile_id': 'friend_mook', 'status': 'paid', 'amount_owed': 250.0},
          {'profile_id': 'friend_unseen', 'status': 'pending', 'amount_owed': 250.0},
        ],
      };

      final summary = BillProgressHelper.calculate(billData);

      expect(summary.totalMembers, equals(3));
      expect(summary.totalPayingCount, equals(2)); // Owner excluded
      expect(summary.paidCount, equals(1));
      expect(summary.unpaidCount, equals(1));
      expect(summary.percentage, equals(50));
      expect(summary.isSettled, isFalse);
      expect(summary.progressPercentageText, equals('เก็บเงินแล้ว 50%'));
      expect(summary.paidCountText, equals('จ่ายแล้ว 1/2 คน'));
      expect(summary.waitingText, equals('รออีก 1 คน'));
      expect(summary.averagePerPerson, equals(250.0));
    });

    test('calculates 100% and settled when all non-owner friends pay', () {
      final billData = {
        'id': 'bill_test_2',
        'shop_name': 'KFC',
        'owner_id': 'owner_ying',
        'sub_total': 500.0,
        'bill_participants': [
          {'profile_id': 'owner_ying', 'status': 'paid', 'amount_owed': 250.0},
          {'profile_id': 'friend_mook', 'status': 'paid', 'amount_owed': 250.0},
        ],
      };

      final summary = BillProgressHelper.calculate(billData);

      expect(summary.totalMembers, equals(2));
      expect(summary.totalPayingCount, equals(1));
      expect(summary.paidCount, equals(1));
      expect(summary.unpaidCount, equals(0));
      expect(summary.percentage, equals(100));
      expect(summary.isSettled, isTrue);
      expect(summary.paidCountText, equals('จ่ายครบแล้ว 1/1 คน'));
    });

    test('handles solo bill without division by zero', () {
      final billData = {
        'id': 'bill_test_solo',
        'shop_name': 'Starbucks',
        'owner_id': 'owner_ying',
        'sub_total': 150.0,
        'bill_participants': [
          {'profile_id': 'owner_ying', 'status': 'paid', 'amount_owed': 150.0},
        ],
      };

      final summary = BillProgressHelper.calculate(billData);

      expect(summary.totalMembers, equals(1));
      expect(summary.totalPayingCount, equals(0));
      expect(summary.paidCount, equals(0));
      expect(summary.unpaidCount, equals(0));
      expect(summary.percentage, equals(100));
      expect(summary.isSettled, isTrue);
    });

    testWidgets('BillCard renders progress bar, percentage, and average price',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BillCard(
              shopName: 'Shabu Shabu Buffet',
              totalAmount: 750.0,
              dateText: '2026-11-01',
              status: 'pending',
              memberCount: 3,
              totalPayingCount: 2,
              paidCount: 1,
              unpaidCount: 1,
              averagePerPerson: 250.0,
            ),
          ),
        ),
      );

      // Verify shop name
      expect(find.text('Shabu Shabu Buffet'), findsOneWidget);
      // Verify price and average per person
      expect(find.text('750.00 ฿'), findsOneWidget);
      expect(find.text('ตกคนละ 250.00 ฿'), findsOneWidget);
      // Verify collection progress text
      expect(find.text('เก็บเงินแล้ว 50%'), findsOneWidget);
      expect(find.text('จ่ายแล้ว 1/2 คน'), findsOneWidget);
      expect(find.text('รออีก 1 คน'), findsOneWidget);
    });

    testWidgets('BillCard displays placeholder text when totalAmount is zero',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BillCard(
              shopName: 'Unknown Shop',
              totalAmount: 0.0,
              dateText: '2026-11-01',
              status: 'pending',
            ),
          ),
        ),
      );

      expect(find.text('ยังไม่มีข้อมูลยอดบิล'), findsOneWidget);
    });
  });
}
