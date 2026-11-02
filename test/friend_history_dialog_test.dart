import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/widgets/common/mascot_state_view.dart';
import 'package:snap2bill/widgets/friends/friend_history_dialog.dart';

UserModel _user({
  String id = 'user-1',
  String name = 'เพื่อนจริง',
  String? email = 'friend@example.com',
}) {
  return UserModel(id: id, displayName: name, email: email);
}

Widget _host(Future<List<UserModel>> Function() loadFriends) {
  return MaterialApp(
    home: Scaffold(body: FriendHistoryDialog(loadFriends: loadFriends)),
  );
}

void main() {
  testWidgets('shows real friends in the reusable popup', (tester) async {
    await tester.pumpWidget(_host(() async => [_user()]));
    await tester.pumpAndSettle();

    expect(find.text('เพื่อนที่เคยหารบิล'), findsOneWidget);
    expect(find.text('เพื่อนจริง'), findsOneWidget);
    expect(find.text('friend@example.com'), findsOneWidget);
  });

  testWidgets('shows mascot when there are no past bill friends', (
    tester,
  ) async {
    await tester.pumpWidget(_host(() async => []));
    await tester.pumpAndSettle();

    expect(find.byType(MascotStateView), findsOneWidget);
    expect(find.text('ยังไม่มีเพื่อนที่เคยหารบิล'), findsOneWidget);
  });

  testWidgets('shows retry mascot when loading friends fails', (tester) async {
    await tester.pumpWidget(
      _host(() async => throw StateError('network unavailable')),
    );
    await tester.pumpAndSettle();

    expect(find.text('โหลดรายชื่อเพื่อนไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองใหม่'), findsOneWidget);
  });
}
