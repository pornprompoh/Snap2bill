import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/providers/contact_provider.dart';
import 'package:snap2bill/providers/theme_provider.dart';
import 'package:snap2bill/providers/user_provider.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/theme/app_theme.dart';
import 'package:snap2bill/widgets/common/deep_link_handler.dart';

class Snap2BillApp extends StatelessWidget {
  const Snap2BillApp({super.key});

  static final _navigatorKey = GlobalKey<NavigatorState>();
  static final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        child: const _AppView(),
      ),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final hasSession = Supabase.instance.client.auth.currentSession != null;

    return MaterialApp(
      title: 'Snap2Bill',
      navigatorKey: Snap2BillApp._navigatorKey,
      scaffoldMessengerKey: Snap2BillApp._scaffoldMessengerKey,
      themeMode: themeProvider.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: hasSession ? AppRoutes.home : '/',
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
