import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:snap2bill/screens/bill/personal_payment_details_screen.dart';
import 'package:snap2bill/services/offline/offline_service.dart';
import 'package:snap2bill/widgets/bill/member_summary_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockConnectivity extends Mock implements Connectivity {}
class _MockSupabaseClient extends Mock implements SupabaseClient {}

final _testClient = _MockSupabaseClient();

Future<OfflineService> _offlineService() async {
  final connectivity = _MockConnectivity();
  when(
    connectivity.checkConnectivity,
  ).thenAnswer((_) async => [ConnectivityResult.none]);
  when(
    () => connectivity.onConnectivityChanged,
  ).thenAnswer((_) => const Stream<List<ConnectivityResult>>.empty());
  final service = OfflineService(
    connectivity: connectivity,
    client: _testClient,
  );
  await service.start();
  return service;
}

MemberSummaryEntry _reviewingMember({bool isGuest = false}) {
  return MemberSummaryEntry(
    id: 'friend-1',
    name: 'เพื่อนรอตรวจ',
    amount: 125,
    status: 'reviewing',
    isGuest: isGuest,
    slipUrl:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
  );
}

Widget _paymentPage(
  OfflineService offline, {
  required MemberSummaryEntry member,
  required Map<String, dynamic> billData,
  required bool isOwner,
  void Function(String, String?)? onStatusChanged,
}) {
  return ChangeNotifierProvider.value(
    value: offline,
    child: MaterialApp(
      home: Scaffold(
        body: PersonalPaymentDetailsScreen(
          billData: billData,
          member: member,
          hostPromptPay: '0812345678',
          hostPromptPayType: 'phone',
          hostBankAccountNumber: '',
          hostName: 'เจ้าของบิล',
          isCurrentViewerOwner: isOwner,
          onStatusChanged: onStatusChanged,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('approves a verified slip and notifies the parent', (
    tester,
  ) async {
    print('start test');
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    final offline = await _offlineService();
    print('service started');
    final billData = <String, dynamic>{'receipt_json': <String, dynamic>{}};
    final statusUpdates = <String>[];
    await tester.pumpWidget(
      _paymentPage(
        offline,
        member: _reviewingMember(),
        billData: billData,
        isOwner: true,
        onStatusChanged: (status, _) => statusUpdates.add(status),
      ),
    );
    print('widget mounted');

    await tester.ensureVisible(find.text('ยืนยันชำระเงิน'));
    print('button visible');
    await tester.tap(find.text('ยืนยันชำระเงิน'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    print('button handled');

    expect(statusUpdates, ['paid']);
    expect(find.text('ชำระเงินสำเร็จเรียบร้อยแล้ว 🎉'), findsOneWidget);
    print('assertions passed');
    await tester.pumpWidget(const SizedBox.shrink());
    print('widget removed');
    await offline.disposeService();
    print('service disposed');
  });

  testWidgets('rejects a slip and allows it to be replaced', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    final offline = await _offlineService();
    final billData = <String, dynamic>{'receipt_json': <String, dynamic>{}};
    final statusUpdates = <String>[];
    await tester.pumpWidget(
      _paymentPage(
        offline,
        member: _reviewingMember(isGuest: true),
        billData: billData,
        isOwner: true,
        onStatusChanged: (status, slip) {
          statusUpdates.add('$status:${slip ?? 'none'}');
        },
      ),
    );

    await tester.ensureVisible(find.text('ปฏิเสธสลิป'));
    await tester.tap(find.text('ปฏิเสธสลิป'));
    await tester.pumpAndSettle();

    expect(statusUpdates, ['pending:none']);
    expect(find.textContaining('แนบหลักฐานการโอนเงิน'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await offline.disposeService();
  });

  testWidgets('renders owner and bank-transfer payment states', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    final owner = const MemberSummaryEntry(
      id: 'owner-1',
      name: 'เจ้าของ',
      amount: 200,
      isOwner: true,
    );
    final offline = await _offlineService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: offline,
        child: MaterialApp(
          home: Scaffold(
            body: PersonalPaymentDetailsScreen(
              billData: const {'id': 'bill-owner'},
              member: owner,
              hostPromptPay: '',
              hostBankAccountNumber: '',
              hostName: 'เจ้าของ',
              isCurrentViewerOwner: true,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('คุณเป็นเจ้าของบิล'), findsOneWidget);
    expect(find.textContaining('ไม่ต้องชำระเงินให้ตนเอง'), findsOneWidget);
    expect(find.text('ระบบแจ้งและยืนยันการชำระเงิน'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await offline.disposeService();

    final bankOnlyOffline = await _offlineService();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: bankOnlyOffline,
        child: MaterialApp(
          home: Scaffold(
            body: PersonalPaymentDetailsScreen(
              billData: const {'id': 'bill-bank'},
              member: const MemberSummaryEntry(
                id: 'friend-bank',
                name: 'เพื่อนโอนบัญชี',
                amount: 80,
              ),
              hostPromptPay: '',
              hostBankName: 'ธนาคารทดสอบ',
              hostBankAccountNumber: '1234567890',
              hostBankAccountName: 'ชื่อบัญชี',
              hostName: 'เจ้าของบิล',
              isCurrentViewerOwner: false,
            ),
          ),
        ),
      ),
    );
    expect(find.textContaining('ธนาคารทดสอบ'), findsOneWidget);
    expect(find.textContaining('1234567890'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await bankOnlyOffline.disposeService();
  });
}
