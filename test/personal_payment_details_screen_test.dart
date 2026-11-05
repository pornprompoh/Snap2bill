import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/screens/bill/personal_payment_details_screen.dart';
import 'package:snap2bill/widgets/bill/member_summary_list.dart';

Widget _paymentScreen({
  String status = 'pending',
  List<MemberDishItem> dishes = const [],
  bool isCurrentViewerOwner = false,
  bool memberIsOwner = false,
  bool memberIsGuest = false,
  String hostPromptPay = '',
  String hostBankAccountNumber = '',
  String? hostBankName,
  String? hostBankAccountName,
}) {
  return MaterialApp(
    home: PersonalPaymentDetailsScreen(
      key: ValueKey(status),
      billData: const {'id': 'bill-1'},
      member: MemberSummaryEntry(
        id: 'member-1',
        name: 'Test Member',
        amount: 130,
        status: status,
        isOwner: memberIsOwner,
        isGuest: memberIsGuest,
        dishes: dishes,
      ),
      hostPromptPay: hostPromptPay,
      hostPromptPayType: 'phone',
      hostBankAccountNumber: hostBankAccountNumber,
      hostBankName: hostBankName,
      hostBankAccountName: hostBankAccountName,
      hostName: 'Bill Owner',
      isCurrentViewerOwner: isCurrentViewerOwner,
      receiptSubTotal: 200,
      receiptVat: 10,
      receiptServiceCharge: 20,
    ),
  );
}

void main() {
  testWidgets('shows selected dishes and apportioned receipt charges', (
    tester,
  ) async {
    await tester.pumpWidget(
      _paymentScreen(
        dishes: const [
          MemberDishItem(
            itemName: 'ชาไทย',
            quantity: 2,
            unitPrice: 50,
            totalPrice: 100,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('รายละเอียดการชำระเงินรายบุคคล'), findsOneWidget);
    expect(find.text('Test Member'), findsOneWidget);
    expect(find.text('ชาไทย'), findsOneWidget);
    expect(find.text('ส่วนตัว 2 ชิ้น @ 50 ฿'), findsOneWidget);
    expect(find.text('ยอดรวมค่าอาหาร (Subtotal)'), findsOneWidget);
    expect(find.text('ส่วนแบ่ง Service Charge'), findsOneWidget);
    expect(find.text('ส่วนแบ่ง VAT'), findsOneWidget);
    expect(find.text('ยังไม่ชำระ'), findsOneWidget);
    expect(
      find.text(
        '⚠️ เจ้าของบิลยังไม่ได้ตั้งค่าพร้อมเพย์ กรุณาแนะนำให้เจ้าของบิลระบุเลขพร้อมเพย์ในหน้าโปรไฟล์',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders pending, reviewing, and paid payment states', (
    tester,
  ) async {
    for (final state in const [
      ('pending', 'ยังไม่ชำระ'),
      ('reviewing', 'รอตรวจสอบ'),
      ('paid', 'ชำระแล้ว'),
    ]) {
      await tester.pumpWidget(_paymentScreen(status: state.$1));
      await tester.pumpAndSettle();
      expect(find.text(state.$2), findsOneWidget);
    }
  });

  testWidgets('shows owner controls that match the payment state', (
    tester,
  ) async {
    final ownerStates = const [
      ('pending', 'ทำเครื่องหมายว่าชำระแล้ว'),
      ('reviewing', 'ยืนยันชำระเงิน'),
      ('paid', 'ยกเลิกสถานะจ่ายแล้ว (เปลี่ยนเป็นรอจ่าย)'),
    ];

    for (final state in ownerStates) {
      await tester.pumpWidget(
        _paymentScreen(status: state.$1, isCurrentViewerOwner: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('สำหรับเจ้าของบิล:'), findsOneWidget);
      expect(find.text(state.$2), findsOneWidget);
    }
  });

  testWidgets('hides payment actions for owners and guests who are not host', (
    tester,
  ) async {
    await tester.pumpWidget(_paymentScreen(memberIsOwner: true));
    await tester.pumpAndSettle();
    expect(find.textContaining('เจ้าของบิล'), findsWidgets);
    expect(find.textContaining('แนบหลักฐานการโอนเงิน'), findsNothing);

    await tester.pumpWidget(
      _paymentScreen(memberIsGuest: true, isCurrentViewerOwner: false),
    );
    await tester.pumpAndSettle();
    expect(find.text('Guest'), findsOneWidget);
    expect(find.textContaining('แนบหลักฐานการโอนเงิน'), findsNothing);
  });

  testWidgets('renders PromptPay QR and bank transfer details', (tester) async {
    await tester.pumpWidget(
      _paymentScreen(
        hostPromptPay: '0812345678',
        hostBankAccountNumber: '1234567890',
        hostBankName: 'Test Bank',
        hostBankAccountName: 'Owner Name',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PromptPay QR Code'), findsOneWidget);
    expect(find.text('พร้อมเพย์: 0812345678'), findsOneWidget);
    expect(find.text('ยอดสแกนจ่าย: 130 ฿'), findsOneWidget);
    expect(find.text('Test Bank: 1234567890'), findsOneWidget);
    expect(find.text('ชื่อบัญชี: Owner Name'), findsOneWidget);
    expect(find.text('บันทึก QR Code'), findsOneWidget);
    expect(find.text('คัดลอกยอดเงิน'), findsOneWidget);
    expect(find.byTooltip('คัดลอกเลขบัญชี'), findsOneWidget);
  });
}
