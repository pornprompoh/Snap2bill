import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/common/loading_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.loadFromString(envString: 'GEMINI_API_KEY=');
  });

  testWidgets('returns to the previous route when OCR has no API key', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.loading),
              child: const Text('open scanner result'),
            ),
          ),
        ),
        routes: {
          AppRoutes.loading: (_) =>
              LoadingScreen(imageBytes: Uint8List.fromList([1, 2, 3])),
        },
      ),
    );

    await tester.tap(find.text('open scanner result'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('open scanner result'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
