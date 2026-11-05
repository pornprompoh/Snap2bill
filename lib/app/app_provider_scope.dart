import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bill_provider.dart';
import '../providers/contact_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/offline/offline_service.dart';
import '../widgets/deep_link_handler.dart';
import 'app_keys.dart';
import 'auth_notification_lifecycle.dart';
import 'snap2bill_app.dart';

class AppProviderScope extends StatelessWidget {
  final OfflineService offlineService;

  const AppProviderScope({super.key, required this.offlineService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OfflineService>.value(value: offlineService),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<OfflineService, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, offline, user) =>
              (user ?? UserProvider())..setOfflineService(offline),
        ),
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProxyProvider2<
          ContactProvider,
          OfflineService,
          BillProvider
        >(
          create: (_) => BillProvider(),
          update: (_, contacts, offline, bills) => (bills ?? BillProvider())
            ..setContactProvider(contacts)
            ..setOfflineService(offline),
        ),
      ],
      child: DeepLinkHandler(
        navigatorKey: AppKeys.navigator,
        scaffoldMessengerKey: AppKeys.scaffoldMessenger,
        child: AuthNotificationLifecycle(
          offlineService: offlineService,
          child: const Snap2BillApp(),
        ),
      ),
    );
  }
}
