import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

Future<Uint8List?> captureReceiptPhotoWithControls(BuildContext context) async {
  if (!context.mounted) return null;

  return showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CameraCaptureDialog(),
  );
}

class _CameraCaptureDialog extends StatefulWidget {
  const _CameraCaptureDialog();

  @override
  State<_CameraCaptureDialog> createState() => _CameraCaptureDialogState();
}

class _CameraCaptureDialogState extends State<_CameraCaptureDialog> {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isSwitchingCamera = false;
  bool _isFlashEnabled = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera({int? cameraIndex}) async {
    setState(() {
      _isInitializing = true;
      _cameraError = null;
    });

    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        if (_cameras.isEmpty) {
          throw CameraException(
            'no-camera',
            'No camera is available on this device.',
          );
        }
        _cameraIndex = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        if (_cameraIndex == -1) _cameraIndex = 0;
      } else if (cameraIndex != null) {
        _cameraIndex = cameraIndex;
      }

      final previousController = _controller;
      _controller = null;
      await previousController?.dispose();
      if (!mounted) return;

      final controller = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isFlashEnabled = false;
        _isInitializing = false;
      });
    } catch (error) {
      debugPrint('Camera initialization failed: $error');
      if (!mounted) return;
      setState(() {
        _cameraError = 'เปิดกล้องไม่สำเร็จ กรุณาตรวจสอบสิทธิ์การใช้กล้อง';
        _isInitializing = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || _cameras.length < 2) return;
    setState(() => _isSwitchingCamera = true);
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await _initializeCamera(cameraIndex: nextIndex);
    if (mounted) setState(() => _isSwitchingCamera = false);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final enableFlash = !_isFlashEnabled;
    try {
      await controller.setFlashMode(
        enableFlash ? FlashMode.torch : FlashMode.off,
      );
      if (mounted) setState(() => _isFlashEnabled = enableFlash);
    } catch (error) {
      debugPrint('Camera torch is unavailable: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กล้องนี้ไม่รองรับแฟลชหรือไฟฉาย')),
      );
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (_isCapturing || controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      if (mounted) {
        Navigator.of(context).pop(await photo.readAsBytes());
      }
    } catch (error) {
      debugPrint('Camera capture failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ถ่ายรูปไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewHeight = math.min(
      380.0,
      math.max(220.0, MediaQuery.sizeOf(context).height * 0.48),
    );

    return Dialog(
      backgroundColor: const Color(0xFF18181B),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ถ่ายรูปใบเสร็จ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ปิดกล้อง',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
              Container(
                height: previewHeight,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.5),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCameraPreview(),
                      if (_controller != null && !_isInitializing)
                        Center(
                          child: Container(
                            width: 260,
                            height: math.min(320, previewHeight - 24),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.tealGreen.withValues(
                                  alpha: 0.8,
                                ),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'วางใบเสร็จให้อยู่ในกรอบ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      tooltip: _isFlashEnabled ? 'ปิดไฟฉาย' : 'เปิดไฟฉาย',
                      onPressed: _controller == null ? null : _toggleFlash,
                      icon: Icon(
                        _isFlashEnabled
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        color: _isFlashEnabled
                            ? AppColors.tealGreen
                            : Colors.white,
                      ),
                    ),
                    InkWell(
                      key: const ValueKey('takeReceiptPhoto'),
                      onTap: _isCapturing ? null : _takePicture,
                      borderRadius: BorderRadius.circular(40),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.pink,
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'สลับกล้อง',
                      onPressed: _cameras.length < 2 || _isSwitchingCamera
                          ? null
                          : _switchCamera,
                      icon: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (_cameraError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _cameraError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _controller;
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.tealGreen),
      );
    }
    if (controller != null && controller.value.isInitialized) {
      return CameraPreview(controller);
    }
    return const Center(
      child: Icon(
        Icons.no_photography_outlined,
        color: Colors.white54,
        size: 40,
      ),
    );
  }
}
