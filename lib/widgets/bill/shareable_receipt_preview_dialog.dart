import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../utils/bill_progress_helper.dart';
import '../../utils/formatters.dart';
import '../../utils/promptpay_helper.dart';
import '../../services/media/qr_image_saver.dart';
import 'shareable_receipt_card.dart';

class ShareableReceiptPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> bill;
  final BillProgressSummary summary;
  final String? hostPromptPay;
  final String? hostPromptPayType;
  final String? hostBankAccount;
  final String? hostBankName;
  final String? hostName;
  final bool isCurrentViewerOwner;
  final void Function(String promptPay, String promptPayType, String? hostName)?
  onPromptPayUpdated;

  const ShareableReceiptPreviewDialog({
    super.key,
    required this.bill,
    required this.summary,
    this.hostPromptPay,
    this.hostPromptPayType,
    this.hostBankAccount,
    this.hostBankName,
    this.hostName,
    this.isCurrentViewerOwner = true,
    this.onPromptPayUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> bill,
    BillProgressSummary? summary,
    String? hostPromptPay,
    String? hostPromptPayType,
    String? hostBankAccount,
    String? hostBankName,
    String? hostName,
    bool isCurrentViewerOwner = true,
    void Function(String promptPay, String promptPayType, String? hostName)?
    onPromptPayUpdated,
  }) {
    final effectiveSummary = summary ?? BillProgressHelper.calculate(bill);
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ShareableReceiptPreviewDialog(
          bill: bill,
          summary: effectiveSummary,
          hostPromptPay: hostPromptPay,
          hostPromptPayType: hostPromptPayType,
          hostBankAccount: hostBankAccount,
          hostBankName: hostBankName,
          hostName: hostName,
          isCurrentViewerOwner: isCurrentViewerOwner,
          onPromptPayUpdated: onPromptPayUpdated,
        ),
      ),
    );
  }

  @override
  State<ShareableReceiptPreviewDialog> createState() =>
      _ShareableReceiptPreviewDialogState();
}

class _ShareableReceiptPreviewDialogState
    extends State<ShareableReceiptPreviewDialog> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isProcessing = false;
  String? _statusMessage;
  Color? _statusColor;

  late String? _currentHostPromptPay;
  late String? _currentHostPromptPayType;
  late String? _currentHostBankAccount;
  late String? _currentHostBankName;
  late String? _currentHostName;

  @override
  void initState() {
    super.initState();
    _currentHostPromptPay = widget.hostPromptPay;
    _currentHostPromptPayType = widget.hostPromptPayType ?? 'phone';
    _currentHostBankAccount = widget.hostBankAccount;
    _currentHostBankName = widget.hostBankName;
    _currentHostName = widget.hostName;

    _checkAndLoadHostPromptPay();
  }

  Future<void> _checkAndLoadHostPromptPay() async {
    if (_currentHostPromptPay != null &&
        _currentHostPromptPay!.trim().isNotEmpty) {
      return;
    }
    try {
      final receipt = _asMap(widget.bill['receipt_json']);
      if (receipt.isNotEmpty) {
        final rPromptPay = receipt['promptpay_number']?.toString();
        if (rPromptPay != null && rPromptPay.isNotEmpty) {
          if (mounted) {
            setState(() {
              _currentHostPromptPay = rPromptPay;
              _currentHostPromptPayType =
                  receipt['promptpay_type']?.toString() ?? 'phone';
            });
          }
          return;
        }
      }

      final ownerId =
          widget.bill['owner_id']?.toString() ??
          Supabase.instance.client.auth.currentUser?.id;
      if (ownerId != null && ownerId.isNotEmpty) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', ownerId)
            .maybeSingle();
        if (profile != null && mounted) {
          final paymentInfo = _asMap(profile['payment_info']);
          final pNumber =
              profile['promptpay_number']?.toString() ??
              paymentInfo['number']?.toString();
          if (pNumber != null && pNumber.isNotEmpty) {
            setState(() {
              _currentHostPromptPay = pNumber;
              _currentHostPromptPayType =
                  profile['promptpay_type']?.toString() ??
                  paymentInfo['type']?.toString() ??
                  'phone';
              final dName = profile['display_name']?.toString().trim();
              if (dName != null && dName.isNotEmpty) {
                _currentHostName = dName;
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading host promptpay in dialog: $e');
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        debugPrint('Invalid payment_info JSON in receipt dialog.');
      }
    }
    return {};
  }

  Future<void> _showPromptPayConfigDialog() async {
    String selectedType = _currentHostPromptPayType ?? 'phone';
    final numberController = TextEditingController(
      text: _currentHostPromptPay ?? '',
    );
    final nameController = TextEditingController(text: _currentHostName ?? '');
    String? errorText;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'ตั้งค่า PromptPay',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'กำหนดหมายเลขพร้อมเพย์ของเจ้าของบิล เพื่อสร้าง QR Code ให้เพื่อนสแกนชำระเงิน',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ประเภทพร้อมเพย์',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'phone',
                        label: Text('เบอร์โทรศัพท์'),
                        icon: Icon(Icons.phone_iphone_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: 'id_card',
                        label: Text('บัตรประชาชน'),
                        icon: Icon(Icons.badge_rounded, size: 16),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (val) {
                      setDialogState(() {
                        selectedType = val.first;
                        errorText = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    selectedType == 'phone'
                        ? 'เบอร์โทรศัพท์ (10 หลัก)'
                        : 'เลขบัตรประชาชน (13 หลัก)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: numberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: selectedType == 'phone'
                          ? 'เช่น 0812345678'
                          : 'เช่น 1234567890123',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setDialogState(() => errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ชื่อบัญชี / ชื่อเจ้าของบิล',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'เช่น สมชาย ใจดี',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () async {
                  final target = numberController.text.trim();
                  if (!PromptPayHelper.isValidTarget(target)) {
                    setDialogState(() {
                      errorText = selectedType == 'phone'
                          ? 'กรุณากรอกเบอร์มือถือ 10 หลัก (ขึ้นต้นด้วย 0)'
                          : 'กรุณากรอกเลขบัตรประชาชน 13 หลัก';
                    });
                    return;
                  }

                  final newName = nameController.text.trim().isNotEmpty
                      ? nameController.text.trim()
                      : null;

                  // Save to Supabase
                  try {
                    final currentUserId =
                        Supabase.instance.client.auth.currentUser?.id;
                    if (currentUserId != null) {
                      final updateData = <String, dynamic>{
                        'promptpay_number': target,
                        'promptpay_type': selectedType,
                      };
                      if (newName != null) {
                        updateData['display_name'] = newName;
                      }
                      await Supabase.instance.client
                          .from('profiles')
                          .update(updateData)
                          .eq('id', currentUserId);
                    }

                    final billId = widget.bill['id']?.toString();
                    if (billId != null && billId.isNotEmpty) {
                      final receipt = widget.bill['receipt_json'] is Map
                          ? Map<String, dynamic>.from(
                              widget.bill['receipt_json'] as Map,
                            )
                          : <String, dynamic>{};
                      receipt['promptpay_number'] = target;
                      receipt['promptpay_type'] = selectedType;
                      if (newName != null) receipt['host_name'] = newName;
                      await Supabase.instance.client
                          .from('bills')
                          .update({'receipt_json': receipt})
                          .eq('id', billId);
                      widget.bill['receipt_json'] = receipt;
                    }
                  } catch (e) {
                    debugPrint('Error updating promptpay info: $e');
                  }

                  if (mounted) {
                    setState(() {
                      _currentHostPromptPay = target;
                      _currentHostPromptPayType = selectedType;
                      if (newName != null) _currentHostName = newName;
                      _statusMessage =
                          'ตั้งค่า PromptPay และสร้าง QR Code สำเร็จแล้ว ✅';
                      _statusColor = AppColors.tealGreen;
                    });
                  }

                  widget.onPromptPayUpdated?.call(
                    target,
                    selectedType,
                    newName,
                  );
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<Uint8List?> _captureReceiptPng() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing receipt image: $e');
      return null;
    }
  }

  String _buildSummaryMessage() {
    final s = widget.summary;
    final buffer = StringBuffer();
    buffer.writeln('🧾 สรุปค่าใช้จ่าย: ${s.shopName}');
    buffer.writeln(
      '💰 ยอดรวม: ${AppFormatters.formatCurrency(s.totalAmount)} (ตกคนละ ฿${s.formattedAverage})',
    );
    buffer.writeln(
      '📊 สถานะ: ${s.progressPercentageText} (${s.paidCountText})',
    );
    buffer.writeln('');

    if (s.unpaidMembers.isNotEmpty) {
      buffer.writeln('⏳ รอชำระ:');
      for (final m in s.unpaidMembers) {
        buffer.writeln(
          '• ${m.name}: ${AppFormatters.formatCurrency(m.amount)}',
        );
      }
      buffer.writeln('');
    }

    final pPay = _currentHostPromptPay ?? widget.hostPromptPay;
    final hName = _currentHostName ?? widget.hostName ?? "เจ้าของบิล";
    if (pPay != null && pPay.isNotEmpty) {
      buffer.writeln('💳 พร้อมเพย์: $pPay ($hName)');
    }
    final bAccount = _currentHostBankAccount ?? widget.hostBankAccount;
    final bName = _currentHostBankName ?? widget.hostBankName ?? "";
    if (bAccount != null && bAccount.isNotEmpty) {
      buffer.writeln('🏦 บัญชี: $bName $bAccount ($hName)');
    }
    buffer.writeln('📲 จัดการบิลผ่าน Snap2Bill');
    return buffer.toString();
  }

  Future<void> _saveImage() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final imageBytes = await _captureReceiptPng();
      if (imageBytes == null) {
        throw StateError('ไม่สามารถแปลงบิลเป็นรูปภาพได้');
      }

      final fileName =
          'snap2bill_receipt_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        await saveQrImage(imageBytes, fileName);
      } else {
        // Mobile share/save
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(imageBytes, mimeType: 'image/png', name: fileName),
            ],
            title: 'บันทึกรูปภาพบิลสรุป',
          ),
        );
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'ดาวน์โหลด/บันทึกรูปภาพบิลสรุปเรียบร้อยแล้ว ✅';
          _statusColor = AppColors.tealGreen;
        });
      }
    } catch (e) {
      debugPrint('บันทึกรูปบิลสรุปไม่สำเร็จ: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'บันทึกรูปบิลสรุปไม่สำเร็จ กรุณาลองอีกครั้ง';
          _statusColor = Colors.red;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareToLine() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final message = _buildSummaryMessage();
      final imageBytes = await _captureReceiptPng();
      final fileName =
          'snap2bill_receipt_${DateTime.now().millisecondsSinceEpoch}.png';

      if (imageBytes != null) {
        // Share image + caption so LINE or any selected app receives both image & text
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(imageBytes, mimeType: 'image/png', name: fileName),
            ],
            text: message,
            subject: 'สรุปบิล ${widget.summary.shopName}',
          ),
        );
      } else {
        // Fallback to text LINE scheme
        final lineUrl = Uri.parse(
          'https://line.me/R/msg/text/?${Uri.encodeComponent(message)}',
        );
        await launchUrl(lineUrl, mode: LaunchMode.externalApplication);
      }

      if (mounted) {
        setState(() {
          _statusMessage =
              'เปิดหน้าแชร์ LINE เรียบร้อย ให้เลือกเพื่อนหรือกลุ่มเพื่อส่งภาพบิล';
          _statusColor = AppColors.tealGreen;
        });
      }
    } catch (e) {
      debugPrint('แชร์บิลสรุปผ่าน LINE ไม่สำเร็จ: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'แชร์บิลไม่สำเร็จ กรุณาลองอีกครั้ง';
          _statusColor = Colors.red;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareNative() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    try {
      final imageBytes = await _captureReceiptPng();
      final message = _buildSummaryMessage();
      final fileName =
          'snap2bill_receipt_${DateTime.now().millisecondsSinceEpoch}.png';

      if (imageBytes != null) {
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(imageBytes, mimeType: 'image/png', name: fileName),
            ],
            text: message,
            subject: 'บิลสรุปค่าใช้จ่าย ${widget.summary.shopName}',
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            title: 'บิลสรุปค่าใช้จ่าย ${widget.summary.shopName}',
            text: message,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _statusMessage = 'เปิดระบบแชร์ของอุปกรณ์เรียบร้อย';
          _statusColor = AppColors.tealGreen;
        });
      }
    } catch (e) {
      debugPrint('แชร์บิลสรุปไม่สำเร็จ: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'แชร์บิลไม่สำเร็จ กรุณาลองอีกครั้ง';
          _statusColor = Colors.red;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _copyText() async {
    final message = _buildSummaryMessage();
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      setState(() {
        _statusMessage = 'คัดลอกข้อความสรุปบิลเรียบร้อยแล้ว 📋';
        _statusColor = AppColors.tealGreen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 480),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Modal Top Bar
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 12,
              top: 14,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.pink.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.pink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ตัวอย่างบิลสรุปสำเร็จรูป',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.black,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Receipt Card Preview
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _receiptKey,
                    child: ShareableReceiptCard(
                      bill: widget.bill,
                      summary: widget.summary,
                      hostPromptPay: _currentHostPromptPay,
                      hostPromptPayType: _currentHostPromptPayType,
                      hostBankAccount: _currentHostBankAccount,
                      hostBankName: _currentHostBankName,
                      hostName: _currentHostName,
                      isCurrentViewerOwner: widget.isCurrentViewerOwner,
                      onConfigurePromptPay: _showPromptPayConfigDialog,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Feedback Status Banner
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_statusColor ?? AppColors.tealGreen).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_statusColor ?? AppColors.tealGreen).withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor ?? AppColors.tealGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Save Image Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _saveImage,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text(
                          'บันทึกรูปภาพ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Share to LINE Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06C755),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _shareToLine,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'แชร์เข้า LINE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    // Native Share Sheet
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _shareNative,
                        icon: const Icon(Icons.share_rounded, size: 17),
                        label: const Text(
                          'แชร์ช่องทางอื่น',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Copy Summary Text
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isProcessing ? null : _copyText,
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: const Text(
                          'คัดลอกข้อความ',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
