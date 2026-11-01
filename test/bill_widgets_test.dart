import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/widgets/friend_item.dart';
import 'package:snap2bill/widgets/bill/promptpay_card.dart';
import 'package:snap2bill/widgets/bill/claim_item_card.dart';

void main() {
  group('FriendItem Widget Tests', () {
    testWidgets('renders friend name, host badge, amount text and handles tap selection',
        (WidgetTester tester) async {
      bool? selectedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendItem(
              name: 'สมชาย เจ้ามือ',
              isHost: true,
              amountText: '250.00 ฿',
              isSelected: false,
              onSelectionChanged: (value) {
                selectedState = value;
              },
            ),
          ),
        ),
      );

      expect(find.text('สมชาย เจ้ามือ'), findsOneWidget);
      expect(find.text('250.00 ฿'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(find.byType(FriendItem));
      await tester.pump();

      expect(selectedState, isTrue);
    });

    testWidgets('renders non-host friend with subtitle and person icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FriendItem(
              name: 'มานะ เพื่อนร่วมโต๊ะ',
              isHost: false,
              subtitleText: 'ชำระแล้ว',
            ),
          ),
        ),
      );

      expect(find.text('มานะ เพื่อนร่วมโต๊ะ'), findsOneWidget);
      expect(find.text('ชำระแล้ว'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('FriendAvatar renders initials and badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FriendAvatar(
              name: 'Alice Wonder',
              isHost: true,
              isCurrentUser: true,
            ),
          ),
        ),
      );

      expect(find.text('AW'), findsOneWidget);
      expect(find.text('คุณ'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });

  group('PromptPayCard Widget Tests', () {
    testWidgets('renders PromptPay details, amount and cleans up timer on dispose',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PromptPayCard(
                hostName: 'คุณเจ้าของห้อง',
                promptPayNumber: '0812345678',
                qrPayload: 'PROMPTPAY_TEST_PAYLOAD',
                selectedUserName: 'สมหญิง',
                amount: 320.50,
                isPaid: false,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('คุณเจ้าของห้อง'), findsWidgets);
      expect(find.textContaining('0812345678'), findsWidgets);
      expect(find.textContaining('320.50'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('renders paid state with success checkmark and handles slip button',
        (WidgetTester tester) async {
      bool slipAttached = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PromptPayCard(
                hostName: 'คุณเจ้าของห้อง',
                promptPayNumber: '0812345678',
                qrPayload: 'PAYLOAD',
                selectedUserName: 'สมชาย',
                amount: 450.0,
                isPaid: true,
                onAttachSlip: () {
                  slipAttached = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('ชำระเงินสำเร็จเรียบร้อยแล้ว! 🎉'), findsOneWidget);
      expect(find.textContaining('ยอดชำระของ สมชาย'), findsOneWidget);
      expect(find.text('แนบ / ตรวจสอบสลิปหลักฐาน'), findsOneWidget);

      await tester.tap(find.text('แนบ / ตรวจสอบสลิปหลักฐาน'));
      await tester.pump();

      expect(slipAttached, isTrue);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('switches to bank account transfer mode when bank details are provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PromptPayCard(
                hostName: 'คุณเจ้าของห้อง',
                promptPayNumber: '0812345678',
                bankName: 'กสิกรไทย',
                bankAccountNumber: '123-4-56789-0',
                bankAccountName: 'สมชาย เจ้ามือ',
                qrPayload: 'PAYLOAD',
                selectedUserName: 'สมหญิง',
                amount: 600.0,
                isPaid: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('โอนด้วยเลขบัญชี'), findsOneWidget);
      await tester.tap(find.text('โอนด้วยเลขบัญชี'));
      await tester.pump();

      expect(find.textContaining('123-4-56789-0'), findsWidgets);
      expect(find.textContaining('กสิกรไทย'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ClaimItemCard Widget Tests', () {
    testWidgets('renders item details, dish icon, and triggers quantity changes',
        (WidgetTester tester) async {
      int newQty = 0;
      bool shareToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClaimItemCard(
                itemName: 'ข้าวผัดต้มยำกุ้ง',
                itemQuantity: 3,
                unitPrice: 95.0,
                claimingUserId: 'user_1',
                itemClaims: const {'user_1': 1, 'user_2': 1},
                sharedUsers: const {'user_1', 'user_2'},
                userNames: const {'user_1': 'ฉัน', 'user_2': 'เพื่อน'},
                onChangeQuantity: (qty) {
                  newQty = qty;
                },
                onToggleShared: () {
                  shareToggled = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('ข้าวผัดต้มยำกุ้ง'), findsOneWidget);
      expect(find.textContaining('95.00'), findsOneWidget);
      expect(find.byIcon(Icons.rice_bowl_rounded), findsOneWidget);

      // Tap + button to increment
      final addButtons = find.byIcon(Icons.add);
      if (addButtons.evaluate().isNotEmpty) {
        await tester.tap(addButtons.first);
        await tester.pump();
        expect(newQty, 2);
      }

      // Tap share button
      final shareChip = find.textContaining('กินด้วยกัน');
      expect(shareChip, findsOneWidget);
      await tester.tap(shareChip);
      await tester.pump();
      expect(shareToggled, isTrue);
    });

    testWidgets('renders drink dish icon for beverage items',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClaimItemCard(
              itemName: 'ชาเขียวเย็นหวานน้อย',
              itemQuantity: 1,
              unitPrice: 45.0,
              claimingUserId: 'user_1',
              itemClaims: const {'user_1': 1},
              sharedUsers: const {},
              userNames: const {'user_1': 'ฉัน'},
              onChangeQuantity: (_) {},
              onToggleShared: () {},
            ),
          ),
        ),
      );

      expect(find.text('ชาเขียวเย็นหวานน้อย'), findsOneWidget);
      expect(find.byIcon(Icons.local_cafe_rounded), findsOneWidget);
    });
  });
}
