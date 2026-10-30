import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/qr_image_saver.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

class PromptPayCard extends StatefulWidget {
  final String hostName;
  final String promptPayNumber;
  final String qrPayload;
  final String selectedUserName;
  final double amount;
  final bool isPaid;
  final VoidCallback? onAttachSlip;
  final VoidCallback? onRegenerateQr;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;

  const PromptPayCard({
    super.key,
    required this.hostName,
    required this.promptPayNumber,
    required this.qrPayload,
    required this.selectedUserName,
    required this.amount,
    this.isPaid = false,
    this.onAttachSlip,
    this.onRegenerateQr,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
  });

  @override
  State<PromptPayCard> createState() => _PromptPayCardState();
}

class _PromptPayCardState extends State<PromptPayCard> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;
  int _selectedPaymentMethod = 0; // 0 = PromptPay QR, 1 = Bank Account Transfer

  // ⏱️ ตัวจับเวลา 15 นาที สำหรับ Dynamic Single-Use QR (แบบ Shopee)
  static const int _initialDurationSeconds = 15 * 60; // 15 นาที
  late int _secondsRemaining;
  Timer? _countdownTimer;
  late String _currentSessionId;

  @override
  void initState() {
    super.initState();
    if (widget.promptPayNumber.trim().isEmpty &&
        widget.bankAccountNumber != null &&
        widget.bankAccountNumber!.trim().isNotEmpty) {
      _selectedPaymentMethod = 1;
    }
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _secondsRemaining = _initialDurationSeconds;
    _currentSessionId =
        'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() {});
      }
    });
  }

  void _regenerateQr() {
    setState(() {
      _startCountdown();
    });
    widget.onRegenerateQr?.call();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} นาที';
  }

  Future<void> _saveQrCode() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = _qrKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('ไม่พบการ์ดคิวอาร์โค้ดสำหรับบันทึก');
      }

      final image = await renderObject.toImage(pixelRatio: 3);
      late final Uint8List pngBytes;
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw StateError('ไม่สามารถแปลงการ์ดคิวอาร์โค้ดเป็นรูปภาพได้');
        }
        pngBytes = byteData.buffer.asUint8List();
      } finally {
        image.dispose();
      }

      await saveQrImage(pngBytes, 'promptpay_qr.png');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกรูปคิวอาร์โค้ดสำเร็จ')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกรูปคิวอาร์โค้ดไม่สำเร็จ: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildRowInfo(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPromptPay = widget.promptPayNumber.trim().isNotEmpty;
    final hasBank =
        widget.bankAccountNumber != null &&
        widget.bankAccountNumber!.trim().isNotEmpty;
    final isBankSelected = _selectedPaymentMethod == 1 && hasBank;

    // 🎉 1. ถ้าจ่ายเงินแล้วจริงๆ ให้ขึ้นแบบใน Shopee ว่าชำระเสร็จแล้วจบเลย
    if (widget.isPaid) {
      final payeeInfo = isBankSelected
          ? '${widget.hostName} (${widget.bankName ?? 'ธนาคาร'} ${widget.bankAccountNumber})'
          : '${widget.hostName} (${widget.promptPayNumber})';
      final channelInfo = isBankSelected
          ? 'โอนผ่านบัญชีธนาคาร (${widget.bankName ?? ''})'
          : 'พร้อมเพย์ QR (ใช้ครั้งเดียว)';

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.shade300, width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00AA5B),
                size: 56,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ชำระเงินสำเร็จเรียบร้อยแล้ว! 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF008A4B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ยอดชำระของ ${widget.selectedUserName} ได้รับการบันทึกแล้ว',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ยอดชำระสุทธิ',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Text(
                        '${AppFormatters.formatCurrency(widget.amount)} ฿',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00AA5B),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildRowInfo('ผู้รับเงิน', payeeInfo),
                  const SizedBox(height: 6),
                  _buildRowInfo('ช่องทาง', channelInfo),
                  const SizedBox(height: 6),
                  _buildRowInfo('รหัสอ้างอิง', _currentSessionId),
                  const SizedBox(height: 6),
                  _buildRowInfo('สถานะ', 'ชำระเงินแล้ว ✅'),
                ],
              ),
            ),
            if (widget.onAttachSlip != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('แนบ / ตรวจสอบสลิปหลักฐาน'),
                onPressed: widget.onAttachSlip,
              ),
            ],
          ],
        ),
      );
    }

    final isExpired = _secondsRemaining <= 0;

    return Column(
      children: [
        // 🔄 แถบสลับช่องทางการโอน (พร้อมเพย์ QR vs โอนผ่านเลขบัญชี)
        if (hasPromptPay && hasBank)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedPaymentMethod = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 0
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 18,
                            color: _selectedPaymentMethod == 0
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'พร้อมเพย์ QR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _selectedPaymentMethod == 0
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedPaymentMethod = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 1
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_rounded,
                            size: 18,
                            color: _selectedPaymentMethod == 1
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'โอนด้วยเลขบัญชี',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _selectedPaymentMethod == 1
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // แสดงหน้าจอตามวิธีที่เลือก
        if (_selectedPaymentMethod == 1 && hasBank)
          _buildBankTransferCard(context)
        else ...[
          // แถบจับเวลาคิวอาร์โค้ด (Shopee Style)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isExpired ? Colors.red.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpired ? Colors.red.shade200 : Colors.amber.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 18,
                  color: isExpired
                      ? Colors.red.shade700
                      : Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired
                      ? 'คิวอาร์โค้ดหมดอายุแล้ว (ใช้ครั้งเดียวทิ้ง)'
                      : 'คิวอาร์โค้ดหมดอายุใน: ${_formatTimer(_secondsRemaining)} (ใช้ครั้งเดียว)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isExpired
                        ? Colors.red.shade700
                        : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),

          RepaintBoundary(
            key: _qrKey,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PROMPTPAY (Single-Use)',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ชำระให้ ${widget.hostName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 214,
                      height: 214,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: isExpired
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'QR Code หมดอายุแล้ว',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'โปรดกดสร้างใหม่เพื่อชำระ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                  ),
                                  onPressed: _regenerateQr,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text(
                                    'สร้างใหม่',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            )
                          : QrImageView(
                              data: widget.qrPayload,
                              version: QrVersions.auto,
                              size: 190,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: AppColors.primaryDark,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: AppColors.primaryDark,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.promptPayNumber,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'ยอดชำระของ ${widget.selectedUserName}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(widget.amount),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!isExpired)
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _saveQrCode,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(_isSaving ? 'กำลังบันทึก...' : 'บันทึกคิวอาร์โค้ด'),
            )
          else
            TextButton.icon(
              onPressed: _regenerateQr,
              icon: const Icon(Icons.refresh),
              label: const Text('สร้าง QR Code สำหรับทำรายการใหม่'),
            ),
        ],
      ],
    );
  }

  Widget _buildBankTransferCard(BuildContext context) {
    final bankName = widget.bankName ?? 'ธนาคารพาณิชย์';
    final accountNumber = widget.bankAccountNumber ?? '-';
    final accountName =
        (widget.bankAccountName != null &&
            widget.bankAccountName!.trim().isNotEmpty)
        ? widget.bankAccountName!
        : widget.hostName;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'โอนผ่านเลขที่บัญชีธนาคาร',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ธนาคารผู้รับเงิน',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            bankName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'เลขที่บัญชีธนาคาร',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        accountNumber,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: accountNumber));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('คัดลอกเลขบัญชีแล้ว 📋'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text(
                        'คัดลอก',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'ชื่อบัญชี',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  accountName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยอดโอนของ ${widget.selectedUserName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${AppFormatters.formatCurrency(widget.amount)} ฿',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: widget.amount.toStringAsFixed(2)),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('คัดลอกยอดเงินแล้ว 📋'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'คัดลอกยอด',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'เมื่อโอนเงินเข้าบัญชีเรียบร้อยแล้ว อย่าลืมกดปุ่มแนบสลิปด้านล่าง เพื่อยืนยันยอด',
                    style: TextStyle(fontSize: 11, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onAttachSlip != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('แนบสลิปการโอนเงิน'),
              onPressed: widget.onAttachSlip,
            ),
          ],
        ],
      ),
    );
  }
}
