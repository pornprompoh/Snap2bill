import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🚀 นำเข้า dotenv
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'providers/bill_provider.dart';
import 'providers/contact_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/user_provider.dart';
import 'theme/app_theme.dart';
import 'package:snap2bill/widgets/deep_link_handler.dart';
import 'services/offline/offline_service.dart';
import 'widgets/common/offline_status_banner.dart';

final _navigatorKey = GlobalKey<NavigatorState>();
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 โหลดไฟล์ .env ก่อนเรียกใช้ตัวแปร
  await dotenv.load(fileName: ".env");

  // 🚀 เริ่มต้น Supabase โดยดึงค่าจาก .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey:
        dotenv.env['SUPABASE_ANON_KEY']!, // ใช้ anonKey สำหรับ Supabase
  );

  final offlineService = OfflineService();
  unawaited(offlineService.start());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<OfflineService>.value(value: offlineService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProxyProvider<ContactProvider, BillProvider>(
          create: (_) => BillProvider(),
          update: (_, contacts, bills) =>
              (bills ?? BillProvider())..setContactProvider(contacts),
        ),
      ],
      child: DeepLinkHandler(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => MaterialApp(
        title: 'Snap2Bill',
        onGenerateTitle: (context) => 'Snap2Bill',
        builder: (context, child) {
          return OfflineStatusBanner(
            child: Title(
              title: 'Snap2Bill',
              color: Theme.of(context).colorScheme.primary,
              child: child ?? const SizedBox(),
            ),
          );
        },
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.lightWithDynamicColors(lightDynamic),
        darkTheme: AppTheme.darkWithDynamicColors(darkDynamic),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
