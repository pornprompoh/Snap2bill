import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../routes/app_routes.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_db_service.dart';

class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;

  const DeepLinkHandler({
    super.key,
    required this.child,
    required this.navigatorKey,
    required this.scaffoldMessengerKey,
  });

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<User?>? _authSubscription;
  String? _pendingRoomCode;
  bool _isOpeningRoom = false;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (error) => debugPrint('Deep link stream error: $error'),
    );
    _authSubscription = FirebaseAuthService().authStateChanges.listen((user) {
      if (user != null && _pendingRoomCode != null) {
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
    if (FirebaseAuthService().currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
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
    final currentUser = FirebaseAuthService().currentUser;
    if (roomCode == null || currentUser == null || _isOpeningRoom) return;

    _isOpeningRoom = true;
    try {
      final room = await FirebaseDbService().getLobby(roomCode);

      if (room == null) {
        _pendingRoomCode = null;
        _showLinkMessage('ไม่พบห้องรหัส $roomCode');
        return;
      }

      final hostId = room['host_id']?.toString();
      final receiptData = _receiptDataFrom(room['receipt_json']);
      if (hostId != null) receiptData['owner_id'] = hostId;
      _pendingRoomCode = null;

      widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.lobby,
        (route) => false,
        arguments: {
          'lobbyId': roomCode,
          'receiptData': receiptData,
          'isHost': hostId == currentUser.uid,
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
      widget.scaffoldMessengerKey.currentState?.showSnackBar(
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
