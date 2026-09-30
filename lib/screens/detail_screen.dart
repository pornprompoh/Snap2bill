import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> billData; 
  
  const DetailScreen({super.key, required this.billData});

  @override
  Widget build(BuildContext context) {
    final shopName = billData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final createdAt = billData['created_at']?.toString().split('T')[0] ?? '';
    final imageUrl = billData['image_url'];
    
    final receiptJson = billData['receipt_json'] as Map<String, dynamic>? ?? {};
    final items = receiptJson['items'] as List<dynamic>? ?? [];
    
    final subTotal = double.tryParse(receiptJson['sub_total']?.toString() ?? '0') ?? 0.0;
    final vatAmount = double.tryParse(receiptJson['vat_amount']?.toString() ?? '0') ?? 0.0;
    final serviceCharge = double.tryParse(receiptJson['service_charge']?.toString() ?? '0') ?? 0.0;
    final discount = double.tryParse(receiptJson['discount']?.toString() ?? '0') ?? 0.0;
    final totalAmount = double.tryParse(receiptJson['total_amount']?.toString() ?? billData['sub_total']?.toString() ?? '0') ?? 0.0;

    final sharersJson = billData['sharers_json'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดบิลย้อนหลัง')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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

            Text(shopName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (createdAt.isNotEmpty)
              Text('วันที่: $createdAt', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),

            // 🚀 กล่องสรุปยอดแบบใบเสร็จจริง
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('ยอดรวม (Subtotal)', subTotal),
                  if (serviceCharge > 0) _buildSummaryRow('Service Charge', serviceCharge),
                  if (vatAmount > 0) _buildSummaryRow('VAT', vatAmount),
                  if (discount > 0) _buildSummaryRow('ส่วนลด', -discount, color: Colors.red),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ยอดสุทธิ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        AppFormatters.formatCurrency(totalAmount),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('รายการที่สั่ง (รายละเอียด)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemName = item['item_name'] ?? 'ไม่มีชื่อ';
                final qty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
                final unitPrice = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
                final totalPrice = double.tryParse(item['total_price']?.toString() ?? '0') ?? (qty * unitPrice);
                
                // จัดกลุ่มคนที่แชร์ เพื่อไม่ให้ชื่อโชว์ซ้ำๆ
                final sharersList = sharersJson[index.toString()] as List<dynamic>? ?? [];
                final Map<String, int> groupedSharers = {};
                for (var s in sharersList) {
                  final name = s['user_name'] ?? 'ไม่ระบุ';
                  groupedSharers[name] = (groupedSharers[name] ?? 0) + 1;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
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
                                  Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    '$qty x ${AppFormatters.formatCurrency(unitPrice)}',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Text(AppFormatters.formatCurrency(totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (groupedSharers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: groupedSharers.entries.map((entry) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.blue.shade100),
                                ),
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                                ),
                              );
                            }).toList(),
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(AppFormatters.formatCurrency(amount), style: TextStyle(color: color ?? Colors.grey.shade800)),
        ],
      ),
    );
  }
}