import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/utils/join_link.dart';

void main() {
  group('JoinLink', () {
    test('builds the production web hash URL with a roomId query', () {
      expect(
        JoinLink.forRoom('123456'),
        'https://snap2bill.vercel.app/#/join?roomId=123456',
      );
    });

    test('reads a room id from the web hash route', () {
      final uri = Uri.parse(
        'https://snap2bill.vercel.app/#/join?roomId=123456',
      );

      expect(JoinLink.isJoinUri(uri), isTrue);
      expect(JoinLink.roomIdFromUri(uri), '123456');
    });

    test('reads billId and legacy app-link identifiers', () {
      expect(
        JoinLink.roomIdFromUri(
          Uri.parse('https://snap2bill.vercel.app/#/join?billId=abc'),
        ),
        'abc',
      );
      expect(
        JoinLink.roomIdFromUri(Uri.parse('snap2bill://join/123456')),
        '123456',
      );
    });
  });
}
