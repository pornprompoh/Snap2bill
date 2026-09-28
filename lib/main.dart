import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🚀 นำเข้า dotenv
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'providers/bill_provider.dart';
import 'providers/user_provider.dart';
import 'services/supabase_auth_service.dart';
import 'theme/app_colors.dart';

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
      ],
      child: const _DeepLinkHandler(child: MyApp()),
    ),
  );
}

class _DeepLinkHandler extends StatefulWidget {
  final Widget child;

  const _DeepLinkHandler({required this.child});

  @override
  State<_DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<_DeepLinkHandler> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  String? _pendingRoomCode;
  bool _isOpeningRoom = false;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (error) => debugPrint('Deep link stream error: $error'),
    );
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      state,
    ) {
      if (state.session != null && _pendingRoomCode != null) {
        unawaited(_openPendingRoom());
      }
    });
  }

  String? _roomCodeFromUri(Uri uri) {
    final queryCode =
        uri.queryParameters['roomCode'] ??
        uri.queryParameters['room_code'] ??
        uri.queryParameters['code'];
    if (queryCode != null && queryCode.isNotEmpty) return queryCode;

    final pathSegments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (uri.scheme == 'snap2bill' &&
        uri.host == 'join' &&
        pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host == 'join' &&
        pathSegments.isNotEmpty) {
      return pathSegments.last;
    }
    return null;
  }

  void _handleIncomingLink(Uri uri) {
    final roomCode = _roomCodeFromUri(uri);
    if (roomCode == null || !RegExp(r'^\d{6}$').hasMatch(roomCode)) {
      _showLinkMessage('ลิงก์เข้าห้องไม่ถูกต้อง');
      return;
    }

    _pendingRoomCode = roomCode;
    if (SupabaseAuthService().currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      });
      return;
    }

    unawaited(_openPendingRoom());
  }

  Map<String, dynamic> _receiptDataFrom(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  Future<void> _openPendingRoom() async {
    final roomCode = _pendingRoomCode;
    final currentUser = SupabaseAuthService().currentUser;
    if (roomCode == null || currentUser == null || _isOpeningRoom) return;

    _isOpeningRoom = true;
    try {
      final room = await Supabase.instance.client
          .from('lobbies')
          .select('host_id, receipt_json')
          .eq('room_code', roomCode)
          .maybeSingle();

      if (room == null) {
        _pendingRoomCode = null;
        _showLinkMessage('ไม่พบห้องรหัส $roomCode');
        return;
      }

      final hostId = room['host_id']?.toString();
      final receiptData = _receiptDataFrom(room['receipt_json']);
      if (hostId != null) receiptData['owner_id'] = hostId;
      _pendingRoomCode = null;

      _navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.lobby,
        (route) => false,
        arguments: {
          'lobbyId': roomCode,
          'receiptData': receiptData,
          'isHost': hostId == currentUser.id,
        },
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to open room from deep link: $error\n$stackTrace');
      _showLinkMessage('เปิดห้องไม่สำเร็จ กรุณาลองอีกครั้ง');
    } finally {
      _isOpeningRoom = false;
    }
  }

  void _showLinkMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap2Bill',
      navigatorKey: _navigatorKey,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        useMaterial3: true,
      ),
      // OAuth returns to the app after Supabase has restored the session.
      initialRoute: Supabase.instance.client.auth.currentSession == null
          ? '/'
          : AppRoutes.home,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
