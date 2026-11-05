import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/theme/app_colors.dart';
import 'package:snap2bill/widgets/common/custom_top_app_bar.dart';

void main() {
  testWidgets('renders title, unread badge, and optional actions', (
    tester,
  ) async {
    var notifications = 0;
    var friends = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: CustomTopAppBar(
            title: 'Bill history',
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
            unreadCount: 3,
            onNotificationsPressed: () => notifications++,
            onFriendsPressed: () => friends++,
          ),
        ),
      ),
    );

    expect(find.text('Bill history'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    tester
        .widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.notifications_none_rounded),
            matching: find.byType(IconButton),
          ),
        )
        .onPressed!();
    tester
        .widget<IconButton>(
          find.ancestor(
            of: find.byIcon(Icons.people_alt_outlined),
            matching: find.byType(IconButton),
          ),
        )
        .onPressed!();
    expect(notifications, 1);
    expect(friends, 1);
    expect(
      const CustomTopAppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
      ).preferredSize,
      const Size.fromHeight(kToolbarHeight),
    );
  });

  testWidgets('omits actions and unread badge when not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: CustomTopAppBar(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
            unreadCount: 8,
          ),
        ),
      ),
    );

    expect(find.text('Snap2Bill'), findsOneWidget);
    expect(find.byTooltip('การแจ้งเตือน'), findsNothing);
    expect(find.byTooltip('เพื่อนในตี้'), findsNothing);
    expect(find.text('8'), findsNothing);
  });
}
