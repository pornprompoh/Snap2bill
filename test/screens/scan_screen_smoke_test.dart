import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/screens/bill/scan_screen.dart';

void main() {
  testWidgets('renders receipt scan prompt and both image sources', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ScanScreen()));

    expect(find.text('ถ่ายรูปใบเสร็จ'), findsOneWidget);
    expect(find.text('บันนี่พร้อมช่วยอ่านใบเสร็จแล้ว'), findsOneWidget);
    expect(find.text('ถ่ายรูป'), findsOneWidget);
    expect(find.text('คลังภาพ'), findsOneWidget);
    expect(find.text('ให้ AI ช่วยอ่านบิล ✨'), findsNothing);
  });

  testWidgets('uses dark theme colors without changing scan controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: ThemeData.dark(), home: const ScanScreen()),
    );

    expect(find.text('ถ่ายรูป'), findsOneWidget);
    expect(find.text('คลังภาพ'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
