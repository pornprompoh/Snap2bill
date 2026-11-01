import 'dart:ui' as ui;
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../utils/bill_progress_helper.dart';
import '../../utils/formatters.dart';
import 'shareable_receipt_card.dart';

// Conditional import for web download
import 'package:web/web.dart' as web;

class ShareableReceiptPreviewDialog extends StatefulWidget {
  final Map<String, dynamic> bill;
  final BillProgressSummary summary;
  final String? hostPromptPay;
  final String? hostPromptPayType;
  final String? hostBankAccount;
  final String? hostBankName;
  final String? hostName;

  const ShareableReceiptPreviewDialog({
    super.key,
    required this.bill,
    required this.summary,
    this.hostPromptPay,
    this.hostPromptPayType,
    this.hostBankAccount,
    this.hostBankName,
    this.hostName,
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

  Future<Uint8List?> _captureReceiptPng() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
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
    buffer.writeln('💰 ยอดรวม: ${AppFormatters.formatCurrency(s.totalAmount)} (ตกคนละ ฿${s.formattedAverage})');
    buffer.writeln('📊 สถานะ: ${s.progressPercentageText} (${s.paidCountText})');
    buffer.writeln('');

    if (s.unpaidMembers.isNotEmpty) {
      buffer.writeln('⏳ รอชำระ:');
      for (final m in s.unpaidMembers) {
        buffer.writeln('• ${m.name}: ${AppFormatters.formatCurrency(m.amount)}');
      }
      buffer.writeln('');
    }

    if (widget.hostPromptPay != null && widget.hostPromptPay!.isNotEmpty) {
      buffer.writeln('💳 พร้อมเพย์: ${widget.hostPromptPay} (${widget.hostName ?? "เจ้าของบิล"})');
    }
    if (widget.hostBankAccount != null && widget.hostBankAccount!.isNotEmpty) {
      buffer.writeln('🏦 บัญชี: ${widget.hostBankName ?? ""} ${widget.hostBankAccount} (${widget.hostName ?? "เจ้าของบิล"})');
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
        // Direct browser file download on web
        final blob = web.Blob(
          [imageBytes.toJS].toJS,
          web.BlobPropertyBag(type: 'image/png'),
        );
        final url = web.URL.createObjectURL(blob);
        final anchor = web.HTMLAnchorElement()
          ..href = url
          ..download = fileName;
        anchor.click();
        web.URL.revokeObjectURL(url);
      } else {
        // Mobile share/save
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                imageBytes,
                mimeType: 'image/png',
                name: fileName,
              ),
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
      if (mounted) {
        setState(() {
          _statusMessage = 'เกิดข้อผิดพลาดในการบันทึกรูป: $e';
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
              XFile.fromData(
                imageBytes,
                mimeType: 'image/png',
                name: fileName,
              ),
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
          _statusMessage = 'เปิดหน้าแชร์ LINE เรียบร้อย ให้เลือกเพื่อนหรือกลุ่มเพื่อส่งภาพบิล';
          _statusColor = AppColors.tealGreen;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'เกิดข้อผิดพลาดในการแชร์: $e';
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
              XFile.fromData(
                imageBytes,
                mimeType: 'image/png',
                name: fileName,
              ),
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
      if (mounted) {
        setState(() {
          _statusMessage = 'เกิดข้อผิดพลาดในการแชร์: $e';
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
            padding: const EdgeInsets.only(left: 20, right: 12, top: 14, bottom: 8),
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
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.pink, size: 20),
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
                      hostPromptPay: widget.hostPromptPay,
                      hostPromptPayType: widget.hostPromptPayType,
                      hostBankAccount: widget.hostBankAccount,
                      hostBankName: widget.hostBankName,
                      hostName: widget.hostName,
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
                  color: (_statusColor ?? AppColors.tealGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_statusColor ?? AppColors.tealGreen).withValues(alpha: 0.3),
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0))),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isProcessing ? null : _saveImage,
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('บันทึกรูปภาพ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isProcessing ? null : _shareToLine,
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                        label: const Text('แชร์เข้า LINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isProcessing ? null : _shareNative,
                        icon: const Icon(Icons.share_rounded, size: 17),
                        label: const Text('แชร์ช่องทางอื่น', style: TextStyle(fontSize: 12.5)),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Copy Summary Text
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isProcessing ? null : _copyText,
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: const Text('คัดลอกข้อความ', style: TextStyle(fontSize: 12.5)),
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
