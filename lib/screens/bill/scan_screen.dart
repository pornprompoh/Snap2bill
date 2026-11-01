import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../routes/app_routes.dart';
import '../../services/camera_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    Uint8List? imageBytes;
    if (source == ImageSource.camera) {
      imageBytes = await CameraService.captureReceiptPhoto(context);
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imageBytes = await pickedFile.readAsBytes();
      }
    }
    if (imageBytes != null) {
      setState(() {
        _imageBytes = imageBytes;
      });
    }
  }

  void _goToLoadingScreen() {
    if (_imageBytes == null) return;
    Navigator.pushNamed(context, AppRoutes.loading, arguments: _imageBytes!);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : AppColors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'ถ่ายรูปใบเสร็จ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.white : AppColors.black,
                ),
              ),
              const SizedBox(height: 24),

              // กรอบรูปภาพใบเสร็จขอบมนเส้นสีชมพูตามแบบอ้างอิง
              Container(
                height: 380,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.pink.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.5),
                  child: _imageBytes != null
                      ? Image.memory(
                          _imageBytes!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : const Center(
                          child: Text(
                            'กรุณาเลือกรูปภาพใบเสร็จ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // ปุ่มเลือกรูป ถ่ายรูป & คลังภาพ ทรงแคปซูลสีชมพูอ่อนขอบชมพูตามแบบ
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    label: 'ถ่ายรูป',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 16),
                  _buildActionButton(
                    label: 'คลังภาพ',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),

              if (_imageBytes != null) ...[
                const SizedBox(height: 28),
                CustomButton(
                  text: 'ให้ AI ช่วยอ่านบิล ✨',
                  onPressed: _goToLoadingScreen,
                ),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lightPink,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.pink,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}
