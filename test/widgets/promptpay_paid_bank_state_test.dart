import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/widgets/bill/promptpay_card.dart';

void main() {
  testWidgets('shows bank-transfer details for a paid bank-only bill', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PromptPayCard(
              hostName: 'Bill owner',
              promptPayNumber: '',
              bankName: 'Test Bank',
              bankAccountNumber: '123-456',
              bankAccountName: 'Owner Name',
              qrPayload: '',
              selectedUserName: 'Friend',
              amount: 240,
              isPaid: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ชำระเงินสำเร็จเรียบร้อยแล้ว! 🎉'), findsOneWidget);
    expect(find.textContaining('Test Bank 123-456'), findsOneWidget);
    expect(find.textContaining('โอนผ่านบัญชีธนาคาร'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
