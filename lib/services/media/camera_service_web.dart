import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;
import '../../theme/app_colors.dart';

Future<Uint8List?> captureReceiptPhoto(BuildContext context) async {
  try {
    final mediaDevices = web.window.navigator.mediaDevices;
    final stream = await mediaDevices.getUserMedia(
      web.MediaStreamConstraints(
        video: true.toJS,
        audio: false.toJS,
      ),
    ).toDart;

    if (!context.mounted) {
      _stopStream(stream);
      return null;
    }

    final capturedBytes = await showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _WebCameraDialog(stream: stream),
    );

    _stopStream(stream);
    return capturedBytes;
  } catch (error) {
    debugPrint('Web camera initialization error: $error');
    // Fallback to ImagePicker camera/file picker
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked != null) {
      return await picked.readAsBytes();
    }
    return null;
  }
}

void _stopStream(web.MediaStream stream) {
  try {
    final tracks = stream.getTracks().toDart;
    for (final track in tracks) {
      track.stop();
    }
  } catch (_) {}
}

class _WebCameraDialog extends StatefulWidget {
  final web.MediaStream stream;

  const _WebCameraDialog({required this.stream});

  @override
  State<_WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<_WebCameraDialog> {
  web.HTMLVideoElement? _videoElement;
  bool _isCapturing = false;

  void _onElementCreated(Object element) {
    try {
      final video = element as web.HTMLVideoElement;
      _videoElement = video
        ..autoplay = true
        ..playsInline = true
        ..srcObject = widget.stream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
    } catch (_) {}
  }

  void _takePicture() {
    final video = _videoElement;
    if (video == null || _isCapturing) return;

    final width = video.videoWidth;
    final height = video.videoHeight;
    if (width == 0 || height == 0) return;

    setState(() => _isCapturing = true);

    try {
      final canvas = web.document.createElement('canvas') as web.HTMLCanvasElement;
      canvas.width = width;
      canvas.height = height;

      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      ctx.drawImage(video, 0, 0);

      final dataUrl = canvas.toDataURL('image/jpeg', 0.9.toJS);
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex != -1) {
        final base64String = dataUrl.substring(commaIndex + 1);
        final bytes = base64Decode(base64String);
        Navigator.of(context).pop(bytes);
        return;
      }
    } catch (e) {
      debugPrint('Error capturing frame: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ถ่ายรูปใบเสร็จ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),

            // Live Camera Viewfinder
            Container(
              height: 380,
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    HtmlElementView.fromTagName(
                      tagName: 'video',
                      onElementCreated: _onElementCreated,
                    ),

                    // Receipt Guide Overlay (กรอบช่วยเล็งใบเสร็จ)
                    Center(
                      child: Container(
                        width: 260,
                        height: 320,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.tealGreen.withValues(alpha: 0.8),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Shutter Button Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: _isCapturing ? null : _takePicture,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.transparent,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.pink,
                        ),
                        child: _isCapturing
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
