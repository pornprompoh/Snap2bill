import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/friend_item.dart';
import '../../widgets/custom_button.dart';

class SummaryScreen extends StatefulWidget {
  final String lobbyId;
  final Map<String, dynamic> receiptData;
  final Map<int, List<Map<String, dynamic>>> itemSharers;

  const SummaryScreen({
    super.key,
    required this.lobbyId,
    required this.receiptData,
    required this.itemSharers,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isSaving = false;

  // ฟังก์ชันคณิตศาสตร์: คำนวณว่าแต่ละคนต้องจ่ายกี่บาท
  Map<String, double> _calculateTotals() {
    final totals = <String, double>{};
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final price = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
      final sharers = widget.itemSharers[i] ?? [];

      if (sharers.isNotEmpty) {
        final splitPrice = price / sharers.length;
        for (var sharer in sharers) {
          final name = sharer['user_name'] as String;
          totals[name] = (totals[name] ?? 0) + splitPrice;
        }
      }
    }
    return totals;
  }

  // ฟังก์ชันบันทึกข้อมูลลงฐานข้อมูลและปิดจบ
  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true); // เปิดสถานะ Loading ที่ปุ่ม
    
    try {
      // 1. ดึง ID ของคนที่ล็อกอินอยู่ (Host)
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final rawTotalAmount = double.tryParse(widget.receiptData['total_amount']?.toString() ?? '0') ?? 0.0;
      
      if (userId != null) {
        // 2. บันทึกข้อมูลลงตาราง bills
        await Supabase.instance.client.from('bills').insert({
          'owner_id': userId,
          'shop_name': widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน',
          'sub_total': rawTotalAmount,
        });
      }

      // 3. ปิดห้อง Lobby เดิม (อัปเดตสถานะเป็น completed)
      await Supabase.instance.client
          .from('lobbies')
          .update({'status': 'completed'})
          .eq('id', widget.lobbyId);

      // 4. ล้างประวัติหน้าจอทั้งหมดแล้วกลับหน้า Home
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          AppRoutes.home, 
          (route) => false
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกบิล: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false); // ปิดสถานะ Loading
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    final rawTotalAmount = double.tryParse(widget.receiptData['total_amount']?.toString() ?? '0') ?? 0.0;

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
                  Text(
                    AppFormatters.formatCurrency(rawTotalAmount), 
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)
                  ),
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
            
            // ลิสต์แสดงรายชื่อคนและยอดที่ต้องจ่าย
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totals.keys.length,
              itemBuilder: (context, index) {
                final name = totals.keys.elementAt(index);
                final amount = totals[name]!;
                return FriendItem(
                  name: name,
                  amountText: AppFormatters.formatCurrency(amount),
                );
              },
            ),
            
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            const Text('สแกนจ่ายผ่าน PromptPay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // จำลองพื้นที่วาง QR Code
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
            
            // ปุ่มกดเสร็จสิ้น
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                text: 'เสร็จสิ้นการหารบิล (บันทึก & กลับหน้าแรก)',
                backgroundColor: Colors.green,
                isLoading: _isSaving, // 🚀 ส่งค่า Loading ไปให้ปุ่ม
                onPressed: _isSaving ? null : _saveAndFinish, // ป้องกันการกดเบิ้ล
              ),
            ),
          ],
        ),
      ),
    );
  }
}