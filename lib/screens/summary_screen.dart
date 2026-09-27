import 'dart:io';
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

  // 🚀 ฟังก์ชันคำนวณยอดรวม + หาร VAT และ Service Charge ตามสัดส่วน
  Map<String, double> _calculateTotals() {
    final totals = <String, double>{};
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];

    double totalClaimedValue = 0.0;
    final userItemTotals = <String, double>{};

    // 1. รวมยอดค่าอาหาร/สินค้าเพียวๆ ของแต่ละคน
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      // ใช้ unit_price เพราะ 1 itemSharer = 1 ชิ้น
      final unitPrice = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
      final sharers = widget.itemSharers[i] ?? [];

      for (var sharer in sharers) {
        final name = sharer['user_name'] as String;
        userItemTotals[name] = (userItemTotals[name] ?? 0) + unitPrice;
        totalClaimedValue += unitPrice;
      }
    }

    // 2. ดึงค่าส่วนเกิน (VAT, Service Charge, ส่วนลด)
    final vat = double.tryParse(widget.receiptData['vat_amount']?.toString() ?? '0') ?? 0.0;
    final sc = double.tryParse(widget.receiptData['service_charge']?.toString() ?? '0') ?? 0.0;
    final discount = double.tryParse(widget.receiptData['discount']?.toString() ?? '0') ?? 0.0;
    final extraCharges = vat + sc - discount;

    // 3. กระจายส่วนเกินให้แต่ละคนตามสัดส่วนที่กิน
    userItemTotals.forEach((name, itemTotal) {
      if (totalClaimedValue > 0) {
        final proportion = itemTotal / totalClaimedValue; // หารสัดส่วน
        final userExtra = extraCharges * proportion;
        totals[name] = itemTotal + userExtra;
      } else {
        totals[name] = itemTotal;
      }
    });

    return totals;
  }

  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true);
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw 'ไม่พบรหัสผู้ใช้งาน กรุณาล็อกอินใหม่';

      String? imageUrl;
      final localImagePath = widget.receiptData['local_image_path'];

      if (localImagePath != null) {
        final file = File(localImagePath);
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('receipts').upload(fileName, file);
        imageUrl = supabase.storage.from('receipts').getPublicUrl(fileName);
      }

      final sharersJson = widget.itemSharers.map((key, value) => MapEntry(key.toString(), value));
      final rawTotalAmount = double.tryParse(widget.receiptData['total_amount']?.toString() ?? '0') ?? 0.0;

      await supabase.from('bills').insert({
        'owner_id': userId,
        'shop_name': widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน',
        'sub_total': rawTotalAmount,
        'image_url': imageUrl,
        'receipt_json': widget.receiptData,
        'sharers_json': sharersJson,
      });

      await supabase.from('lobbies').update({'status': 'completed'}).eq('id', widget.lobbyId);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                  const SizedBox(height: 8),
                  Text(
                    '*คำนวณ VAT และ Service Charge ตามสัดส่วนแล้ว',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                text: 'เสร็จสิ้นการหารบิล (บันทึก & กลับหน้าแรก)',
                backgroundColor: Colors.green,
                isLoading: _isSaving, 
                onPressed: _isSaving ? null : _saveAndFinish, 
              ),
            ),
          ],
        ),
      ),
    );
  }
}