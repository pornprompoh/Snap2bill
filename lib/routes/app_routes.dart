import 'dart:io';
import 'package:flutter/material.dart';

// Import หน้าจอทั้งหมด
import '../screens/auth/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/review_screen.dart';
import '../screens/lobby_screen.dart';
import '../screens/claim_screen.dart';
import '../screens/summary_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/friends/friend_list_screen.dart';

class AppRoutes {
  // กำหนดชื่อ Route เป็นค่าคงที่
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

  // ฟังก์ชันควบคุมการเปลี่ยนหน้าและส่งพารามิเตอร์
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case friends: // 🚀 เพิ่มเคสนี้
        return MaterialPageRoute(builder: (_) => const FriendListScreen());

        
      case loading:
        final imageFile = settings.arguments as File;
        return MaterialPageRoute(builder: (_) => LoadingScreen(image: imageFile));
        
      case review:
        final receiptData = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => ReviewScreen(receiptData: receiptData));
        
      case lobby:
        final receiptData = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => LobbyScreen(receiptData: receiptData));
        
      case claim:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ClaimScreen(
            lobbyId: args['lobbyId'],
            receiptData: args['receiptData'],
          ),
        );
        
      case summary:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => SummaryScreen(
            lobbyId: args['lobbyId'],
            receiptData: args['receiptData'],
            itemSharers: args['itemSharers'],
          ),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('ไม่มีหน้าจอสำหรับ Route: ${settings.name}')),
          ),
        );
    }
  }
}