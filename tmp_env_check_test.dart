import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('env', () {
    print('FLUTTER_TEST=${Platform.environment['FLUTTER_TEST']}');
    print('UNIT_TEST=${Platform.environment['UNIT_TEST']}');
    print('dart.vm.product=${const bool.fromEnvironment('dart.vm.product')}');
    print('all env keys=${Platform.environment.keys.toList().where((k) => k.contains('TEST') || k.contains('flutter') || k.contains('dart')).toList()}');
  });
}
