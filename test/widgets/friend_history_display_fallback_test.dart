import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/models/user_model.dart';
import 'package:snap2bill/widgets/friends/friend_history_dialog.dart';

void main() {
  testWidgets('uses email or a fallback for friends without display names', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FriendHistoryDialog(
            loadFriends: () async => [
              UserModel(
                id: 'email-friend',
                displayName: '  ',
                email: 'friend@example.com',
              ),
              UserModel(id: 'unnamed-friend'),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('friend@example.com'), findsNWidgets(2));
    expect(find.text('ไม่มีชื่อ'), findsOneWidget);
  });
}
