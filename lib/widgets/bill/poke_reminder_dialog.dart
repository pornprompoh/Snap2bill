import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_colors.dart';
import '../../utils/bill_progress_helper.dart';
import '../../utils/formatters.dart';
import '../../services/notifications/in_app_notification_service.dart';

class PokeReminderDialog extends StatefulWidget {
  final Map<String, dynamic> bill;
  final BillProgressSummary summary;
  final String? hostPromptPay;
  final String? hostBankAccount;
  final String? hostBankName;
  final String? hostName;

  const PokeReminderDialog({
    super.key,
    required this.bill,
    required this.summary,
    this.hostPromptPay,
    this.hostBankAccount,
    this.hostBankName,
    this.hostName,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> bill,
    BillProgressSummary? summary,
    String? hostPromptPay,
    String? hostBankAccount,
    String? hostBankName,
    String? hostName,
  }) {
    final effectiveSummary = summary ?? BillProgressHelper.calculate(bill);
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PokeReminderDialog(
        bill: bill,
        summary: effectiveSummary,
        hostPromptPay: hostPromptPay,
        hostBankAccount: hostBankAccount,
        hostBankName: hostBankName,
        hostName: hostName,
      ),
    );
  }

  @override
  State<PokeReminderDialog> createState() => _PokeReminderDialogState();
}

class _PokeReminderDialogState extends State<PokeReminderDialog> {
  bool _isProcessing = false;
  String? _statusFeedback;
  Color? _feedbackColor;

  String _buildReminderText() {
    final s = widget.summary;
    final buffer = StringBuffer();
    buffer.writeln('📢 สะกิดเตือนเพื่อนตี้ "${s.shopName}" จ้า! 🍲');
    buffer.writeln(
      '💰 ยอดรวมบิล: ฿${AppFormatters.formatCurrency(s.totalAmount)}',
    );
    buffer.writeln(
      '👥 สมาชิกทั้งหมด: ${s.totalMembers} คน (ตกคนละ ฿${s.formattedAverage})',
    );
    buffer.writeln('📊 สถานะ: ${s.paidCountText} | ${s.waitingText}');
    buffer.writeln('');

    buffer.writeln('📌 สมาชิกที่ยังรอชำระเงิน:');
    for (final m in s.unpaidMembers) {
      buffer.writeln(
        '• ${m.name}: ฿${AppFormatters.formatCurrency(m.amount)} (⏳ รอจ่าย)',
      );
    }
    buffer.writeln('');

    final hasPromptPay =
        widget.hostPromptPay != null && widget.hostPromptPay!.isNotEmpty;
    final hasBank =
        widget.hostBankAccount != null && widget.hostBankAccount!.isNotEmpty;

    if (hasPromptPay || hasBank) {
      buffer.writeln('💳 ช่องทางโอนเงิน:');
      if (hasPromptPay) {
        buffer.writeln(
          '• พร้อมเพย์: ${widget.hostPromptPay} (${widget.hostName ?? "เจ้าของบิล"})',
        );
      }
      if (hasBank) {
        buffer.writeln(
          '• บัญชี: ${widget.hostBankName ?? ""} ${widget.hostBankAccount} (${widget.hostName ?? "เจ้าของบิล"})',
        );
      }
      buffer.writeln('');
    }

    buffer.writeln(
      '✨ ใครโอนแล้วรบกวนแจ้งหรือส่งสลิปด้วยน้า ขอบคุณมากครับ/ค่ะ 🙏',
    );
    buffer.writeln('📲 จัดการบิลผ่าน Snap2Bill');
    return buffer.toString();
  }

  String _buildFullSummaryText() {
    final s = widget.summary;
    final buffer = StringBuffer();
    buffer.writeln('📋 สรุปรายละเอียดบิล: ${s.shopName}');
    buffer.writeln(
      '💰 ยอดรวมตามบิล: ฿${AppFormatters.formatCurrency(s.totalAmount)} (ตกคนละ ฿${s.formattedAverage})',
    );
    buffer.writeln(
      '👥 สมาชิกทั้งหมด: ${s.totalMembers} คน (ผู้ชำระจริง ${s.totalPayingCount} คน)',
    );
    buffer.writeln(
      '📊 สถานะการเก็บเงิน: ${s.percentage}% (${s.paidCountText})',
    );
    buffer.writeln('');

    buffer.writeln('📌 รายการยอดและสถานะแต่ละคน:');
    for (final m in s.allMembers) {
      if (m.isOwner) {
        buffer.writeln(
          '• ${m.name}: ฿${AppFormatters.formatCurrency(m.amount)} 👑 [เจ้าของบิล]',
        );
      } else if (m.isPaid) {
        buffer.writeln(
          '• ${m.name}: ฿${AppFormatters.formatCurrency(m.amount)} ✅ [จ่ายแล้ว]',
        );
      } else {
        buffer.writeln(
          '• ${m.name}: ฿${AppFormatters.formatCurrency(m.amount)} ⏳ [รอจ่าย]',
        );
      }
    }
    buffer.writeln('');

    final hasPromptPay =
        widget.hostPromptPay != null && widget.hostPromptPay!.isNotEmpty;
    final hasBank =
        widget.hostBankAccount != null && widget.hostBankAccount!.isNotEmpty;
    if (hasPromptPay || hasBank) {
      buffer.writeln('💳 โอนเงินได้ที่:');
      if (hasPromptPay) {
        buffer.writeln(
          '• พร้อมเพย์: ${widget.hostPromptPay} (${widget.hostName ?? "เจ้าของบิล"})',
        );
      }
      if (hasBank) {
        buffer.writeln(
          '• บัญชีธนาคาร: ${widget.hostBankName ?? ""} ${widget.hostBankAccount}',
        );
      }
      buffer.writeln('');
    }
    buffer.writeln('แชร์จาก Snap2Bill 🧾✨');
    return buffer.toString();
  }

  Future<void> _shareToLine() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusFeedback = null;
    });

    final text = _buildReminderText();
    final lineUrl = Uri.parse(
      'https://line.me/R/msg/text/?${Uri.encodeComponent(text)}',
    );

    try {
      final launched = await launchUrl(
        lineUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(lineUrl, mode: LaunchMode.platformDefault);
      }
      if (mounted) {
        setState(() {
          _statusFeedback =
              'เปิดหน้าแชร์ LINE เรียบร้อย ให้เลือกเพื่อนหรือกลุ่มเพื่อส่งข้อความ';
          _feedbackColor = AppColors.tealGreen;
        });
      }
    } catch (e) {
      // Fallback to general share sheet if LINE scheme fails
      await SharePlus.instance.share(
        ShareParams(
          title: 'สะกิดเตือนบิล ${widget.summary.shopName}',
          text: text,
        ),
      );
      if (mounted) {
        setState(() {
          _statusFeedback = 'เปิดช่องทางแชร์ข้อความเรียบร้อย';
          _feedbackColor = AppColors.tealGreen;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareFullSummary() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusFeedback = null;
    });

    try {
      final text = _buildFullSummaryText();
      await SharePlus.instance.share(
        ShareParams(
          title: 'สรุปการหารบิล ${widget.summary.shopName}',
          text: text,
        ),
      );
      if (mounted) {
        setState(() {
          _statusFeedback = 'เปิดระบบแชร์สรุปบิลเรียบร้อย';
          _feedbackColor = AppColors.tealGreen;
        });
      }
    } catch (e) {
      debugPrint('แชร์สรุปบิลไม่สำเร็จ: $e');
      if (mounted) {
        setState(() {
          _statusFeedback = 'แชร์สรุปบิลไม่สำเร็จ กรุณาลองอีกครั้ง';
          _feedbackColor = Colors.red;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendInAppNotification() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _statusFeedback = null;
    });

    final s = widget.summary;
    final billId = widget.bill['id']?.toString() ?? '';

    try {
      final sentCount = await InAppNotificationService.instance
          .sendBillReminders(
            billId: billId,
            shopName: s.shopName,
            unpaidMembers: s.unpaidMembers,
            senderId: s.ownerId,
            senderName: widget.hostName ?? 'เจ้าของบิล',
            promptPay: widget.hostPromptPay,
            bankAccount: widget.hostBankAccount,
          );

      if (mounted) {
        setState(() {
          _statusFeedback = sentCount > 0
              ? 'ส่งการแจ้งเตือนภายในแอปให้เพื่อน $sentCount คนเรียบร้อยแล้ว ✅'
              : 'ไม่มีผู้ร่วมบิลที่มีบัญชีผู้ใช้ให้ส่งการแจ้งเตือน';
          _feedbackColor = AppColors.tealGreen;
        });
      }
    } catch (e) {
      debugPrint('ส่งการแจ้งเตือนภายในแอปไม่สำเร็จ: $e');
      if (mounted) {
        setState(() {
          _statusFeedback = 'ส่งการแจ้งเตือนภายในแอปไม่สำเร็จ กรุณาลองอีกครั้ง';
          _feedbackColor = Colors.red;
        });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _copyText() async {
    final text = _buildReminderText();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      setState(() {
        _statusFeedback =
            'คัดลอกข้อความทวงเงินเรียบร้อยแล้ว สามารถนำไปส่งได้ทันที 📋';
        _feedbackColor = AppColors.tealGreen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.summary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFD97706),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สะกิดเตือนเพื่อนค้างชำระ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.black,
                      ),
                    ),
                    Text(
                      s.shopName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Target unpaid friends list
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ผู้ที่ยังรอชำระเงิน (${s.unpaidCount} คน)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                    Text(
                      '${s.percentage}% เก็บแล้ว',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (s.unpaidMembers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'สมาชิกทุกคนชำระเงินครบแล้ว 🎉',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.tealGreen,
                      ),
                    ),
                  )
                else
                  ...s.unpaidMembers.map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: Color(0xFFEA580C),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                m.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.black,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '฿${AppFormatters.formatCurrency(m.amount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_statusFeedback != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (_feedbackColor ?? AppColors.tealGreen).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (_feedbackColor ?? AppColors.tealGreen).withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Text(
                _statusFeedback!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _feedbackColor ?? AppColors.tealGreen,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action Options
          const Text(
            'เลือกช่องทางการสะกิดเตือน',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 8),

          // 1. LINE Share
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: const Color(0xFF06C755).withValues(alpha: 0.08),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF06C755),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: const Text(
              'ส่งข้อความทวงเงินเข้า LINE',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text(
              'เปิด LINE และเลือกเพื่อนหรือกลุ่มเพื่อส่งทันที',
              style: TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _isProcessing ? null : _shareToLine,
          ),
          const SizedBox(height: 8),

          // 2. Full Share / Social
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0284C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: const Text(
              'แชร์สรุปบิลครบถ้วน (LINE / รูปภาพ)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text(
              'แชร์รายละเอียดบิล, จำนวนเงินทุกคน, และสถานะ',
              style: TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _isProcessing ? null : _shareFullSummary,
          ),
          const SizedBox(height: 8),

          // 3. In-App Notification
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.pink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: const Text(
              'ส่งการแจ้งเตือนภายในแอป',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text(
              'ส่งเข้าศูนย์แจ้งเตือนของเพื่อนใน Snap2Bill',
              style: TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _isProcessing ? null : _sendInAppNotification,
          ),
          const SizedBox(height: 8),

          // 4. Copy Text
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: isDark ? AppColors.darkSurface : const Color(0xFFF1F5F9),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.copy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: const Text(
              'คัดลอกข้อความทวงเงิน',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text(
              'คัดลอกข้อความพร้อมเลขบัญชีและพร้อมเพย์',
              style: TextStyle(fontSize: 11.5),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            onTap: _isProcessing ? null : _copyText,
          ),
        ],
      ),
    );
  }
}
