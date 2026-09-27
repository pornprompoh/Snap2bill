import 'package:flutter/material.dart';
import 'lobby_screen.dart'; // TODO: เดี๋ยวเราจะสร้างหน้า Lobby ในสเตปถัดไป

class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic> receiptData;
  const ReviewScreen({super.key, required this.receiptData});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final shopName = widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final totalAmount = widget.receiptData['total_amount']?.toString() ?? '0';
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('ตรวจสอบบิล (Review)')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ร้าน: $shopName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('ยอดรวมสุทธิ: $totalAmount บาท', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('รายการอาหาร', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemName = item['item_name'] ?? 'ไม่มีชื่อ';
                final itemTotal = item['total_price']?.toString() ?? '0';
                
                return Column(
                  children: [
                    ListTile(
                      title: Text(itemName),
                      trailing: Text('$itemTotal ฿', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ยืนยันบิลเรียบร้อย! (เตรียมเชื่อมไปหน้า Lobby)')),
                  );
                  // TODO: เปลี่ยนไปหน้า Lobby Screen ในสเตปถัดไป
                   Navigator.pushReplacement(
                     context,
                     MaterialPageRoute(builder: (_) => LobbyScreen(receiptData: widget.receiptData)),
                   );
                },
                child: const Text('ยืนยันรายการอาหาร', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}