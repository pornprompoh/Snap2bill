import 'package:flutter/material.dart';

class SummaryScreen extends StatelessWidget {
  final String lobbyId;
  final Map<String, dynamic> receiptData;
  final Map<int, List<Map<String, dynamic>>> itemSharers;

  const SummaryScreen({
    super.key,
    required this.lobbyId,
    required this.receiptData,
    required this.itemSharers,
  });

  // ฟังก์ชันคณิตศาสตร์: คำนวณว่าแต่ละคนต้องจ่ายกี่บาท
  Map<String, double> _calculateTotals() {
    final totals = <String, double>{};
    final items = receiptData['items'] as List<dynamic>? ?? [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final price = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
      final sharers = itemSharers[i] ?? [];

      if (sharers.isNotEmpty) {
        // เอาค่าอาหารจานนั้น หารด้วยจำนวนคนที่จิ้ม
        final splitPrice = price / sharers.length;
        for (var sharer in sharers) {
          final name = sharer['user_name'] as String;
          totals[name] = (totals[name] ?? 0) + splitPrice;
        }
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    final totalAmount = receiptData['total_amount']?.toString() ?? '0';

    return Scaffold(
      appBar: AppBar(title: const Text('สรุปยอดและเคลียร์บิล')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนหัวแสดงยอดรวมทั้งหมด
            Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).colorScheme.primaryContainer,
              width: double.infinity,
              child: Column(
                children: [
                  const Text('ยอดรวมทั้งหมด', style: TextStyle(fontSize: 16)),
                  Text('$totalAmount บาท', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('สรุปยอดรายบุคคล', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            // ลิสต์แสดงชื่อเพื่อนและยอดเงินที่ต้องจ่าย
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totals.keys.length,
              itemBuilder: (context, index) {
                final name = totals.keys.elementAt(index);
                final amount = totals[name]!;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  title: Text(name),
                  trailing: Text(
                    '${amount.toStringAsFixed(2)} ฿', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                );
              },
            ),
            
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            const Text('สแกนจ่ายผ่าน PromptPay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // จำลองพื้นที่วาง QR Code (สำหรับให้เพื่อน UX/UI ไปใส่ภาพคิวอาร์โค้ดจริงทีหลัง)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.qr_code_scanner, size: 100, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            const Text('089-123-XXXX\nนายทดสอบ ระบบหารบิล', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            // ปุ่มจบการทำงาน
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    // กลับไปหน้าแรกสุด (Home) เพื่อเริ่มบิลใหม่
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text('เสร็จสิ้นการหารบิล (กลับหน้าแรก)', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}