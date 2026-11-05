import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/notifications/in_app_notification_service.dart';
import '../services/offline/offline_service.dart';
import 'app_keys.dart';

class AuthNotificationLifecycle extends StatefulWidget {
  final OfflineService offlineService;
  final Widget child;

  const AuthNotificationLifecycle({
    super.key,
    required this.offlineService,
    required this.child,
  });

  @override
  State<AuthNotificationLifecycle> createState() =>
      _AuthNotificationLifecycleState();
}

class _AuthNotificationLifecycleState extends State<AuthNotificationLifecycle> {
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    widget.offlineService.addListener(_handleConnectivityChanged);
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
      if (widget.offlineService.isOffline) {
        await service.stopListening();
        return;
      }

      await service.listenToUser(
        userId,
        onNotification: _showNotification,
        onConnectionError: widget.offlineService.reportNetworkFailure,
      );
    } catch (error, stackTrace) {
      debugPrint('In-app notification setup failed: $error\n$stackTrace');
      widget.offlineService.reportNetworkFailure(error);
    }
  }

  void _showNotification(InAppNotificationItem item) {
    AppKeys.scaffoldMessenger.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleConnectivityChanged() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (widget.offlineService.isOffline) {
      unawaited(InAppNotificationService.instance.stopListening());
    } else {
      unawaited(_configureNotifications(userId));
    }
  }

  @override
  void dispose() {
    widget.offlineService.removeListener(_handleConnectivityChanged);
    _authStateSubscription?.cancel();
    unawaited(InAppNotificationService.instance.stopListening());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
