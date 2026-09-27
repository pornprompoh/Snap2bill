import 'dart:io';
import 'package:flutter/material.dart';

// นำเข้าหน้าจอทั้งหมด
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
import '../screens/detail_screen.dart';
import '../screens/main_screen.dart';
class AppRoutes {
  // ประกาศชื่อ Route ต่างๆ
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

  // ฟังก์ชันจัดการการเปลี่ยนหน้า
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/': // หน้าแรกสุดของแอป
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanScreen());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case friends:
        return MaterialPageRoute(builder: (_) => const FriendListScreen());
        
      // ส่วนที่มีการส่งข้อมูลพ่วงไปด้วย (Arguments)
      case detail:
        final billData = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(builder: (_) => DetailScreen(billData: billData));
      case loading:
        final image = settings.arguments as File;
        return MaterialPageRoute(builder: (_) => LoadingScreen(image: image));
      case review:
        final receiptData = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => ReviewScreen(receiptData: receiptData));
      case lobby:
        final receiptData = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(builder: (_) => LobbyScreen(receiptData: receiptData));
      case claim:
        // 🚀 ป้องกันค่า null โดยการบังคับแปลงเป็น Map ถ้ายิงมาผิดให้เป็น Map ว่าง
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ClaimScreen(
            lobbyId: args['lobbyId'] ?? 'unknown_room',
            receiptData: args['receiptData'] ?? {},
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
        // กรณีเรียก Route ผิด
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('ไม่มีหน้าจอสำหรับ Route: ${settings.name}'),
            ),
          ),
        );
    }
  }
}