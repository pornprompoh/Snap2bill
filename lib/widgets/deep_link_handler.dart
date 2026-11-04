import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../services/auth/supabase_auth_service.dart';
import '../services/join/pending_join_store.dart';
import '../utils/join_link.dart';

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
  bool _isRoutingJoin = false;

  @override
  void initState() {
    super.initState();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (error) => debugPrint('Deep link stream error: $error'),
    );
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleIncomingLink(Uri.base);
      });
    }
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.scheme == 'snap2bill' && uri.host == 'login-callback') {
      return;
    }
    if (!JoinLink.isJoinUri(uri)) return;

    final roomId = JoinLink.roomIdFromUri(uri);
    final isRoomCode = roomId != null && RegExp(r'^\d{6}$').hasMatch(roomId);
    final isBillId =
        roomId != null &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(roomId);
    if (!isRoomCode && !isBillId) {
      _showLinkMessage('ลิงก์เข้าบิลหรือห้องไม่ถูกต้อง');
      return;
    }

    unawaited(_saveAndRouteJoin(roomId));
  }

  Future<void> _saveAndRouteJoin(String roomId) async {
    try {
      await const PendingJoinStore().save(roomId);
    } catch (error, stackTrace) {
      debugPrint('บันทึกลิงก์เข้าบิลไม่สำเร็จ: $error\n$stackTrace');
      _showLinkMessage('บันทึกลิงก์ไม่สำเร็จ กรุณาลองเปิดอีกครั้ง');
      return;
    }
    if (SupabaseAuthService().currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      });
      return;
    }

    _routeToJoin(roomId);
  }

  void _routeToJoin(String roomId) {
    if (_isRoutingJoin) return;
    _isRoutingJoin = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _isRoutingJoin = false;
        return;
      }
      widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AppRoutes.join,
        (route) => false,
        arguments: {'roomId': roomId},
      );
      _isRoutingJoin = false;
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
