import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ocr_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _image;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;
    setState(() => _isProcessing = true);

    try {
      final result = await _ocrService.processReceipt(_image!);
      if (!mounted) return;
      
      // TODO: (ใน Step 6) จะนำข้อมูล result ส่งต่อไปหน้าเช็กความถูกต้องและบันทึกบิล
      // สำหรับสเตปนี้ ขอโชว์ผลลัพธ์ใส่ Dialog ให้ดูก่อนว่า AI ดึงข้อมูลได้จริง
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('ผลลัพธ์จาก AI 🎉'),
          content: SingleChildScrollView(
            child: Text(result.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ตกลง'),
            )
          ],
        )
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ถ่ายรูปใบเสร็จ')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_image!, height: 350, fit: BoxFit.cover),
                )
              else
                Container(
                  height: 350,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('กรุณาเลือกรูปภาพใบเสร็จ')),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ถ่ายรูป'),
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: const Text('คลังภาพ'),
                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              if (_image != null)
                _isProcessing
                    ? const Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('AI กำลังถอดรหัสใบเสร็จ...'),
                        ],
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _processImage,
                          child: const Text('ให้ AI ช่วยอ่านบิล', style: TextStyle(fontSize: 16)),
                        ),
                      ),
            ],
          ),
        ),
      ),
    );
  }
}