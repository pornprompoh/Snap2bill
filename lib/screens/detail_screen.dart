import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../utils/formatters.dart';
import '../widgets/bill/member_summary_list.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> billData;

  const DetailScreen({super.key, required this.billData});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<List<MemberSummaryEntry>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMemberSummary();
  }

  Future<List<MemberSummaryEntry>> _loadMemberSummary() async {
    final receipt = _asMap(widget.billData['receipt_json']);
    final sharersByItem = _asMap(widget.billData['sharers_json']);
    final billId = widget.billData['id']?.toString();
    final participantRows = billId == null
        ? <dynamic>[]
        : await Supabase.instance.client
              .from('bill_participants')
              .select('profile_id, amount_owed, status')
              .eq('bill_id', billId);

    final profileIds = participantRows
        .map((row) => row['profile_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final namesById = <String, String>{};

    final items = <BillItemModel>[];
    final rawItems = receipt['items'] as List<dynamic>? ?? [];
    for (var index = 0; index < rawItems.length; index++) {
      final rawItem = _asMap(rawItems[index]);
      final personalQuantities = <String, int>{};
      final sharedUsers = <String>{};
      final itemSharers =
          sharersByItem[index.toString()] as List<dynamic>? ?? [];

      for (final rawSharer in itemSharers) {
        final sharer = _asMap(rawSharer);
        final userId = sharer['user_id']?.toString() ?? '';
        if (userId.isEmpty) continue;
        final userName = sharer['user_name']?.toString();
        if (userName?.isNotEmpty == true) namesById[userId] = userName!;
        final quantity = int.tryParse(sharer['quantity']?.toString() ?? '') ?? 0;
        if (quantity > 0) personalQuantities[userId] = quantity;
        if (sharer['is_shared'] == true) sharedUsers.add(userId);
      }

      final rawClaims =
          rawItem['userQuantities'] ??
          rawItem['claims'] ??
          rawItem['user_quantities'];
      if (itemSharers.isEmpty && rawClaims is Map) {
        rawClaims.forEach((userId, quantity) {
          final count = int.tryParse(quantity.toString()) ?? 0;
          if (count > 0) personalQuantities[userId.toString()] = count;
        });
      }
      if (itemSharers.isEmpty) {
        final rawShared =
            rawItem['sharedUsers'] ??
            rawItem['shared_claims'] ??
            rawItem['shared_users'];
        if (rawShared is List) {
          sharedUsers.addAll(rawShared.map((id) => id.toString()));
        }
      }

      final quantity =
          int.tryParse(
            (rawItem['qty'] ?? rawItem['quantity'] ?? 1).toString(),
          ) ??
          1;
      items.add(
        BillItemModel(
          id: index.toString(),
          billId: billId ?? '',
          itemName: rawItem['item_name']?.toString() ?? 'ไม่มีชื่อ',
          price:
              double.tryParse(
                (rawItem['unit_price'] ?? rawItem['price'] ?? 0).toString(),
              ) ??
              0,
          quantity: quantity,
          userQuantities: personalQuantities,
          sharedUsers: sharedUsers.toList(),
          claimedBy: personalQuantities.keys.toList(),
        ),
      );
    }

    for (final item in items) {
      profileIds.addAll(
        item.userQuantities.keys.where((id) => !id.startsWith('guest_')),
      );
      profileIds.addAll(
        item.sharedUsers.where((id) => !id.startsWith('guest_')),
      );
    }
    final profilesById = <String, Map<String, dynamic>>{};
    if (profileIds.isNotEmpty) {
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('id, display_name, email')
          .inFilter('id', profileIds.toList());
      for (final profile in profiles) {
        profilesById[profile['id'].toString()] =
            Map<String, dynamic>.from(profile);
      }
    }
    for (final profile in profilesById.entries) {
      final name = profile.value['display_name']?.toString().trim();
      namesById.putIfAbsent(
        profile.key,
        () => name?.isNotEmpty == true
            ? name!
            : profile.value['email']?.toString().split('@').first ?? 'เพื่อน',
      );
    }

    final participantIds = <String>{
      ...profileIds,
      for (final item in items) ...item.userQuantities.keys,
      for (final item in items) ...item.sharedUsers,
    };
    final finalTotal =
        double.tryParse(
          (receipt['final_total'] ??
                  receipt['total_amount'] ??
                  widget.billData['sub_total'] ??
                  0)
              .toString(),
        ) ??
        0;
    final calculatedShares = BillProvider.calculateUserShares(
      items: items,
      finalTotal: finalTotal,
      splitType: receipt['split_type']?.toString() ?? 'proportional',
      participantIds: participantIds,
    );

    final entriesById = <String, MemberSummaryEntry>{};
    for (final id in participantIds) {
      final profile = profilesById[id];
      final name =
          namesById[id] ??
          profile?['display_name']?.toString() ??
          (id.startsWith('guest_') ? 'Guest' : 'เพื่อน');
      entriesById[id] = MemberSummaryEntry(
        id: id,
        name: name,
        amount: calculatedShares[id] ?? 0,
        isGuest: id.startsWith('guest_'),
      );
    }

    for (final row in participantRows) {
      final id = row['profile_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final status = row['status']?.toString().toLowerCase();
      final existing = entriesById[id];
      entriesById[id] = MemberSummaryEntry(
        id: id,
        name: existing?.name ?? namesById[id] ?? 'เพื่อน',
        amount:
            double.tryParse(row['amount_owed']?.toString() ?? '') ??
            existing?.amount ??
            0,
        isPaid:
            status == 'paid' ||
            status == 'cleared' ||
            status == 'settled',
        isGuest: false,
      );
    }

    return entriesById.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.billData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final createdAt =
        widget.billData['created_at']?.toString().split('T')[0] ?? '';
    final imageUrl = widget.billData['image_url'];
    final receiptJson = _asMap(widget.billData['receipt_json']);
    final items = receiptJson['items'] as List<dynamic>? ?? [];
    final sharersJson = _asMap(widget.billData['sharers_json']);

    final subTotal =
        double.tryParse(receiptJson['sub_total']?.toString() ?? '0') ?? 0;
    final vatAmount =
        double.tryParse(receiptJson['vat_amount']?.toString() ?? '0') ?? 0;
    final serviceCharge =
        double.tryParse(receiptJson['service_charge']?.toString() ?? '0') ?? 0;
    final discount =
        double.tryParse(receiptJson['discount']?.toString() ?? '0') ?? 0;
    final totalAmount =
        double.tryParse(
          (receiptJson['final_total'] ??
                  receiptJson['total_amount'] ??
                  widget.billData['sub_total'] ??
                  '0')
              .toString(),
        ) ??
        0;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดบิลย้อนหลัง')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.toString().isNotEmpty)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(imageUrl, height: 300, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              shopName.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (createdAt.isNotEmpty)
              Text(
                'วันที่: $createdAt',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('ยอดรวม (Subtotal)', subTotal),
                  if (serviceCharge > 0)
                    _buildSummaryRow('Service Charge', serviceCharge),
                  if (vatAmount > 0) _buildSummaryRow('VAT', vatAmount),
                  if (discount > 0)
                    _buildSummaryRow('ส่วนลด', -discount, color: Colors.red),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ยอดสุทธิ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(totalAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'รายการที่สั่ง (รายละเอียด)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final rawItem = _asMap(items[index]);
                final itemName = rawItem['item_name']?.toString() ?? 'ไม่มีชื่อ';
                final qty =
                    int.tryParse(
                      (rawItem['qty'] ?? rawItem['quantity'] ?? 1).toString(),
                    ) ??
                    1;
                final unitPrice =
                    double.tryParse(
                      (rawItem['unit_price'] ?? rawItem['price'] ?? 0)
                          .toString(),
                    ) ??
                    0;
                final totalPrice =
                    double.tryParse(rawItem['total_price']?.toString() ?? '') ??
                    qty * unitPrice;
                final itemSharers =
                    sharersJson[index.toString()] as List<dynamic>? ?? [];
                final userQuantities = <String, int>{};
                final namesByUserId = <String, String>{};
                final sharedUsers = <String, String>{};

                for (final rawSharer in itemSharers) {
                  final sharer = _asMap(rawSharer);
                  final userId = sharer['user_id']?.toString() ?? '';
                  if (userId.isEmpty) continue;
                  final name = sharer['user_name']?.toString() ?? 'ไม่ระบุ';
                  namesByUserId[userId] = name;
                  final claimedQuantity =
                      int.tryParse(sharer['quantity']?.toString() ?? '') ?? 0;
                  if (claimedQuantity > 0) {
                    userQuantities[userId] =
                        (userQuantities[userId] ?? 0) + claimedQuantity;
                  }
                  if (sharer['is_shared'] == true) sharedUsers[userId] = name;
                }

                if (itemSharers.isEmpty) {
                  final claims =
                      rawItem['userQuantities'] ??
                      rawItem['claims'] ??
                      rawItem['user_quantities'];
                  if (claims is Map) {
                    claims.forEach((userId, amount) {
                      final id = userId.toString();
                      final claimedQuantity =
                          int.tryParse(amount.toString()) ?? 0;
                      if (claimedQuantity > 0) {
                        userQuantities[id] = claimedQuantity;
                        namesByUserId[id] = id.startsWith('guest_')
                            ? 'Guest'
                            : id;
                      }
                    });
                  }
                  final shared = rawItem['sharedUsers'] ??
                      rawItem['shared_claims'] ??
                      rawItem['shared_users'];
                  if (shared is List) {
                    for (final userId in shared) {
                      sharedUsers[userId.toString()] =
                          userId.toString().startsWith('guest_')
                          ? 'Guest'
                          : userId.toString();
                    }
                  }
                }

                final personalQuantity = userQuantities.values.fold<int>(
                  0,
                  (sum, amount) => sum + amount,
                );
                final sharedQuantity = (qty - personalQuantity).clamp(0, qty);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '$qty x ${AppFormatters.formatCurrency(unitPrice)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.formatCurrency(totalPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (userQuantities.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '👤 ส่วนตัว: ${userQuantities.entries.map((entry) => '${namesByUserId[entry.key] ?? entry.key}: ${entry.value} ชิ้น').join(', ')}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (sharedUsers.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '🤝 แชร์ร่วมกัน ($sharedQuantity ชิ้น): ${sharedUsers.values.join(', ')}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'สรุปยอดชำระและสถานะของเพื่อน',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            FutureBuilder<List<MemberSummaryEntry>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'โหลดสรุปยอดของสมาชิกไม่สำเร็จ: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('ไม่มีข้อมูลยอดชำระรายบุคคล'),
                  );
                }
                return MemberSummaryList(members: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(color: color ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}
