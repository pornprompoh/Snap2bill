import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/common/splash_screen.dart';

void main() {
  testWidgets('Facebook OAuth fragment opens the splash screen', (
    tester,
  ) async {
    late Widget routedWidget;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final route = AppRoutes.generateRoute(
            const RouteSettings(name: '=_='),
          ) as MaterialPageRoute<dynamic>;
          routedWidget = route.builder(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(routedWidget, isA<SplashScreen>());
  });

  testWidgets('web root opens the splash screen', (tester) async {
    late Widget routedWidget;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final route = AppRoutes.generateRoute(
            const RouteSettings(name: '/?code=oauth-callback'),
          ) as MaterialPageRoute<dynamic>;
          routedWidget = route.builder(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(routedWidget, isA<SplashScreen>());
  });
}
