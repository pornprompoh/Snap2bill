import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:snap2bill/domain/repositories/bill_repository.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/providers/bill_provider.dart';
import 'package:snap2bill/screens/bill/review_screen.dart';

void main() {
  late BillProvider billProvider;

  setUp(() {
    billProvider = BillProvider(billRepository: _FakeBillRepository());
  });

  testWidgets('shows receipt mismatch and supports choosing calculated total', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      billProvider,
      receiptData: {
        'shop_name': 'Cafe',
        'final_total': 250,
        'items': [
          {'item_name': 'Coffee', 'qty': 1, 'unit_price': 100},
          {'item_name': 'Cake', 'qty': 1, 'unit_price': 50},
          {'item_name': '', 'qty': 1, 'unit_price': 20},
          {'item_name': 'Free item', 'qty': 1, 'unit_price': 0},
        ],
      },
    );

    expect(find.text('Cafe'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Cake'), findsOneWidget);
    expect(find.text('Free item'), findsNothing);
    expect(find.textContaining('ยอดรายการไม่ตรง'), findsOneWidget);

    await tester.ensureVisible(find.text('ใช้ยอดรายการอยู่'));
    await tester.tap(find.text('ใช้ TOTAL 250 ฿'));
    await tester.pumpAndSettle();
    expect(find.text('ใช้ TOTAL 250 ฿'), findsNothing);
    expect(find.text('ใช้ TOTAL ใบเสร็จ'), findsOneWidget);
  });

  testWidgets('edits shop header and adds, edits and removes receipt items', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      billProvider,
      receiptData: {
        'shop_name': 'Old shop',
        'items': [
          {'item_name': 'Tea', 'qty': 1, 'unit_price': 40},
        ],
      },
    );

    await tester.tap(find.text('Old shop'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '  New shop  ');
    await tester.enterText(find.byType(TextField).last, '5');
    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();
    expect(find.text('New shop'), findsOneWidget);

    await tester.ensureVisible(find.text('เพิ่มรายการอาหารเอง'));
    await tester.tap(find.text('เพิ่มรายการอาหารเอง'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Juice');
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.enterText(find.byType(TextField).at(2), '30');
    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();
    expect(find.text('Juice'), findsOneWidget);

    await tester.ensureVisible(find.text('Juice'));
    await tester.tap(find.byTooltip('แก้ไข').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Orange juice');
    await tester.enterText(find.byType(TextField).at(1), '3');
    await tester.enterText(find.byType(TextField).at(2), '25');
    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();
    expect(find.text('Orange juice'), findsOneWidget);

    await tester.ensureVisible(find.text('Orange juice'));
    await tester.tap(find.byTooltip('ลบ').last);
    await tester.pumpAndSettle();
    expect(find.text('Orange juice'), findsNothing);
  });

  testWidgets('calculates VAT and service charge and selects equal splitting', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      billProvider,
      receiptData: {
        'shop_name': 'Cafe',
        'items': [
          {'item_name': 'Coffee', 'qty': 2, 'unit_price': 100},
        ],
      },
    );

    await tester.ensureVisible(find.text('Service Charge 10%'));
    await tester.tap(find.byType(Switch).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).at(1));
    await tester.pumpAndSettle();
    expect(find.text('SVC 20 ฿'), findsOneWidget);
    expect(find.text('VAT 14 ฿'), findsOneWidget);

    await tester.ensureVisible(find.text('หารเท่าทุกคน'));
    await tester.tap(find.text('หารเท่าทุกคน'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('ยืนยัน & ชวนเพื่อน'));
    await tester.tap(find.text('ยืนยัน & ชวนเพื่อน'));
    await tester.pumpAndSettle();
    expect(billProvider.splitType, 'equal');
    expect(find.text('next room'), findsOneWidget);
  });

  testWidgets('allows entering an empty bill and displays its empty state', (
    tester,
  ) async {
    await _pumpReview(
      tester,
      billProvider,
      receiptData: {'shop_name': 'No items', 'items': []},
    );
    expect(find.text('ไม่มีรายการอาหาร'), findsOneWidget);

    await tester.tap(find.byTooltip('เพิ่มเมนูเอง'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Soup');
    await tester.enterText(find.byType(TextField).at(1), '1');
    await tester.enterText(find.byType(TextField).at(2), '0');
    await tester.tap(find.text('บันทึก').last);
    await tester.pumpAndSettle();
    expect(find.text('กรุณาระบุราคาที่มากกว่า 0 บาท'), findsOneWidget);
    await tester.tap(find.text('ยกเลิก'));
    await tester.pumpAndSettle();
  });
}

Future<void> _pumpReview(
  WidgetTester tester,
  BillProvider provider, {
  required Map<String, dynamic> receiptData,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<BillProvider>.value(
      value: provider,
      child: MaterialApp(
        routes: {'/lobby': (_) => const Scaffold(body: Text('next room'))},
        home: ReviewScreen(receiptData: receiptData),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeBillRepository implements BillRepository {
  @override
  String? get currentUserId => 'review-test-user';

  @override
  Future<List<BillModel>> getMyBills() async => [];

  @override
  Future<BillModel> createBill(String shopName, double totalAmount) async =>
      BillModel(
        id: 'review-test-bill',
        ownerId: currentUserId!,
        shopName: shopName,
        totalAmount: totalAmount,
      );

  @override
  Future<List<RoomMember>> getRoomGuestMembers(String roomCode) async => [];

  @override
  Future<RoomMember> addRoomGuestMember(
    String roomCode,
    RoomMember member,
  ) async => member;
}
