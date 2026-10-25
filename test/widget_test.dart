import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/widgets/bill_card.dart';
import 'package:snap2bill/widgets/custom_button.dart';
import 'package:snap2bill/widgets/bill/member_summary_list.dart';

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
}
