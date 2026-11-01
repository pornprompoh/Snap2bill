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
import 'package:snap2bill/services/ocr_service.dart';
import 'package:snap2bill/screens/bill/personal_payment_details_screen.dart';
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
      expect(summary.percentage, equals(0));
      expect(summary.isSettled, isFalse);
    });

    test('new bill with guest from sharers_json stays pending', () {
      final summary = BillProgressHelper.calculate({
        'id': 'b1',
        'owner_id': 'owner',
        'sub_total': 500.0,
        'status': 'pending',
        'sharers_json': {
          '0': [
            {'user_id': 'owner', 'user_name': 'o', 'quantity': 1},
            {'user_id': 'guest_1', 'user_name': 'g', 'quantity': 1},
          ],
        },
      });
      expect(summary.totalPayingCount, equals(1));
      expect(summary.paidCount, equals(0));
      expect(summary.isSettled, isFalse);
    });

    test('percentage: 0% new, 50% one of two paid, 100% all paid (owner excluded)', () {
      Map<String, dynamic> bill(String a, String b) => {
            'id': 'bp',
            'owner_id': 'owner',
            'sub_total': 300.0,
            'bill_participants': [
              {'profile_id': 'owner', 'status': 'pending', 'amount_owed': 100.0},
              {'profile_id': 'a', 'status': a, 'amount_owed': 100.0},
              {'profile_id': 'b', 'status': b, 'amount_owed': 100.0},
            ],
          };
      final none = BillProgressHelper.calculate(bill('pending', 'pending'));
      expect(none.percentage, equals(0));
      expect(none.isSettled, isFalse);
      final half = BillProgressHelper.calculate(bill('paid', 'pending'));
      expect(half.percentage, equals(50));
      expect(half.paidCount, equals(1));
      expect(half.totalPayingCount, equals(2));
      expect(half.isSettled, isFalse);
      final all = BillProgressHelper.calculate(bill('paid', 'paid'));
      expect(all.percentage, equals(100));
      expect(all.isSettled, isTrue);
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

      // Verify Sushi has sushi emoji and Ramen has ramen emoji
      expect(find.text('🍣'), findsOneWidget);
      expect(find.text('🍜'), findsOneWidget);
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

  group('AI Scan Receipt Filtering Tests (> 0 Baht Rule)', () {
    test('OcrService.validateAndNormalizeReceipt filters out 0-baht items, freebies, privileges and keeps valid dishes', () {
      final rawAiReceipt = {
        'shop_name': 'Haidilao',
        'is_vat_included': true,
        'vat_amount': 0,
        'service_charge': 0,
        'discount': 0,
        'final_total': 300.0,
        'total_amount': 300.0,
        'items': [
          {'item_name': 'ซูชิแซลมอน', 'qty': 1, 'unit_price': 120.0, 'total_price': 120.0},
          {'item_name': 'ราเมน', 'qty': 1, 'unit_price': 180.0, 'total_price': 180.0},
          {'item_name': 'น้ำเปล่า', 'qty': 1, 'unit_price': 0.0, 'total_price': 0.0}, // Free water
          {'item_name': 'ของแถม', 'qty': 1, 'unit_price': 0.0, 'total_price': 0.0}, // Giveaway
          {'item_name': 'ส่วนลดสมาชิก', 'qty': 1, 'unit_price': 0.0, 'total_price': 0.0}, // Member discount remark
          {'item_name': 'สิทธิ์แลกซื้อ', 'qty': 3, 'unit_price': 0.0, 'total_price': 0.0}, // Privileges
          {'item_name': 'AMB สิทธิ์แลกซื้อ', 'qty': 3, 'unit_price': 0.0, 'total_price': 0.0}, // Privileges
          {'item_name': 'รายการที่ไม่มีราคา', 'qty': 1, 'unit_price': null, 'total_price': null}, // No price
          {'item_name': '', 'qty': 1, 'unit_price': 50.0, 'total_price': 50.0}, // Empty name
        ],
      };

      final normalized = OcrService.validateAndNormalizeReceipt(rawAiReceipt);
      final items = normalized['items'] as List<dynamic>;

      // Only the 2 valid dishes with price > 0 must remain
      expect(items.length, equals(2));
      expect(items[0]['item_name'], equals('ซูชิแซลมอน'));
      expect(items[0]['total_price'], equals(120.0));
      expect(items[1]['item_name'], equals('ราเมน'));
      expect(items[1]['total_price'], equals(180.0));

      // 0-baht items must NEVER exist
      final allNames = items.map((e) => e['item_name']?.toString()).toList();
      expect(allNames.contains('น้ำเปล่า'), isFalse);
      expect(allNames.contains('ของแถม'), isFalse);
      expect(allNames.contains('ส่วนลดสมาชิก'), isFalse);
      expect(allNames.contains('สิทธิ์แลกซื้อ'), isFalse);
      expect(allNames.contains('AMB สิทธิ์แลกซื้อ'), isFalse);
      expect(allNames.contains('รายการที่ไม่มีราคา'), isFalse);

      // Reconciled sub_total and final_total remain intact
      expect(normalized['sub_total'], equals(300.0));
      expect(normalized['final_total'], equals(300.0));
    });

    test('OcrService.validateAndNormalizeReceipt throws FormatException when no positive price items exist', () {
      final zeroOnlyReceipt = {
        'shop_name': 'Test Shop',
        'is_vat_included': true,
        'final_total': 0.0,
        'items': [
          {'item_name': 'ของแถม', 'qty': 1, 'unit_price': 0.0, 'total_price': 0.0},
          {'item_name': 'สิทธิ์แลกซื้อ', 'qty': 2, 'unit_price': 0.0, 'total_price': 0.0},
        ],
      };

      expect(
        () => OcrService.validateAndNormalizeReceipt(zeroOnlyReceipt),
        throwsA(isA<FormatException>()),
      );
    });

    test('Receipt items filtering strips 0-baht and unpriced items matching user screenshot', () {
      final receiptData = {
        'shop_name': 'MK Restaurant',
        'is_vat_included': true,
        'final_total': 175.0,
        'total_amount': 175.0,
        'items': [
          {'item_name': 'H ข้าวโพดหวานตัดท่อ', 'qty': 1, 'unit_price': 22.0, 'total_price': 22.0},
          {'item_name': 'H ข้าวหอมมะลิหุงสุก', 'qty': 1, 'unit_price': 15.0, 'total_price': 15.0},
          {'item_name': 'H น้ำดื่มเพียวไลฟ์ 15', 'qty': 2, 'unit_price': 69.0, 'total_price': 138.0},
          {'item_name': 'สิทธิ์แลกซื้อ', 'qty': 3, 'unit_price': 0.0, 'total_price': 0.0},
          {'item_name': 'AMB สิทธิ์แลกซื้อ', 'qty': 3, 'unit_price': 0.0, 'total_price': 0.0},
        ],
      };

      final normalized = OcrService.validateAndNormalizeReceipt(receiptData);
      final items = normalized['items'] as List<dynamic>;

      expect(items.length, equals(3));
      expect(items[0]['item_name'], equals('H ข้าวโพดหวานตัดท่อ'));
      expect(items[1]['item_name'], equals('H ข้าวหอมมะลิหุงสุก'));
      expect(items[2]['item_name'], equals('H น้ำดื่มเพียวไลฟ์ 15'));

      final names = items.map((e) => e['item_name']).toList();
      expect(names.contains('สิทธิ์แลกซื้อ'), isFalse);
      expect(names.contains('AMB สิทธิ์แลกซื้อ'), isFalse);
    });
  });

  group('Personal Payment Details & Member Row Navigation Tests', () {
    testWidgets('MemberSummaryList shows dish count, chevron, and triggers onMemberTap', (WidgetTester tester) async {
      String? tappedMemberId;

      final members = [
        const MemberSummaryEntry(
          id: 'user_1',
          name: 'ฟิม (Guest)',
          amount: 250.0,
          itemsCount: 3,
          isGuest: true,
          dishes: [
            MemberDishItem(
              itemName: 'B Sushi',
              quantity: 2,
              unitPrice: 40.0,
              totalPrice: 80.0,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MemberSummaryList(
              members: members,
              onMemberTap: (id) => tappedMemberId = id,
            ),
          ),
        ),
      );

      // Verify member name and formatted currency
      expect(find.textContaining('ฟิม'), findsOneWidget);
      expect(find.text('250 ฿'), findsOneWidget);
      // Verify dish count subtitle
      expect(find.text('3 รายการ'), findsOneWidget);
      // Verify chevron icon
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Tap row to trigger navigation callback
      await tester.tap(find.textContaining('ฟิม'));
      await tester.pump();
      expect(tappedMemberId, equals('user_1'));
    });

    testWidgets('PersonalPaymentDetailsScreen renders member info, dishes with emoji, breakdown and PromptPay QR', (WidgetTester tester) async {
      final testMember = const MemberSummaryEntry(
        id: 'member_99',
        name: 'สายกิน',
        amount: 250.0,
        itemsCount: 2,
        dishes: [
          MemberDishItem(
            itemName: 'Sushi แซลมอน',
            quantity: 2,
            unitPrice: 40.0,
            totalPrice: 80.0,
          ),
          MemberDishItem(
            itemName: 'Ramen ซุปกระดูกหมู',
            quantity: 1,
            unitPrice: 120.0,
            totalPrice: 120.0,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonalPaymentDetailsScreen(
              billData: const {
                'id': 'bill_123',
                'shop_name': 'Sushiro',
                'receipt_json': {
                  'sub_total': 200.0,
                  'service_charge': 20.0,
                  'vat_amount': 30.0,
                  'final_total': 250.0,
                },
              },
              member: testMember,
              hostPromptPay: '0812345678',
              hostPromptPayType: 'phone',
              hostBankAccountNumber: '1234567890',
              hostName: 'คุณเจ้าของ',
              isCurrentViewerOwner: true,
              receiptSubTotal: 200.0,
              receiptVat: 30.0,
              receiptServiceCharge: 20.0,
            ),
          ),
        ),
      );

      // Verify participant header
      expect(find.text('สายกิน'), findsWidgets);
      // Verify isolated dishes
      expect(find.text('Sushi แซลมอน'), findsOneWidget);
      expect(find.text('Ramen ซุปกระดูกหมู'), findsOneWidget);
      // Verify dish emojis
      expect(find.text('🍣'), findsOneWidget);
      expect(find.text('🍜'), findsOneWidget);
      // Verify financial breakdown & Net Total
      expect(find.text('ยอดเงินสุทธิที่ต้องชำระ'), findsOneWidget);
      expect(find.text('250 ฿'), findsWidgets);
      // Verify PromptPay QR section
      expect(find.text('PromptPay QR Code'), findsOneWidget);
      expect(find.textContaining('คุณเจ้าของ'), findsWidgets);
      expect(find.textContaining('0812345678'), findsWidgets);
      expect(find.byType(QrImageView), findsOneWidget);
      // Verify action buttons
      expect(find.text('บันทึก QR Code'), findsOneWidget);
      expect(find.text('คัดลอกยอดเงิน'), findsOneWidget);
      expect(find.textContaining('แนบหลักฐานการโอนเงิน'), findsOneWidget);

      // Tap copy amount
      await tester.ensureVisible(find.text('คัดลอกยอดเงิน'));
      await tester.tap(find.text('คัดลอกยอดเงิน'));
      await tester.pump();
      expect(find.textContaining('คัดลอกยอดเงิน'), findsWidgets);
    });

    testWidgets('PersonalPaymentDetailsScreen renders paid state and suppresses slip upload', (WidgetTester tester) async {
      final paidMember = const MemberSummaryEntry(
        id: 'member_paid',
        name: 'สายจ่ายไว',
        amount: 300.0,
        status: 'paid',
        isPaid: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonalPaymentDetailsScreen(
              billData: const {
                'id': 'bill_456',
                'shop_name': 'Mo-Mo-Paradise',
              },
              member: paidMember,
              hostPromptPay: '0812345678',
              hostBankAccountNumber: '1234567890',
              hostName: 'เจ้าของบิล',
              isCurrentViewerOwner: true,
            ),
          ),
        ),
      );

      expect(find.text('ชำระเงินสำเร็จเรียบร้อยแล้ว 🎉'), findsOneWidget);
      expect(find.text('ชำระแล้ว'), findsWidgets);
      // Slip upload button is suppressed
      expect(find.textContaining('แนบหลักฐานการโอนเงิน'), findsNothing);
    });

    testWidgets('PersonalPaymentDetailsScreen renders reviewing state with owner approval and rejection buttons', (WidgetTester tester) async {
      final reviewingMember = const MemberSummaryEntry(
        id: 'member_rev',
        name: 'เพื่อนกำลังจ่าย',
        amount: 180.0,
        status: 'reviewing',
        isReviewing: true,
        slipUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonalPaymentDetailsScreen(
              billData: const {
                'id': 'bill_789',
                'shop_name': 'Haidilao',
              },
              member: reviewingMember,
              hostPromptPay: '0812345678',
              hostBankAccountNumber: '1234567890',
              hostName: 'คุณเจ้าของ',
              isCurrentViewerOwner: true,
            ),
          ),
        ),
      );

      expect(find.text('รอตรวจสอบ'), findsWidgets);
      expect(find.text('ยืนยันชำระเงิน'), findsOneWidget);
      expect(find.text('ปฏิเสธสลิป'), findsOneWidget);
      expect(find.text('ดูรูป'), findsOneWidget);
    });

    testWidgets('PersonalPaymentDetailsScreen shows warning when host PromptPay is not set', (WidgetTester tester) async {
      final member = const MemberSummaryEntry(
        id: 'user_no_pp',
        name: 'ต้นกล้า',
        amount: 150.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PersonalPaymentDetailsScreen(
              billData: const {'id': 'bill_no_pp'},
              member: member,
              hostPromptPay: '',
              hostBankAccountNumber: '',
              hostName: 'คุณเจ้าของ',
              isCurrentViewerOwner: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('เจ้าของบิลยังไม่ได้ตั้งค่าพร้อมเพย์'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    test('MemberSummaryEntry and MemberDishItem model properties and copyWith', () {
      const dish = MemberDishItem(
        itemName: 'Salmon',
        quantity: 2,
        isShared: true,
        totalSharers: 2,
        unitPrice: 50.0,
        totalPrice: 100.0,
      );
      expect(dish.itemName, 'Salmon');
      expect(dish.isShared, isTrue);

      const entry = MemberSummaryEntry(
        id: 'e1',
        name: 'Member 1',
        amount: 100.0,
      );
      final copied = entry.copyWith(
        name: 'Member Updated',
        amount: 120.0,
        status: 'paid',
        itemsCount: 2,
        dishes: [dish],
      );
      expect(copied.name, 'Member Updated');
      expect(copied.amount, 120.0);
      expect(copied.isPaid, isTrue);
      expect(copied.itemsCount, 2);
      expect(copied.dishes.length, 1);
    });

    test('PromptPayHelper.maskPromptPay masks phone numbers and national IDs correctly', () {
      expect(PromptPayHelper.maskPromptPay('0812345678'), '081-xxx-5678');
      expect(PromptPayHelper.maskPromptPay('0899991234'), '089-xxx-1234');
      expect(PromptPayHelper.maskPromptPay('1234567890123'), '1-xxxx-xxxxx-12-3');
      expect(PromptPayHelper.maskPromptPay('1100501234567'), '1-xxxx-xxxxx-56-7');
      expect(PromptPayHelper.maskPromptPay('12345'), '12345');
    });

    testWidgets('ShareableReceiptCard displays owner PromptPay QR code with masked number and guidance text', (WidgetTester tester) async {
      final bill = {
        'id': 'bill-receipt-1',
        'shop_name': 'Sushi Masa',
        'sub_total': 500.0,
        'created_at': '2026-11-01T12:00:00Z',
      };
      final summary = BillProgressHelper.calculate(bill);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShareableReceiptCard(
                bill: bill,
                summary: summary,
                hostPromptPay: '0812345678',
                hostPromptPayType: 'phone',
                hostName: 'คุณเจ้าของบิล',
              ),
            ),
          ),
        ),
      );

      // Verify Thai QR PromptPay header badge
      expect(find.text('Thai QR Payment (พร้อมเพย์)'), findsOneWidget);
      // Verify QR Code image
      expect(find.byType(QrImageView), findsOneWidget);
      // Verify Account Name and masked number
      expect(find.textContaining('คุณเจ้าของบิล'), findsOneWidget);
      expect(find.textContaining('081-xxx-5678'), findsOneWidget);
      // Verify exact guidance text
      expect(find.text('สแกนเพื่อชำระเงินเข้าบัญชีเจ้าของบิล'), findsOneWidget);
    });

    testWidgets('ShareableReceiptCard displays configure PromptPay button when not configured', (WidgetTester tester) async {
      final bill = {
        'id': 'bill-receipt-2',
        'shop_name': 'Ramen Shop',
        'sub_total': 300.0,
      };
      final summary = BillProgressHelper.calculate(bill);
      bool configClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ShareableReceiptCard(
                bill: bill,
                summary: summary,
                hostPromptPay: null,
                isCurrentViewerOwner: true,
                onConfigurePromptPay: () => configClicked = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('เจ้าของบิลยังไม่ได้ตั้งค่าพร้อมเพย์'), findsOneWidget);
      expect(find.text('ตั้งค่า PromptPay'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);

      await tester.tap(find.text('ตั้งค่า PromptPay'));
      await tester.pump();
      expect(configClicked, isTrue);
    });
  });
}
