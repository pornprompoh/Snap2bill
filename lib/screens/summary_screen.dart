import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
  final _supabase = Supabase.instance.client;
  
  String _hostPromptPay = '';
  String _hostName = 'เจ้าของบิล';
  bool _isLoadingHost = true;
  bool _isSaving = false;

  final Map<String, double> _userTotals = {};
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchHostPromptPayInfo();
  }

  Future<void> _fetchHostPromptPayInfo() async {
    try {
      final ownerId = widget.receiptData['owner_id'] ?? _supabase.auth.currentUser?.id;
      if (ownerId != null) {
        final response = await _supabase
            .from('profiles')
            .select()
            .eq('id', ownerId)
            .maybeSingle();

        if (response != null && mounted) {
          setState(() {
            _hostPromptPay = response['promptpay'] ?? response['phone'] ?? '';
            _hostName = response['name'] ?? response['email']?.split('@')[0] ?? 'เจ้าของบิล';
          });
        }
      }
    } catch (e) {
      debugPrint('ไม่สามารถดึงข้อมูล PromptPay ของ Host ได้: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingHost = false);
      }
    }
  }

  // 🚀 ใช้ตรรกะเดิมของคุณในการคำนวณยอด
  Map<String, double> _calculateTotals() {
    final totals = <String, double>{};
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];

    double totalClaimedValue = 0.0;
    final userItemTotals = <String, double>{};

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final unitPrice = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
      final sharers = widget.itemSharers[i] ?? [];

      for (var sharer in sharers) {
        final name = sharer['user_name'] as String;
        final userId = sharer['user_id'] as String;
        userItemTotals[name] = (userItemTotals[name] ?? 0) + unitPrice;
        totalClaimedValue += unitPrice;
        
        // 🚀 เก็บ userId ไว้ใช้ตอนบันทึกลงตาราง bill_participants
        _userTotals[userId] = (_userTotals[userId] ?? 0.0) + unitPrice;
      }
    }

    final vat = double.tryParse(widget.receiptData['vat_amount']?.toString() ?? '0') ?? 0.0;
    final sc = double.tryParse(widget.receiptData['service_charge']?.toString() ?? '0') ?? 0.0;
    final discount = double.tryParse(widget.receiptData['discount']?.toString() ?? '0') ?? 0.0;
    final extraCharges = vat + sc - discount;

    userItemTotals.forEach((name, itemTotal) {
      if (totalClaimedValue > 0) {
        final proportion = itemTotal / totalClaimedValue;
        final userExtra = extraCharges * proportion;
        totals[name] = itemTotal + userExtra;
      } else {
        totals[name] = itemTotal;
      }
    });

    // อัปเดต _userTotals ให้รวมค่า extraCharges ด้วย
    if (totalClaimedValue > 0) {
        _userTotals.forEach((userId, total) {
           final proportion = total / totalClaimedValue;
           _userTotals[userId] = total + (extraCharges * proportion);
        });
    }

    _grandTotal = totalClaimedValue + extraCharges;
    return totals;
  }

  // 🚀 ฟังก์ชันนี้รวมโค้ดเก่าของคุณที่อัปโหลดรูปและเซฟบิล เข้ากับการบันทึกผู้ร่วมหาร
  Future<void> _saveAndFinish() async {
    setState(() => _isSaving = true);
    
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'ไม่พบรหัสผู้ใช้งาน กรุณาล็อกอินใหม่';

      String? imageUrl;
      final localImagePath = widget.receiptData['local_image_path'];

      // 1. อัปโหลดรูป (เหมือนโค้ดเดิมของคุณ)
      if (localImagePath != null && localImagePath.isNotEmpty) {
        final file = File(localImagePath);
        if (file.existsSync()) {
          final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await _supabase.storage.from('receipts').upload(fileName, file);
          imageUrl = _supabase.storage.from('receipts').getPublicUrl(fileName);
        }
      }

      final sharersJson = widget.itemSharers.map((key, value) => MapEntry(key.toString(), value));
      final rawTotalAmount = double.tryParse(widget.receiptData['total_amount']?.toString() ?? '0') ?? _grandTotal;

      // 2. 🚀 บันทึกบิลใหม่ลงตาราง bills และรับค่า UUID ที่เพิ่งสร้างกลับมา
      final insertedBill = await _supabase.from('bills').insert({
        'owner_id': userId,
        'shop_name': widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน',
        'sub_total': rawTotalAmount,
        'image_url': imageUrl,
        'receipt_json': widget.receiptData,
        'sharers_json': sharersJson,
      }).select('id').single(); // ดึง id ออกมา

      final String newBillId = insertedBill['id'].toString();

      // 3. 🚀 บันทึกรายชื่อคนหาร ลงในตาราง bill_participants
      final List<Map<String, dynamic>> participantsData = [];
      _userTotals.forEach((uid, amount) {
        participantsData.add({
          'bill_id': newBillId,     
          'profile_id': uid,         
          'amount_owed': amount,         
        });
      });

      if (participantsData.isNotEmpty) {
        await _supabase.from('bill_participants').insert(participantsData);
      }

      // 4. (ถ้ามี) อัปเดตสถานะห้อง lobby เป็น completed (เหมือนโค้ดเดิมของคุณ)
      // if (widget.lobbyId.isNotEmpty && widget.lobbyId != 'unknown_room') {
      //   await _supabase.from('lobbies').update({'status': 'completed'}).eq('lobby_code', widget.lobbyId);
      // }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาด: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _generatePromptPayPayload(String target, double amount) {
    String cleanTarget = target.replaceAll(RegExp(r'[^0-9]'), '');
    
    String targetField = '';
    if (cleanTarget.length == 10) {
      String formattedPhone = '0066${cleanTarget.substring(1)}';
      targetField = '0129' + '0066' + formattedPhone; 
    } else {
      targetField = '02' + cleanTarget.length.toString().padLeft(2, '0') + cleanTarget;
    }

    String payloadFormat = '000201';
    String initiationMethod = '010211'; 
    
    String merchantAccountInfo = '0016A000000677010111' + targetField;
    String countryCode = '5802TH';
    String currencyCode = '5303764'; 
    
    String amountStr = amount.toStringAsFixed(2);
    String amountField = '54' + amountStr.length.toString().padLeft(2, '0') + amountStr;

    String unverifiedPayload = payloadFormat + initiationMethod + merchantAccountInfo + currencyCode + countryCode + amountField + '6304';
    
    String crc = _calculateCRC16(unverifiedPayload);
    
    return unverifiedPayload + crc;
  }

  String _calculateCRC16(String payload) {
    int crc = 0xFFFF;
    for (int i = 0; i < payload.length; i++) {
      crc ^= (payload.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  void _showPromptPayDialog(String userName, double amount) {
    if (_hostPromptPay.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เจ้าของบิลยังไม่ได้ตั้งค่าเบอร์ PromptPay ในหน้าโปรไฟล์')),
      );
      return;
    }

    final String qrPayload = _generatePromptPayPayload(_hostPromptPay, amount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            const Icon(Icons.qr_code_2, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            Text('สแกนจ่ายให้ $_hostName\n($_hostPromptPay)', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
              'ยอดชำระ: ${AppFormatters.formatCurrency(amount)}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = _calculateTotals();
    final rawTotalAmount = double.tryParse(widget.receiptData['total_amount']?.toString() ?? '0') ?? _grandTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สรุปยอดและเคลียร์บิล'),
        automaticallyImplyLeading: false,
      ),
      body: _isLoadingHost
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        if (_hostPromptPay.isEmpty) ...[
                           const SizedBox(height: 8),
                           const Text(
                             '⚠️ คุณยังไม่ได้ตั้งค่าเบอร์ PromptPay ในหน้าโปรไฟล์',
                             style: TextStyle(color: Colors.redAccent, fontSize: 12),
                           ),
                        ]
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
                      
                      return InkWell(
                        onTap: () => _showPromptPayDialog(name, amount),
                        child: FriendItem(
                          name: name,
                          amountText: AppFormatters.formatCurrency(amount),
                        ),
                      );
                    },
                  ),
                  const Divider(thickness: 2),
                  const SizedBox(height: 16),
                  
                  // ส่วนแสดง PromptPay ของ Host รวมไว้ด้านล่าง (ตามโค้ดเดิมของคุณ)
                  if (_hostPromptPay.isNotEmpty) ...[
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
                      child: Center(
                        child: QrImageView(
                          data: _generatePromptPayPayload(_hostPromptPay, _grandTotal),
                          version: QrVersions.auto,
                          size: 180.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('$_hostPromptPay\n$_hostName', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ],

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