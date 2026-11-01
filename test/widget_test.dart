import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/widgets/bill_card.dart';
import 'package:snap2bill/widgets/custom_button.dart';
import 'package:snap2bill/widgets/bill/member_summary_list.dart';
import 'package:snap2bill/utils/bill_progress_helper.dart';
import 'package:snap2bill/utils/promptpay_helper.dart';
import 'package:snap2bill/utils/formatters.dart';
import 'package:snap2bill/widgets/bill/shareable_receipt_card.dart';
import 'package:snap2bill/widgets/bill/claim_item_card.dart';
import 'package:snap2bill/utils/menu_icon_helper.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
      expect(find.textContaining('1,251'), findsOneWidget);

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
              isEqualSplit: true,
            ),
          ),
        ),
      );

      // Verify shop name
      expect(find.text('Shabu Shabu Buffet'), findsOneWidget);
      // Verify price and average per person (Ceiling integer)
      expect(find.text('750 ฿'), findsOneWidget);
      expect(find.text('ตกคนละ 250 ฿'), findsOneWidget);
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

  group('PromptPayHelper and ShareableReceiptCard Unit & Widget Tests', () {
    test('PromptPayHelper validates and generates standard EMVCo payload', () {
      expect(PromptPayHelper.isValidTarget('0812345678'), isTrue);
      expect(PromptPayHelper.isValidTarget('1234567890123'), isTrue);
      expect(PromptPayHelper.isValidTarget('123'), isFalse);

      final payload = PromptPayHelper.generatePayload('0812345678', amount: 250.0);
      expect(payload, startsWith('000201'));
      expect(payload, contains('A000000677010111'));
      expect(payload, contains('0066812345678'));
      expect(payload, contains('250.00'));
      expect(payload.length, greaterThan(50));
    });

    testWidgets('ShareableReceiptCard renders authentic receipt with members and PromptPay QR',
        (WidgetTester tester) async {
      final billData = {
        'id': 'bill_receipt_test',
        'shop_name': 'สชิโร่ (SUSHIRO)',
        'owner_id': 'owner_ying',
        'sub_total': 500.0,
        'created_at': '2026-11-01T14:30:00Z',
        'bill_participants': [
          {'profile_id': 'owner_ying', 'status': 'paid', 'amount_owed': 250.0},
          {'profile_id': 'guest_film', 'status': 'pending', 'amount_owed': 250.0},
        ],
      };

      final summary = BillProgressHelper.calculate(billData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShareableReceiptCard(
                bill: billData,
                summary: summary,
                hostPromptPay: '0812345678',
                hostName: 'พรพรหม (หญิง)',
              ),
            ),
          ),
        ),
      );

      // Verify receipt title and shop
      expect(find.text('SNAP2BILL RECEIPT'), findsOneWidget);
      expect(find.text('สชิโร่ (SUSHIRO)'), findsOneWidget);

      // Verify total and split amount
      expect(find.text('500 ฿'), findsOneWidget);
      expect(find.text('ตกคนละ 250 ฿'), findsOneWidget);

      // Verify member breakdown
      expect(find.text('เจ้าของ 👑'), findsOneWidget);
      expect(find.text('รอจ่าย ⏳'), findsOneWidget);

      // Verify PromptPay QR is rendered
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.textContaining('Thai QR Payment'), findsOneWidget);
      expect(find.textContaining('ชื่อบัญชี: พรพรหม (หญิง)'), findsOneWidget);
    });

    testWidgets('ShareableReceiptCard shows notice when host PromptPay is not set',
        (WidgetTester tester) async {
      final billData = {
        'id': 'bill_no_qr',
        'shop_name': 'KFC',
        'owner_id': 'owner_ying',
        'sub_total': 200.0,
      };

      final summary = BillProgressHelper.calculate(billData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShareableReceiptCard(
                bill: billData,
                summary: summary,
                hostPromptPay: null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('เจ้าของบิลยังไม่ได้ตั้งค่าพร้อมเพย์'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });
  });

  group('MenuIconHelper & Dynamic Dish Icon Tests (Material Design 3)', () {
    test('MenuIconHelper maps diverse food and drink keywords to correct Material icons', () {
      // 1. ซูชิ (Sushi / Sashimi)
      expect(MenuIconHelper.getDishIcon('B Sushi'), equals(Icons.set_meal_rounded));
      expect(MenuIconHelper.getDishIcon('ซูชิแซลมอน'), equals(Icons.set_meal_rounded));
      expect(MenuIconHelper.getDishIcon('ข้าวปั้นหน้ากุ้ง'), equals(Icons.set_meal_rounded));

      // 2. ราเมน (Ramen / Noodles)
      expect(MenuIconHelper.getDishIcon('B Ramen'), equals(Icons.ramen_dining_rounded));
      expect(MenuIconHelper.getDishIcon('ราเมนต้มยำ'), equals(Icons.ramen_dining_rounded));
      expect(MenuIconHelper.getDishIcon('สปาเก็ตตี้ขี้เมา'), equals(Icons.ramen_dining_rounded));

      // 3. พิซซ่า (Pizza)
      expect(MenuIconHelper.getDishIcon('Pizza Hawaiian'), equals(Icons.local_pizza_rounded));
      expect(MenuIconHelper.getDishIcon('พิซซ่าหน้าซีฟู้ด'), equals(Icons.local_pizza_rounded));

      // 4. เบอร์เกอร์ (Burger)
      expect(MenuIconHelper.getDishIcon('Cheeseburger'), equals(Icons.lunch_dining_rounded));
      expect(MenuIconHelper.getDishIcon('เบอร์เกอร์หมู'), equals(Icons.lunch_dining_rounded));

      // 5. น้ำปั่น / เครื่องดื่มปั่น (Smoothie / Shakes)
      expect(MenuIconHelper.getDishIcon('น้ำส้มปั่น'), equals(Icons.local_drink_rounded));
      expect(MenuIconHelper.getDishIcon('Strawberry Smoothie'), equals(Icons.local_drink_rounded));
      expect(MenuIconHelper.getDishIcon('มะนาวปั่น'), equals(Icons.local_drink_rounded));

      // 6. กาแฟ (Coffee)
      expect(MenuIconHelper.getDishIcon('Iced Americano'), equals(Icons.local_cafe_rounded));
      expect(MenuIconHelper.getDishIcon('ลาเต้ร้อน'), equals(Icons.local_cafe_rounded));
      expect(MenuIconHelper.getDishIcon('กาแฟสด'), equals(Icons.local_cafe_rounded));

      // 7. เค้ก (Cake)
      expect(MenuIconHelper.getDishIcon('Chocolate Cake'), equals(Icons.cake_rounded));
      expect(MenuIconHelper.getDishIcon('ชีสเค้กหน้าไหม้'), equals(Icons.cake_rounded));

      // 8. อาหารทั่วไป (Fallback for unclassified items)
      expect(MenuIconHelper.getDishIcon('อาหารจานพิเศษ #99'), equals(Icons.restaurant_rounded));
      expect(MenuIconHelper.getDishIcon(''), equals(Icons.restaurant_rounded));
    });

    testWidgets('ClaimItemCard renders distinct icons for Sushi and Ramen instead of identical icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ClaimItemCard(
                  itemName: 'B Sushi',
                  itemQuantity: 10,
                  unitPrice: 40.0,
                  claimingUserId: 'user_1',
                  itemClaims: const {},
                  sharedUsers: const {},
                  userNames: const {},
                  onChangeQuantity: (_) {},
                  onToggleShared: () {},
                ),
                ClaimItemCard(
                  itemName: 'B Ramen',
                  itemQuantity: 1,
                  unitPrice: 100.0,
                  claimingUserId: 'user_1',
                  itemClaims: const {},
                  sharedUsers: const {},
                  userNames: const {},
                  onChangeQuantity: (_) {},
                  onToggleShared: () {},
                ),
              ],
            ),
          ),
        ),
      );

      // Verify Sushi has set_meal icon and Ramen has ramen_dining icon
      expect(find.byIcon(Icons.set_meal_rounded), findsOneWidget);
      expect(find.byIcon(Icons.ramen_dining_rounded), findsOneWidget);
    });
  });

  group('Bill Management, Ceiling Round Up & Equal Split Tests', () {
    test('Requirement 5: ceiling round up always rounds fractions to next integer without decimals', () {
      // 100 ÷ 3 = 33.33 -> 34 บาท/คน
      expect(AppFormatters.formatCurrency(100 / 3), equals('34 ฿'));
      // 101 ÷ 3 = 33.67 -> 34 บาท/คน
      expect(AppFormatters.formatCurrency(101 / 3), equals('34 ฿'));
      // 99 ÷ 2 = 49.50 -> 50 บาท/คน
      expect(AppFormatters.formatCurrency(99 / 2), equals('50 ฿'));
      // 120 ÷ 4 = 30.00 -> 30 บาท/คน
      expect(AppFormatters.formatCurrency(120 / 4), equals('30 ฿'));
      // 100 ÷ 6 = 16.67 -> 17 บาท/คน
      expect(AppFormatters.formatCurrency(100 / 6), equals('17 ฿'));
      // 199 ÷ 3 = 66.33 -> 67 บาท/คน
      expect(AppFormatters.formatCurrency(199 / 3), equals('67 ฿'));
    });

    testWidgets('Requirement 4: BillCard hides average per person when members pay unequal amounts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BillCard(
              shopName: 'Sushi Bar',
              totalAmount: 500.0,
              dateText: '2026-11-01',
              status: 'pending',
              memberCount: 3,
              totalPayingCount: 2,
              paidCount: 0,
              unpaidCount: 2,
              averagePerPerson: null,
              isEqualSplit: false, // Unequal amounts: member 1 paid 80+34=114, member 2 paid 160+34=194
            ),
          ),
        ),
      );

      // Verify total price is displayed
      expect(find.text('500 ฿'), findsOneWidget);
      // Verify "ตกคนละ" text is NOT rendered because amounts are unequal
      expect(find.textContaining('ตกคนละ'), findsNothing);
    });

    testWidgets('Requirement 4: BillCard displays average per person when members pay equal amounts',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BillCard(
              shopName: 'Sushi Bar',
              totalAmount: 500.0,
              dateText: '2026-11-01',
              status: 'pending',
              memberCount: 2,
              totalPayingCount: 1,
              paidCount: 0,
              unpaidCount: 1,
              averagePerPerson: 250.0,
              isEqualSplit: true, // Both pay 250.0
            ),
          ),
        ),
      );

      expect(find.text('500 ฿'), findsOneWidget);
      expect(find.text('ตกคนละ 250 ฿'), findsOneWidget);
    });

    test('Requirement 1: bill with unpaid member is never settled even if marked completed in raw status', () {
      final bill = {
        'id': 'bill_pending_test',
        'shop_name': 'Sushi Shop',
        'owner_id': 'owner_1',
        'status': 'completed', // mistakenly has completed in raw DB field
        'bill_participants': [
          {'profile_id': 'owner_1', 'amount_owed': 114.0, 'status': 'paid'},
          {'profile_id': 'friend_1', 'amount_owed': 194.0, 'status': 'pending'}, // Still unpaid!
        ],
      };

      final summary = BillProgressHelper.calculate(bill);
      expect(summary.unpaidCount, equals(1));
      expect(summary.totalPayingCount, equals(1));
      expect(summary.isSettled, isFalse); // MUST be false!
    });
  });
}
