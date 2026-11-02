import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/offline/offline_service.dart';

class OfflineStatusBanner extends StatelessWidget {
  final Widget child;

  const OfflineStatusBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<OfflineService>(
          builder: (context, offline, _) {
            if (offline.isOnline && !offline.isSyncing) {
              return const SizedBox.shrink();
            }
            return Material(
              color: offline.isSyncing
                  ? Colors.blue.shade700
                  : Colors.orange.shade800,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      offline.isSyncing
                          ? 'กำลังซิงก์ข้อมูลที่ค้างไว้...'
                          : 'ออฟไลน์: ข้อมูลจะถูกซิงก์เมื่อกลับมาออนไลน์',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        Expanded(child: child),
      ],
    );
  }
}
