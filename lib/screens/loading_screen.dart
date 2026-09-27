import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/ocr_service.dart';
import '../../routes/app_routes.dart';

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
    _processReceipt();
  }

  Future<void> _processReceipt() async {
    try {
      final result = await _ocrService.processReceipt(widget.image);
      if (!mounted) return;

      if (result != null) {
        // 🚀 ทริค: แอบฝากที่อยู่ไฟล์รูปภาพ (Path) ไปกับชุดข้อมูล JSON เลย
        result['local_image_path'] = widget.image.path; 

        Navigator.pushReplacementNamed(
          context,
          AppRoutes.review,
          arguments: result,
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
    Navigator.pop(context);
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