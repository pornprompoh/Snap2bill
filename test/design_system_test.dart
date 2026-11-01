import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/theme/app_colors.dart';
import 'package:snap2bill/theme/app_design_system.dart';

void main() {
  group('Design system', () {
    test('breakpoints map widths to window size classes', () {
      expect(Responsive.fromWidth(360), AppWindowSize.compact);
      expect(Responsive.fromWidth(700), AppWindowSize.medium);
      expect(Responsive.fromWidth(1280), AppWindowSize.expanded);
    });

    test('apply() keeps Material 3 and adds component themes', () {
      final t = AppDesignSystem.apply(
        ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        ),
      );
      expect(t.useMaterial3, isTrue);
      expect(t.cardTheme.shape, isNotNull);
      expect(t.dialogTheme.shape, isNotNull);
      expect(t.bottomSheetTheme.showDragHandle, isTrue);
    });

    testWidgets('ResponsiveCenter limits content width on wide screens',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: ResponsiveCenter(child: SizedBox.expand(key: Key('c'))),
        ),
      );
      expect(tester.getSize(find.byKey(const Key('c'))).width,
          AppBreakpoints.maxContentWidth);
    });
  });
}
