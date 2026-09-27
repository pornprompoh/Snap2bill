import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/ocr_service.dart';
import 'review_screen.dart'; // TODO: เดี๋ยวเราจะสร้างไฟล์นี้ในสเตปต่อไป

class LoadingScreen extends StatefulWidget {
  final File image;
  const LoadingScreen({super.key, required this.image});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    _processReceipt(); // เริ่มอ่านบิลทันทีที่เปิดหน้านี้
  }

  Future<void> _processReceipt() async {
    try {
      final result = await _ocrService.processReceipt(widget.image);
      if (!mounted) return;

      if (result != null) {
        // AI อ่านสำเร็จ (ชั่วคราว: แจ้งเตือนก่อนเดี๋ยวค่อยเชื่อมไปหน้า Review)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI อ่านบิลเสร็จแล้ว! 🎉')),
        );
        Navigator.pop(context); 
        
        // โค้ดจริงที่จะใช้เด้งไปหน้า Review (คอมเมนต์ไว้ก่อน)
         Navigator.pushReplacement(
           context,
           MaterialPageRoute(builder: (_) => ReviewScreen(receiptData: result)),
         );
      } else {
        _showError('ไม่สามารถอ่านข้อมูลใบเสร็จได้');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context); // กลับไปหน้าสแกน
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'กำลังให้ AI แกะข้อมูลใบเสร็จ...\nรอสักครู่นะครับ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}