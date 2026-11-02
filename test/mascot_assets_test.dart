import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/utils/mascot_assets.dart';

void main() {
  test('all mascot state assets exist in the repository', () {
    const assets = [
      MascotAssets.fallback,
      MascotAssets.waving,
      MascotAssets.phoneHappy,
      MascotAssets.worried,
      MascotAssets.cheering,
      MascotAssets.happyReceipt,
      MascotAssets.thinking,
    ];

    for (final asset in assets) {
      expect(File(asset).existsSync(), isTrue, reason: asset);
      expect(File(asset).lengthSync(), greaterThan(0), reason: asset);
    }
  });
}
