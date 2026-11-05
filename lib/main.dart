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
import 'services/notifications/in_app_notification_service.dart';
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
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _scaffoldMessengerKey,
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<AuthState>? _authStateSubscription;
  late final OfflineService _offlineService;

  @override
  void initState() {
    super.initState();
    _offlineService = context.read<OfflineService>()
      ..addListener(_handleConnectivityChanged);
    unawaited(
      _configureNotifications(Supabase.instance.client.auth.currentUser?.id),
    );
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen((authState) {
          unawaited(_configureNotifications(authState.session?.user.id));
        });
  }

  Future<void> _configureNotifications(String? userId) async {
    final service = InAppNotificationService.instance;
    try {
      if (userId == null) {
        await service.stopListening();
        service.unreadCount.value = 0;
        service.notifications.value = [];
        return;
      }
      if (_offlineService.isOffline) {
        await service.stopListening();
        return;
      }

      await service.listenToUser(
        userId,
        onNotification: (item) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        },
        onConnectionError: _offlineService.reportNetworkFailure,
      );
    } catch (error, stackTrace) {
      debugPrint('In-app notification setup failed: $error\n$stackTrace');
      _offlineService.reportNetworkFailure(error);
    }
  }

  void _handleConnectivityChanged() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (_offlineService.isOffline) {
      unawaited(InAppNotificationService.instance.stopListening());
    } else {
      unawaited(_configureNotifications(userId));
    }
  }

  @override
  void dispose() {
    _offlineService.removeListener(_handleConnectivityChanged);
    _authStateSubscription?.cancel();
    unawaited(InAppNotificationService.instance.stopListening());
    super.dispose();
  }

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
