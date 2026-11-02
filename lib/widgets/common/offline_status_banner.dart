import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/offline/offline_service.dart';
import '../../utils/mascot_assets.dart';

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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          offline.isSyncing
                              ? MascotAssets.thinking
                              : MascotAssets.phoneHappy,
                          width: 30,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.asset(
                                MascotAssets.fallback,
                                width: 30,
                                height: 30,
                                fit: BoxFit.contain,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            offline.isSyncing
                                ? 'กำลังซิงก์ข้อมูลที่ค้างไว้...'
                                : 'Bunny บันทึกข้อมูลไว้ก่อนนะ จะซิงก์เมื่อออนไลน์',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
