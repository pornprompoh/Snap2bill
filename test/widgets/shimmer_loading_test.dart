import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/widgets/common/shimmer_loading.dart';

void main() {
  testWidgets('shimmer keeps its child visible and disposes its animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ShimmerEffect(child: Text('loading content'))),
      ),
    );
    expect(find.text('loading content'), findsOneWidget);

    await tester.pumpWidget(const Placeholder());
  });

  testWidgets('bill skeleton builds its placeholder layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BillCardSkeleton())),
    );
    await tester.pump();

    expect(find.byType(BillCardSkeleton), findsOneWidget);
    expect(find.byType(ShaderMask), findsOneWidget);
    await tester.pumpWidget(const Placeholder());
  });
}
