import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snap2bill/theme/app_theme.dart';
import 'package:snap2bill/widgets/bill/member_summary_list.dart';

void main() {
  testWidgets('renders member roles, statuses and forwards row/status taps', (
    tester,
  ) async {
    final toggledIds = <String>[];
    String? tappedId;
    final members = [
      const MemberSummaryEntry(
        id: 'owner',
        name: 'Owner',
        amount: 100,
        isOwner: true,
      ),
      const MemberSummaryEntry(
        id: 'guest',
        name: 'Guest',
        amount: 50,
        isGuest: true,
        itemsCount: 2,
      ),
      const MemberSummaryEntry(
        id: 'paid',
        name: 'Paid Friend',
        amount: 50,
        status: 'paid',
      ),
      const MemberSummaryEntry(
        id: 'reviewing',
        name: 'Reviewing Friend',
        amount: 50,
        status: 'pending_verification',
        subtitle: 'receipt pending',
      ),
      const MemberSummaryEntry(
        id: 'pending',
        name: 'Pending Friend',
        amount: 50,
        status: 'pending',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberSummaryList(
            members: members,
            selectedMemberId: 'guest',
            onMemberTap: (id) => tappedId = id,
            onStatusToggle: (member) => toggledIds.add(member.id),
          ),
        ),
      ),
    );

    expect(find.text('Owner (เจ้าของ)'), findsOneWidget);
    expect(find.text('Guest (Guest / จ่ายแทน)'), findsOneWidget);
    expect(find.text('2 รายการ'), findsOneWidget);
    expect(find.text('จ่ายแล้ว'), findsOneWidget);
    expect(find.text('รอตรวจสอบ'), findsOneWidget);
    expect(find.text('receipt pending'), findsOneWidget);
    expect(find.text('รอจ่าย'), findsNWidgets(2));
    expect(
      tester.widget<ListTile>(find.byType(ListTile).at(1)).selected,
      isTrue,
    );

    await tester.tap(find.text('Paid Friend'));
    await tester.pump();
    expect(tappedId, 'paid');

    await tester.tap(find.text('จ่ายแล้ว'));
    await tester.pump();
    expect(toggledIds, ['paid']);

    await tester.tap(
      find.descendant(
        of: find.byType(ListTile).last,
        matching: find.text('รอจ่าย'),
      ),
    );
    await tester.pump();
    expect(toggledIds, ['paid', 'pending']);
  });

  testWidgets('status controls are disabled when viewer is not the owner', (
    tester,
  ) async {
    var statusChanged = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MemberSummaryList(
            members: const [
              MemberSummaryEntry(
                id: 'paid',
                name: 'Friend',
                amount: 80,
                status: 'paid',
              ),
            ],
            isCurrentViewerOwner: false,
            onStatusToggle: (_) => statusChanged = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('จ่ายแล้ว'));
    await tester.pump();
    expect(statusChanged, isFalse);
  });

  testWidgets('member amounts remain readable in dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: MemberSummaryList(
            members: const [
              MemberSummaryEntry(id: 'member', name: 'Friend', amount: 80),
            ],
          ),
        ),
      ),
    );

    final amount = tester.widget<Text>(find.text('80 ฿'));
    expect(amount.style?.color, AppTheme.dark.colorScheme.onSurface);
  });
}
