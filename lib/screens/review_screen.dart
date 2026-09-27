import 'package:flutter/material.dart';
import '../../routes/app_routes.dart'; // 🚀 นำเข้าระบบนำทาง
import '../../widgets/custom_button.dart'; // 🚀 นำเข้าปุ่มสำเร็จรูป
import '../../utils/formatters.dart'; // 🚀 นำเข้าตัวจัดรูปแบบตัวเลข

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
    // ดึงค่ามาแปลงเป็น double เพื่อเตรียมให้ Formatter ทำงาน
    final rawTotal = double.tryParse(widget.receiptData['total_amount']?.toString() ?? '0') ?? 0.0;
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
                // 🚀 ใช้ AppFormatters แปลงตัวเลขยอดรวม (เช่น 1300 -> 1,300.00 ฿)
                Text('ยอดรวมสุทธิ: ${AppFormatters.formatCurrency(rawTotal)}', style: const TextStyle(fontSize: 16)),
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
                final itemTotal = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
                
                return Column(
                  children: [
                    ListTile(
                      title: Text(itemName),
                      // 🚀 ใช้ AppFormatters แปลงราคาอาหารแต่ละรายการ
                      trailing: Text(
                        AppFormatters.formatCurrency(itemTotal), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            // 🚀 เรียกใช้ CustomButton ที่มีดีไซน์กลางของแอป
            child: CustomButton(
              text: 'ยืนยันรายการอาหาร',
              onPressed: () {
                // 🚀 ใช้ AppRoutes ส่งข้อมูลกระโดดไปหน้า Lobby
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.lobby,
                  arguments: widget.receiptData,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}