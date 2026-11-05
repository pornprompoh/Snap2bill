import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/widgets/common/mascot_state_view.dart';

void main() {
  testWidgets('renders message, detail, and optional retry action', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MascotStateView(
            state: MascotState.error,
            message: 'Could not load',
            detail: 'Check your connection',
            onRetry: () => retries++,
            size: 64,
          ),
        ),
      ),
    );

    expect(find.text('Could not load'), findsOneWidget);
    expect(find.text('Check your connection'), findsOneWidget);
    await tester.tap(find.text('ลองใหม่'));
    expect(retries, 1);
  });

  testWidgets('omits blank message and optional detail', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MascotStateView(state: MascotState.empty, message: '  '),
        ),
      ),
    );

    expect(find.byType(MascotStateView), findsOneWidget);
    expect(find.text('ลองใหม่'), findsNothing);
  });

  testWidgets('supports every mascot state', (tester) async {
    for (final state in MascotState.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MascotStateView(state: state, message: state.name, size: 48),
          ),
        ),
      );
      expect(find.text(state.name), findsOneWidget);
      expect(find.bySemanticsLabel('Snap2Bill Bunny'), findsOneWidget);
    }

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
