import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/media/ocr_service.dart';
import '../../routes/app_routes.dart';

import '../../widgets/common/bouncing_mascot_loader.dart';
import '../../theme/app_colors.dart';

class LoadingScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const LoadingScreen({super.key, required this.imageBytes});

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
      final result = await _ocrService.processReceipt(widget.imageBytes);
      if (!mounted) return;

      if (result != null) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.review,
          arguments: {
            'receiptData': result,
            'receiptImageBytes': widget.imageBytes,
          },
        );
      } else {
        _showError('ไม่สามารถอ่านข้อมูลใบเสร็จได้');
      }
    } catch (e) {
      debugPrint('อ่านข้อมูลใบเสร็จไม่สำเร็จ: $e');
      _showError(
        'อ่านข้อมูลใบเสร็จไม่สำเร็จ กรุณาใช้ภาพที่ชัดเจนแล้วลองอีกครั้ง',
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('กำลังประมวลผล'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BouncingMascotLoader(
              message: 'รอก่อนนะ บันนี่กำลังประมวลผล..',
              size: MediaQuery.sizeOf(context).shortestSide * 0.42,
            ),
          ),
        ),
      ),
    );
  }
}
