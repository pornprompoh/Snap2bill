import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/common/offline_status_banner.dart';
import 'app_keys.dart';

class Snap2BillApp extends StatelessWidget {
  const Snap2BillApp({super.key});

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
        navigatorKey: AppKeys.navigator,
        scaffoldMessengerKey: AppKeys.scaffoldMessenger,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.lightWithDynamicColors(lightDynamic),
        darkTheme: AppTheme.darkWithDynamicColors(darkDynamic),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
