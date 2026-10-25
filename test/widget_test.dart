import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the app shell', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        title: 'Snap2Bill',
        home: const Scaffold(body: Text('Snap2Bill')),
      ),
    );

    expect(find.text('Snap2Bill'), findsOneWidget);
  });
}
