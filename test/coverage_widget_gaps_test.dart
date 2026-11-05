import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/providers/contact_provider.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:snap2bill/utils/bill_progress_helper.dart';
import 'package:snap2bill/widgets/bill/guest_dialog.dart';
import 'package:snap2bill/widgets/bill/shareable_receipt_card.dart';
import 'package:snap2bill/widgets/common/cached_avatar.dart';
import 'package:snap2bill/widgets/common/custom_bottom_nav_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _summary = BillProgressSummary(
  totalAmount: 120,
  shopName: 'Cafe Widget Test',
  ownerId: 'owner-1',
  totalMembers: 2,
  totalPayingCount: 1,
  paidCount: 0,
  unpaidCount: 1,
  percentage: 0,
  averagePerPerson: 60,
  equalPerPerson: 60,
  isEqualSplit: true,
  isSettled: false,
  unpaidMembers: [
    BillParticipantStatus(
      id: 'friend-1',
      name: 'Friend',
      amount: 60,
      isOwner: false,
      isPaid: false,
      isGuest: false,
    ),
  ],
  allMembers: [
    BillParticipantStatus(
      id: 'owner-1',
      name: 'Owner',
      amount: 60,
      isOwner: true,
      isPaid: false,
      isGuest: false,
    ),
    BillParticipantStatus(
      id: 'friend-1',
      name: 'Friend',
      amount: 60,
      isOwner: false,
      isPaid: false,
      isGuest: false,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    try {
      await Supabase.initialize(
        url: 'https://widget-gap-test.supabase.co',
        publishableKey: 'widget-gap-test-key',
      );
    } catch (_) {}
  });

  testWidgets('GuestDialog displays load errors and returns trimmed names', (
    tester,
  ) async {
    final provider = _IdleContactProvider();
    final controller = TextEditingController();
    late Future<String?> dialogResult;

    await tester.pumpWidget(
      ChangeNotifierProvider<ContactProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  dialogResult = showDialog<String>(
                    context: context,
                    builder: (_) => GuestDialog(controller: controller),
                  );
                },
                child: const Text('open guest dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open guest dialog'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มเพื่อนที่ไม่มีแอป'), findsOneWidget);
    expect(find.text('ยังไม่มีรายชื่อที่บันทึกไว้'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  Guest Friend  ');
    await tester.pump();
    await tester.tap(find.text('เพิ่มชื่อที่พิมพ์'));
    await tester.pumpAndSettle();
    expect(await dialogResult, 'Guest Friend');

    controller.dispose();
    provider.dispose();
  });

  testWidgets(
    'CachedAvatar uses its placeholder for offline and invalid URLs',
    (tester) async {
      final offline = OfflineService()
        ..reportNetworkFailure(const SocketException('network unavailable'));
      addTearDown(offline.disposeService);

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: offline,
          child: const MaterialApp(
            home: Scaffold(
              body: CachedAvatar(
                imageUrl: 'https://example.test/avatar.png',
                size: 48,
                placeholder: Text('avatar placeholder'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('avatar placeholder'), findsOneWidget);

      await tester.pumpWidget(
        ChangeNotifierProvider<OfflineService>.value(
          value: offline..reportNetworkFailure(Exception('network')),
          child: const MaterialApp(
            home: Scaffold(
              body: CachedAvatar(
                imageUrl: 'not-a-url',
                size: 48,
                placeholder: Text('invalid avatar placeholder'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('invalid avatar placeholder'), findsOneWidget);
    },
  );

  testWidgets('CustomBottomNavBar renders selection and reports tapped index', (
    tester,
  ) async {
    var selectedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 1,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    expect(find.text('ประวัติบิล'), findsOneWidget);
    expect(find.text('แสกน'), findsOneWidget);
    expect(find.text('โปรไฟล์'), findsOneWidget);
    await tester.tap(find.text('โปรไฟล์'));
    expect(selectedIndex, 2);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: 0,
            onTap: (index) => selectedIndex = index,
          ),
        ),
      ),
    );
    expect(selectedIndex, 2);
    expect(find.text('ประวัติบิล'), findsOneWidget);
  });

  testWidgets('ShareableReceiptCard renders a valid payment QR and bill info', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ShareableReceiptCard(
              bill: {
                'id': 'bill-12345678',
                'created_at': '2026-11-05T10:00:00Z',
                'image_url': 'not-a-valid-image-url',
              },
              summary: _summary,
              hostPromptPay: '0812345678',
              hostPromptPayType: 'phone',
              hostBankAccount: '123-456',
              hostBankName: 'Test Bank',
              hostName: 'Bill Owner',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SNAP2BILL RECEIPT'), findsOneWidget);
    expect(find.text('Cafe Widget Test'), findsOneWidget);
    expect(find.text('#BILL-123'), findsOneWidget);
    expect(find.text('พร้อมเพย์: 081-xxx-5678'), findsOneWidget);
    expect(find.textContaining('Test Bank 123-456'), findsOneWidget);
    expect(find.textContaining('Friend'), findsWidgets);
  });
}

class _IdleContactProvider extends ContactProvider {
  @override
  Future<void> loadContacts() async {}
}
