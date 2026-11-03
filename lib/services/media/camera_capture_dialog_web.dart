import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart' as web;

import '../../theme/app_colors.dart';

Future<Uint8List?> captureReceiptPhotoWithControls(BuildContext context) async {
  if (!context.mounted) return null;

  try {
    final stream = await web.window.navigator.mediaDevices
        .getUserMedia(
          web.MediaStreamConstraints(
            video: web.MediaTrackConstraints(
              facingMode: web.ConstrainDOMStringParameters(
                ideal: 'environment'.toJS,
              ),
            ),
            audio: false.toJS,
          ),
        )
        .toDart;

    if (!context.mounted) {
      _stopStream(stream);
      return null;
    }

    return await showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _WebCameraDialog(stream: stream),
    );
  } catch (error) {
    debugPrint('Web camera initialization failed: $error');
    if (!context.mounted) return null;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
      return await picked?.readAsBytes();
    } catch (fallbackError) {
      debugPrint('Web camera fallback failed: $fallbackError');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'เปิดกล้องไม่สำเร็จ กรุณาอนุญาตการใช้กล้องแล้วลองอีกครั้ง',
            ),
          ),
        );
      }
      return null;
    }
  }
}

void _stopStream(web.MediaStream stream) {
  for (final track in stream.getTracks().toDart) {
    track.stop();
  }
}

class _WebCameraDialog extends StatefulWidget {
  const _WebCameraDialog({required this.stream});

  final web.MediaStream stream;

  @override
  State<_WebCameraDialog> createState() => _WebCameraDialogState();
}

class _WebCameraDialogState extends State<_WebCameraDialog> {
  late web.MediaStream _stream = widget.stream;
  web.HTMLVideoElement? _videoElement;
  List<web.MediaDeviceInfo> _cameras = const [];
  int _cameraIndex = 0;
  bool _isCapturing = false;
  bool _isSwitchingCamera = false;
  bool _isFlashEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      final devices =
          (await web.window.navigator.mediaDevices.enumerateDevices().toDart)
              .toDart
              .where((device) => device.kind == 'videoinput')
              .toList();
      final tracks = _stream.getVideoTracks().toDart;
      final activeDeviceId = tracks.isEmpty
          ? ''
          : tracks.first.getSettings().deviceId;

      if (!mounted) return;
      setState(() {
        _cameras = devices;
        final activeIndex = devices.indexWhere(
          (device) => device.deviceId == activeDeviceId,
        );
        if (activeIndex >= 0) _cameraIndex = activeIndex;
      });
    } catch (error) {
      debugPrint('Unable to enumerate web cameras: $error');
    }
  }

  Future<void> _switchCamera() async {
    if (_isSwitchingCamera || _cameras.length < 2) return;
    setState(() => _isSwitchingCamera = true);
    final nextIndex = (_cameraIndex + 1) % _cameras.length;

    try {
      final nextStream = await web.window.navigator.mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              video: web.MediaTrackConstraints(
                deviceId: web.ConstrainDOMStringParameters(
                  exact: _cameras[nextIndex].deviceId.toJS,
                ),
              ),
              audio: false.toJS,
            ),
          )
          .toDart;
      if (!mounted) {
        _stopStream(nextStream);
        return;
      }

      final previousStream = _stream;
      _stream = nextStream;
      _cameraIndex = nextIndex;
      _isFlashEnabled = false;
      _stopStream(previousStream);
      final video = _videoElement;
      if (video != null) {
        video.srcObject = nextStream;
        _playVideo(video);
      }
      setState(() {});
    } catch (error) {
      debugPrint('Unable to switch web camera: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สลับกล้องไม่สำเร็จ กรุณาลองอีกครั้ง')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSwitchingCamera = false);
    }
  }

  Future<void> _toggleFlash() async {
    final tracks = _stream.getVideoTracks().toDart;
    if (tracks.isEmpty) return;
    final enableFlash = !_isFlashEnabled;

    try {
      await tracks.first
          .applyConstraints(web.MediaTrackConstraints(torch: enableFlash.toJS))
          .toDart;
      if (mounted) setState(() => _isFlashEnabled = enableFlash);
    } catch (error) {
      debugPrint('Web camera torch is unavailable: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กล้องนี้ไม่รองรับแฟลชหรือไฟฉาย')),
        );
      }
    }
  }

  void _onElementCreated(Object element) {
    final video = element as web.HTMLVideoElement;
    _videoElement = video
      ..autoplay = true
      ..playsInline = true
      ..srcObject = _stream
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';
    _playVideo(video);
  }

  void _playVideo(web.HTMLVideoElement video) {
    unawaited(_startVideo(video));
  }

  Future<void> _startVideo(web.HTMLVideoElement video) async {
    try {
      await video.play().toDart;
    } catch (error) {
      debugPrint('Unable to start web camera preview: $error');
    }
  }

  void _takePicture() {
    final video = _videoElement;
    if (video == null || _isCapturing) return;

    final width = video.videoWidth;
    final height = video.videoHeight;
    if (width == 0 || height == 0) return;

    setState(() => _isCapturing = true);
    try {
      final canvas =
          web.document.createElement('canvas') as web.HTMLCanvasElement
            ..width = width
            ..height = height;
      final canvasContext =
          canvas.getContext('2d') as web.CanvasRenderingContext2D;
      canvasContext.drawImage(video, 0, 0);

      final dataUrl = canvas.toDataURL('image/jpeg', 0.9.toJS);
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex < 0) {
        throw StateError('Camera returned an invalid image.');
      }
      Navigator.of(
        context,
      ).pop(base64Decode(dataUrl.substring(commaIndex + 1)));
    } catch (error) {
      debugPrint('Web camera capture failed: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ถ่ายรูปไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _stopStream(_stream);
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
                      HtmlElementView.fromTagName(
                        tagName: 'video',
                        onElementCreated: _onElementCreated,
                      ),
                      Center(
                        child: Container(
                          width: 260,
                          height: math.min(320, previewHeight - 24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.tealGreen.withValues(alpha: 0.8),
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
                      onPressed: _toggleFlash,
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
            ],
          ),
        ),
      ),
    );
  }
}
