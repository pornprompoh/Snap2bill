import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/bill_progress_helper.dart';
import '../../utils/promptpay_helper.dart';

class ShareableReceiptCard extends StatelessWidget {
  final Map<String, dynamic> bill;
  final BillProgressSummary summary;
  final String? hostPromptPay;
  final String? hostPromptPayType;
  final String? hostBankAccount;
  final String? hostBankName;
  final String? hostName;
  final double? specificMemberAmount;
  final String? specificMemberName;
  final VoidCallback? onConfigurePromptPay;
  final bool isCurrentViewerOwner;

  const ShareableReceiptCard({
    super.key,
    required this.bill,
    required this.summary,
    this.hostPromptPay,
    this.hostPromptPayType,
    this.hostBankAccount,
    this.hostBankName,
    this.hostName,
    this.specificMemberAmount,
    this.specificMemberName,
    this.onConfigurePromptPay,
    this.isCurrentViewerOwner = true,
  });

  String get _billRefCode {
    final id = bill['id']?.toString() ?? '';
    if (id.length >= 8) {
      return id.substring(0, 8).toUpperCase();
    }
    return id.toUpperCase();
  }

  double? get _effectiveAmount {
    if (specificMemberAmount != null && specificMemberAmount! > 0) {
      return specificMemberAmount;
    }
    if (summary.totalAmount > 0) {
      return summary.totalAmount;
    }
    return null;
  }

  String? get _promptPayPayload {
    if (hostPromptPay == null || hostPromptPay!.trim().isEmpty) return null;
    if (!PromptPayHelper.isValidTarget(hostPromptPay!)) return null;
    return PromptPayHelper.generatePayload(
      hostPromptPay!,
      amount: _effectiveAmount,
      targetType: hostPromptPayType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final createdAt = bill['created_at']?.toString() ?? '';
    final rawImageUrl = bill['image_url']?.toString().trim();
    final parsedImageUrl = rawImageUrl == null
        ? null
        : Uri.tryParse(rawImageUrl);
    final imageUrl =
        parsedImageUrl != null &&
            (parsedImageUrl.scheme == 'http' ||
                parsedImageUrl.scheme == 'https') &&
            parsedImageUrl.host.isNotEmpty
        ? rawImageUrl
        : null;
    final hasValidPromptPay =
        hostPromptPay != null && PromptPayHelper.isValidTarget(hostPromptPay!);
    final qrPayload = _promptPayPayload;

    final double effectiveTargetAmount =
        specificMemberAmount ??
        (s.unpaidMembers.isNotEmpty
            ? s.unpaidMembers.first.amount
            : s.averagePerPerson);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Decorative Header Bar
          Container(
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.pink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Scissors & Receipt Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'SNAP2BILL RECEIPT',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Shop Name
                Text(
                  s.shopName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Bill metadata
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_billRefCode.isNotEmpty) ...[
                      Text(
                        '#$_billRefCode',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const Text(
                        ' • ',
                        style: TextStyle(color: Color(0xFFCBD5E1)),
                      ),
                    ],
                    Text(
                      createdAt.split('T')[0],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),

                // Receipt Thumbnail if exists
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      imageUrl,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),

                // 2. Summary Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'ยอดรวมทั้งสิ้น (Total)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF78350F),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppFormatters.formatCurrency(s.totalAmount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'สมาชิก ${s.totalMembers} คน (ผู้ชำระจริง ${s.totalPayingCount} คน)',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF92400E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.isEqualSplit && s.equalPerPerson != null
                                ? 'ตกคนละ ${AppFormatters.formatCurrency(s.equalPerPerson!)}'
                                : 'หารตามรายการจริง',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress bar in receipt
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: s.percentage / 100.0,
                          backgroundColor: const Color(0xFFFEF3C7),
                          color: s.unpaidCount == 0
                              ? AppColors.tealGreen
                              : AppColors.primaryOrange,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${s.progressPercentageText} (${s.paidCountText})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF78350F),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s.waitingText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: s.unpaidCount == 0
                                  ? AppColors.tealGreen
                                  : const Color(0xFFC2410C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 14),

                // 3. Member Breakdown List
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'รายละเอียดการชำระเงิน (${s.allMembers.length} คน)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                ...s.allMembers.map((member) {
                  final isOwner = member.isOwner;
                  final isPaid = member.isPaid;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        // Avatar Icon
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isOwner
                                ? const Color(0xFFFEF3C7)
                                : (isPaid
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFFEDD5)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOwner
                                ? Icons.star_rounded
                                : (isPaid
                                      ? Icons.check_rounded
                                      : Icons.access_time_rounded),
                            size: 14,
                            color: isOwner
                                ? const Color(0xFFD97706)
                                : (isPaid
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFEA580C)),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Member Name
                        Expanded(
                          child: Text(
                            member.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isOwner
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Member Amount
                        Text(
                          AppFormatters.formatCurrency(member.amount),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isOwner
                                ? const Color(0xFFB45309)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOwner
                                ? const Color(0xFFFEF3C7)
                                : (isPaid
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFFEDD5)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isOwner
                                  ? const Color(0xFFFCD34D)
                                  : (isPaid
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFFDBA74)),
                            ),
                          ),
                          child: Text(
                            isOwner
                                ? 'เจ้าของ 👑'
                                : (isPaid ? 'จ่ายแล้ว ✅' : 'รอจ่าย ⏳'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isOwner
                                  ? const Color(0xFFB45309)
                                  : (isPaid
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFC2410C)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 16),

                // 4. PromptPay QR Code Payment Section
                if (hasValidPromptPay &&
                    qrPayload != null &&
                    qrPayload.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF003D6B).withValues(alpha: 0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF003D6B,
                          ).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Thai QR Header Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF003D6B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Thai QR Payment (พร้อมเพย์)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Crisp QR Code
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 160,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF003D6B),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF003D6B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ชื่อเจ้าของบัญชีหรือชื่อผู้รับเงิน
                        Text(
                          'ชื่อบัญชี: ${hostName?.isNotEmpty == true ? hostName! : "เจ้าของบิล"}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),

                        // หมายเลข PromptPay ที่สามารถแสดงแบบปกปิดบางส่วนได้
                        Text(
                          'พร้อมเพย์: ${PromptPayHelper.maskPromptPay(hostPromptPay!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF003D6B),
                            fontFamily: 'monospace',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),

                        // Amount to scan
                        if (effectiveTargetAmount > 0) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              'ยอดชำระ: ${AppFormatters.formatCurrency(effectiveTargetAmount)}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],

                        // ข้อความแนะนำ
                        const Text(
                          'สแกนเพื่อชำระเงินเข้าบัญชีเจ้าของบิล',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (hostBankAccount != null &&
                            hostBankAccount!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'ธนาคาร: ${hostBankName ?? ""} $hostBankAccount',
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        const Text(
                          '*QR Code สำหรับโอนเงินเท่านั้น การยืนยันชำระต้องให้เจ้าของกดยืนยันในแอป',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // PromptPay not set warning
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF64748B),
                          size: 26,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'เจ้าของบิลยังไม่ได้ตั้งค่าพร้อมเพย์',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'สามารถตั้งค่าพร้อมเพย์เพื่อสร้าง QR Code สำหรับรับเงินอัตโนมัติ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (hostBankAccount != null &&
                            hostBankAccount!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'โอนเข้าบัญชี: ${hostBankName ?? ""} $hostBankAccount (${hostName ?? ""})',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF003D6B),
                            ),
                          ),
                        ],
                        if (onConfigurePromptPay != null &&
                            isCurrentViewerOwner) ...[
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: onConfigurePromptPay,
                            icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                            label: const Text(
                              'ตั้งค่า PromptPay',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                _buildDashedLine(),
                const SizedBox(height: 12),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: AppColors.pink,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Snap2Bill • บิลสรุปค่าใช้จ่าย',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'สร้างเมื่อ ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} น.',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return const SizedBox(
      width: double.infinity,
      height: 1,
      child: CustomPaint(painter: DashedLinePainter()),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  const DashedLinePainter({this.color = const Color(0xFFCBD5E1)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
