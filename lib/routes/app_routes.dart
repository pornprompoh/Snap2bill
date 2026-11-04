import 'package:flutter/material.dart';
import 'dart:typed_data';

import '../screens/auth/login_screen.dart';
import '../screens/common/loading_screen.dart';
import '../screens/common/splash_screen.dart';
import '../screens/common/onboarding_screen.dart';
import '../screens/bill/review_screen.dart';
import '../screens/bill/lobby_screen.dart';
import '../screens/bill/claim_screen.dart';
import '../screens/bill/summary_screen.dart';
import '../screens/friends/friend_list_screen.dart';
import '../screens/bill/detail_screen.dart';
import '../screens/bill/join_room_screen.dart';
import '../screens/main/main_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String scan = '/scan';
  static const String loading = '/loading';
  static const String review = '/review';
  static const String lobby = '/lobby';
  static const String claim = '/claim';
  static const String summary = '/summary';
  static const String profile = '/profile';
  static const String friends = '/friends';
  static const String detail = '/detail';
  static const String join = '/join';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    String routeName = settings.name ?? '/';
    final hashRouteIndex = routeName.indexOf('#');
    if (hashRouteIndex >= 0) {
      routeName = routeName.substring(hashRouteIndex + 1);
    }
    final routeUri = Uri.tryParse(routeName);
    final queryParameters = routeUri?.queryParameters ?? const {};
    if (routeName.contains('?')) {
      routeName = routeName.split('?')[0];
    }

    switch (routeName) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/':
      case '=_=':
      case '/_=_':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        final destinationRoute = settings.arguments as String? ?? login;
        return MaterialPageRoute(
          builder: (_) => OnboardingScreen(destinationRoute: destinationRoute),
        );
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case join:
        final args = settings.arguments;
        final arguments = args is Map ? args : const {};
        final roomId =
            arguments['roomId']?.toString() ??
            arguments['billId']?.toString() ??
            queryParameters['roomId'] ??
            queryParameters['billId'] ??
            queryParameters['roomCode'] ??
            queryParameters['room_code'];
        return MaterialPageRoute(
          builder: (_) => JoinRoomScreen(roomId: roomId),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case scan:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 1),
        );
      case profile:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(initialIndex: 2),
        );
      case friends:
        final selectionMode = settings.arguments == true;
        return MaterialPageRoute(
          builder: (_) => FriendListScreen(selectionMode: selectionMode),
        );

      case detail:
        final billData = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => DetailScreen(billData: billData),
        );

      case loading:
        final imageBytes = settings.arguments as Uint8List;
        return MaterialPageRoute(
          builder: (_) => LoadingScreen(imageBytes: imageBytes),
        );

      case review:
        final args = settings.arguments;
        final receiptData = args is Map && args['receiptData'] is Map
            ? Map<String, dynamic>.from(args['receiptData'] as Map)
            : Map<String, dynamic>.from(args as Map? ?? {});
        final receiptImageBytes = args is Map
            ? args['receiptImageBytes'] as Uint8List?
            : null;
        return MaterialPageRoute(
          builder: (_) => ReviewScreen(
            receiptData: receiptData,
            receiptImageBytes: receiptImageBytes,
          ),
        );

      case lobby:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        String? lobbyId = args['lobbyId']?.toString();
        Map<String, dynamic>? receiptData = args['receiptData'];
        if (receiptData == null && args.containsKey('items')) {
          receiptData = args;
        }

        // 🚀 เพิ่มรับค่า isHost
        bool isHost = args['isHost'] ?? true;

        return MaterialPageRoute(
          builder: (_) => LobbyScreen(
            lobbyId: lobbyId,
            receiptData: receiptData,
            receiptImageBytes: args['receiptImageBytes'] as Uint8List?,
            isHost: isHost,
          ),
        );

      case claim:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ClaimScreen(
            lobbyId: args['lobbyId']?.toString() ?? 'unknown_room',
            receiptData: args['receiptData'] ?? {},
            roomParticipants: (args['roomParticipants'] as List<dynamic>? ?? [])
                .whereType<Map>()
                .map((participant) => Map<String, dynamic>.from(participant))
                .toList(),
            receiptImageBytes: args['receiptImageBytes'] as Uint8List?,
            isHost: args['isHost'] ?? true, // 🚀 เพิ่มรับค่า isHost
          ),
        );

      case summary:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => SummaryScreen(
            lobbyId: args['lobbyId']?.toString() ?? '',
            receiptData: args['receiptData'] ?? {},
            itemSharers: args['itemSharers'] ?? {},
            roomParticipants: (args['roomParticipants'] as List<dynamic>? ?? [])
                .whereType<Map>()
                .map((participant) => Map<String, dynamic>.from(participant))
                .toList(),
            receiptImageBytes: args['receiptImageBytes'] as Uint8List?,
            isHost: args['isHost'] ?? true, // 🚀 เพิ่มรับค่า isHost
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('ไม่มีหน้าจอสำหรับ Route: $routeName')),
          ),
        );
    }
  }
}
