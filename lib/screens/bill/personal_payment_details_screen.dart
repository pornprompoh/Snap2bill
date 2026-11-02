import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/menu_icon_helper.dart';
import '../../utils/promptpay_helper.dart';
import '../../widgets/bill/member_summary_list.dart';
import '../../services/media/qr_image_saver.dart';
import '../../services/offline/offline_service.dart';

class PersonalPaymentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> billData;
  final MemberSummaryEntry member;
  final String hostPromptPay;
  final String? hostPromptPayType;
  final String? hostBankName;
  final String hostBankAccountNumber;
  final String? hostBankAccountName;
  final String hostName;
  final bool isCurrentViewerOwner;
  final double receiptSubTotal;
  final double receiptVat;
  final double receiptServiceCharge;
  final double receiptDiscount;
  final void Function(String newStatus, String? slipUrl)? onStatusChanged;

  const PersonalPaymentDetailsScreen({
    super.key,
    required this.billData,
    required this.member,
    required this.hostPromptPay,
    this.hostPromptPayType,
    this.hostBankName,
    required this.hostBankAccountNumber,
    this.hostBankAccountName,
    required this.hostName,
    required this.isCurrentViewerOwner,
    this.receiptSubTotal = 0.0,
    this.receiptVat = 0.0,
    this.receiptServiceCharge = 0.0,
    this.receiptDiscount = 0.0,
    this.onStatusChanged,
  });

  @override
  State<PersonalPaymentDetailsScreen> createState() =>
      _PersonalPaymentDetailsScreenState();
}

class _PersonalPaymentDetailsScreenState
    extends State<PersonalPaymentDetailsScreen> {
  final GlobalKey _qrCaptureKey = GlobalKey();
  late String _status;
  String? _slipUrl;
  bool _isSavingQr = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _status = widget.member.status;
    _slipUrl = widget.member.slipUrl;
  }

  bool get _isPaid => _status == 'paid';
  bool get _isReviewing =>
      _status == 'reviewing' || _status == 'pending_verification';

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  // คำนวณส่วนแบ่ง VAT & Service Charge ตามสัดส่วนของยอดอาหาร
  double get _memberFoodSubtotal {
    return widget.member.dishes.fold<double>(
      0.0,
      (sum, dish) => sum + dish.totalPrice,
    );
  }

  double get _memberServiceChargeShare {
    if (widget.receiptSubTotal <= 0 || widget.receiptServiceCharge <= 0) {
      return 0.0;
    }
    final ratio = _memberFoodSubtotal / widget.receiptSubTotal;
    return (widget.receiptServiceCharge * ratio).ceilToDouble();
  }

  double get _memberVatShare {
    if (widget.receiptSubTotal <= 0 || widget.receiptVat <= 0) return 0.0;
    final ratio = _memberFoodSubtotal / widget.receiptSubTotal;
    return (widget.receiptVat * ratio).ceilToDouble();
  }

  // 📥 บันทึก QR Code ลงในเครื่อง
  Future<void> _handleSaveQrCode() async {
    if (_isSavingQr) return;
    setState(() => _isSavingQr = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          _qrCaptureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        throw StateError('ไม่พบคิวอาร์โค้ด');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('แปลงภาพคิวอาร์ไม่สำเร็จ');
      }

      final pngBytes = byteData.buffer.asUint8List();
      await saveQrImage(pngBytes, 'qr_${widget.member.name}.png');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกคิวอาร์โค้ดลงเครื่องสำเร็จ 📥'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      await _queueLocalBillChanges(e, participantStatus: 'reviewing');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึกรูป: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingQr = false);
    }
  }

  // 📋 คัดลอกยอดเงิน
  void _handleCopyAmount() {
    Clipboard.setData(
      ClipboardData(text: widget.member.amount.ceil().toString()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'คัดลอกยอดเงิน ${AppFormatters.formatCurrency(widget.member.amount)} แล้ว 📋',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 📸 แนบสลิปหลักฐานการโอนเงิน (Upload Payment Slip)
  Future<void> _handleUploadSlip() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _isUpdating = true);
    try {
      final bytes = await file.readAsBytes();
      final slipDataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final billId = widget.billData['id']?.toString();
      if (billId != null) {
        final receipt = _asMap(widget.billData['receipt_json']);
        final paymentSlips = _asMap(receipt['payment_slips']);
        paymentSlips[widget.member.id] = slipDataUri;
        receipt['payment_slips'] = paymentSlips;

        final paidStatuses = _asMap(receipt['paid_statuses']);
        paidStatuses[widget.member.id] = 'reviewing';
        receipt['paid_statuses'] = paidStatuses;

        // อัปเดต bills table
        await Supabase.instance.client
            .from('bills')
            .update({'receipt_json': receipt})
            .eq('id', billId);
        widget.billData['receipt_json'] = receipt;

        // ถ้าเป็นสมาชิกที่ลงทะเบียน ให้อัปเดต bill_participants ด้วย
        if (!widget.member.isGuest) {
          try {
            await Supabase.instance.client
                .from('bill_participants')
                .update({'status': 'reviewing'})
                .eq('bill_id', billId)
                .eq('profile_id', widget.member.id);
          } catch (_) {}
        }
      }

      setState(() {
        _status = 'reviewing';
        _slipUrl = slipDataUri;
      });

      widget.onStatusChanged?.call('reviewing', slipDataUri);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('แนบสลิปเรียบร้อยแล้ว สถานะ: รอตรวจสอบ ⏳'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      await _queueLocalBillChanges(e, participantStatus: 'paid');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('แนบสลิปไม่สำเร็จ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ✅ เจ้าของบิลยืนยันการชำระเงิน (Approve)
  Future<void> _handleApprovePayment() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final billId = widget.billData['id']?.toString();
      if (billId != null) {
        final receipt = _asMap(widget.billData['receipt_json']);
        final paidStatuses = _asMap(receipt['paid_statuses']);
        paidStatuses[widget.member.id] = 'paid';
        receipt['paid_statuses'] = paidStatuses;

        await Supabase.instance.client
            .from('bills')
            .update({'receipt_json': receipt})
            .eq('id', billId);
        widget.billData['receipt_json'] = receipt;

        if (!widget.member.isGuest) {
          try {
            await Supabase.instance.client
                .from('bill_participants')
                .update({'status': 'paid'})
                .eq('bill_id', billId)
                .eq('profile_id', widget.member.id);
          } catch (_) {}
        }

        // ตรวจสอบว่าสมาชิกทุกคนชำระครบแล้วหรือไม่ เพื่อเปลี่ยนสถานะบิลเป็น completed
        _checkAndAutoSettleBill(billId, receipt);
      }

      setState(() => _status = 'paid');
      widget.onStatusChanged?.call('paid', _slipUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ยืนยันการชำระเงินของ ${widget.member.name} แล้ว ✅'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      await _queueLocalBillChanges(e, participantStatus: 'pending');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ยืนยันไม่สำเร็จ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // ❌ เจ้าของบิลปฏิเสธสลิป (Reject) ให้ส่งสลิปใหม่
  Future<void> _handleRejectPayment() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      final billId = widget.billData['id']?.toString();
      if (billId != null) {
        final receipt = _asMap(widget.billData['receipt_json']);
        final paidStatuses = _asMap(receipt['paid_statuses']);
        paidStatuses[widget.member.id] = 'pending';
        receipt['paid_statuses'] = paidStatuses;

        final paymentSlips = _asMap(receipt['payment_slips']);
        paymentSlips.remove(widget.member.id);
        receipt['payment_slips'] = paymentSlips;

        await Supabase.instance.client
            .from('bills')
            .update({'receipt_json': receipt, 'status': 'pending'})
            .eq('id', billId);
        widget.billData['receipt_json'] = receipt;
        widget.billData['status'] = 'pending';

        if (!widget.member.isGuest) {
          try {
            await Supabase.instance.client
                .from('bill_participants')
                .update({'status': 'pending'})
                .eq('bill_id', billId)
                .eq('profile_id', widget.member.id);
          } catch (_) {}
        }
      }

      setState(() {
        _status = 'pending';
        _slipUrl = null;
      });
      widget.onStatusChanged?.call('pending', null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ปฏิเสธสลิปแล้ว ผู้เข้าร่วมสามารถแนบสลิปใหม่ได้ ⚠️'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ดำเนินการไม่สำเร็จ: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _checkAndAutoSettleBill(
    String billId,
    Map<String, dynamic> receipt,
  ) async {
    try {
      final paidStatuses = _asMap(receipt['paid_statuses']);
      final rows = await Supabase.instance.client
          .from('bill_participants')
          .select('profile_id, status')
          .eq('bill_id', billId);

      bool allSettled = true;
      for (final r in rows) {
        final pid = r['profile_id']?.toString();
        final s = r['status']?.toString();
        if (pid != null &&
            pid != widget.billData['owner_id'] &&
            s != 'paid' &&
            paidStatuses[pid] != 'paid') {
          allSettled = false;
          break;
        }
      }

      for (final entry in paidStatuses.entries) {
        if (entry.key != widget.billData['owner_id'] && entry.value != 'paid') {
          allSettled = false;
          break;
        }
      }

      final newBillStatus = allSettled ? 'completed' : 'pending';
      await Supabase.instance.client
          .from('bills')
          .update({'status': newBillStatus})
          .eq('id', billId);
      widget.billData['status'] = newBillStatus;
    } catch (error) {
      await _queueLocalBillChanges(
        error,
        participantStatus: null,
        statusOverride: widget.billData['status']?.toString(),
      );
    }
  }

  Future<void> _queueLocalBillChanges(
    Object error, {
    required String? participantStatus,
    String? statusOverride,
  }) async {
    final offline = context.read<OfflineService>();
    final billId = widget.billData['id']?.toString();
    if (billId == null ||
        (!offline.isOffline && !OfflineService.isLikelyNetworkError(error))) {
      return;
    }

    final receipt = _asMap(widget.billData['receipt_json']);
    final billData = <String, dynamic>{'receipt_json': receipt};
    final status = statusOverride ?? widget.billData['status']?.toString();
    if (status != null && status.isNotEmpty) billData['status'] = status;
    await offline.queue.enqueue(
      type: 'update_bill',
      payload: {'id': billId, 'data': billData},
    );
    if (participantStatus != null && !widget.member.isGuest) {
      await offline.queue.enqueue(
        type: 'update_participant',
        payload: {
          'bill_id': billId,
          'profile_id': widget.member.id,
          'data': {'status': participantStatus},
        },
      );
    }
  }

  // 🔍 เปิดดูภาพสลิปแบบขยายเต็มจอ
  void _openSlipFullView(String slipUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 600),
                  color: Colors.black87,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: _buildSlipImageWidget(slipUrl),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlipImageWidget(String slipUrl) {
    if (slipUrl.startsWith('data:image')) {
      final base64String = slipUrl.split(',').last;
      return Image.memory(base64Decode(base64String), fit: BoxFit.contain);
    }
    return Image.network(
      slipUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Padding(
        padding: EdgeInsets.all(32),
        child: Icon(Icons.broken_image, size: 64, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final hasPromptPay = widget.hostPromptPay.isNotEmpty;
    String qrPayload = '';
    if (hasPromptPay && member.amount > 0) {
      try {
        qrPayload = PromptPayHelper.generatePayload(
          widget.hostPromptPay,
          amount: member.amount,
          targetType: widget.hostPromptPayType,
        );
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('รายละเอียดการชำระเงินรายบุคคล'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // ส่วนที่ 1: ข้อมูลผู้เข้าร่วม (Participant Header)
            // ==========================================
            _buildParticipantHeaderCard(member),
            const SizedBox(height: 16),

            // ==========================================
            // ส่วนที่ 2: รายการอาหารที่เลือก (Selected Dishes)
            // ==========================================
            _buildSelectedDishesCard(member),
            const SizedBox(height: 16),

            // ==========================================
            // ส่วนที่ 3: สรุปยอดเงิน (Financial Breakdown)
            // ==========================================
            _buildFinancialBreakdownCard(member),
            const SizedBox(height: 16),

            // ==========================================
            // ส่วนที่ 4: QR Code สำหรับชำระเงิน (PromptPay QR)
            // ==========================================
            _buildPaymentQrCard(member, hasPromptPay, qrPayload),
            const SizedBox(height: 16),

            // ==========================================
            // ส่วนที่ 5: ระบบแจ้งและยืนยันการชำระเงิน (Slip & Verification)
            // ==========================================
            _buildSlipAndVerificationCard(member),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Card 1: Participant Header
  Widget _buildParticipantHeaderCard(MemberSummaryEntry member) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: member.isOwner
                ? const Color(0xFFFEF3C7)
                : (_isPaid
                      ? Colors.green.shade50
                      : (_isReviewing
                            ? Colors.blue.shade50
                            : Colors.orange.shade50)),
            child: _isValidImageUrl(member.avatarUrl)
                ? ClipOval(
                    child: Image.network(
                      member.avatarUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildMemberInitial(member),
                    ),
                  )
                : _buildMemberInitial(member),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (member.isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: const Text(
                          'เจ้าของ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ] else if (member.isGuest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.deepOrange.shade200),
                        ),
                        child: const Text(
                          'Guest',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'ยอดชำระ: ${AppFormatters.formatCurrency(member.amount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          _buildStatusBadge(),
        ],
      ),
    );
  }

  bool _isValidImageUrl(String? value) {
    final url = value?.trim();
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  Widget _buildMemberInitial(MemberSummaryEntry member) {
    if (member.isOwner) {
      return const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 30);
    }
    return Text(
      member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: _isPaid
            ? Colors.green.shade700
            : (_isReviewing ? Colors.blue.shade700 : Colors.orange.shade800),
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (widget.member.isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 14, color: Color(0xFFB45309)),
            SizedBox(width: 4),
            Text(
              'เจ้าของ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
      );
    }
    if (_isPaid) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(
              'ชำระแล้ว',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      );
    }
    if (_isReviewing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.blue.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              size: 14,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              'รอตรวจสอบ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: Colors.orange.shade800),
          const SizedBox(width: 4),
          Text(
            'ยังไม่ชำระ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Selected Dishes
  Widget _buildSelectedDishesCard(MemberSummaryEntry member) {
    final dishes = member.dishes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'รายการอาหารที่เลือก',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dishes.length} รายการ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (dishes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ไม่ได้เลือกรายการอาหารแยกส่วนบุคคล (แชร์ตามสัดส่วน)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dishes.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final dish = dishes[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.warmCream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          MenuIconHelper.getDishEmoji(dish.itemName),
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dish.itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dish.isShared
                                ? 'แชร์ร่วมกัน (${dish.quantity} ชิ้น / ${dish.totalSharers} คน)'
                                : 'ส่วนตัว ${dish.quantity} ชิ้น @ ${AppFormatters.formatCurrency(dish.unitPrice)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(dish.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Card 3: Financial Breakdown
  Widget _buildFinancialBreakdownCard(MemberSummaryEntry member) {
    final foodSubtotal = _memberFoodSubtotal > 0
        ? _memberFoodSubtotal
        : member.amount;
    final sc = _memberServiceChargeShare;
    final vat = _memberVatShare;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปยอดเงิน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 20),
          _buildBreakdownRow('ยอดรวมค่าอาหาร (Subtotal)', foodSubtotal),
          if (sc > 0) _buildBreakdownRow('ส่วนแบ่ง Service Charge', sc),
          if (vat > 0) _buildBreakdownRow('ส่วนแบ่ง VAT', vat),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดเงินสุทธิที่ต้องชำระ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                AppFormatters.formatCurrency(member.amount),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          Text(
            AppFormatters.formatCurrency(amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // Card 4: PromptPay QR Code
  Widget _buildPaymentQrCard(
    MemberSummaryEntry member,
    bool hasPromptPay,
    String qrPayload,
  ) {
    if (member.isOwner) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: const Row(
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFB45309), size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'คุณเป็นเจ้าของบิล รายการนี้จึงไม่ต้องชำระเงินให้ตนเอง 👑',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB45309),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isPaid) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.green.shade700,
              size: 36,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ชำระเงินสำเร็จเรียบร้อยแล้ว 🎉',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ยอด ${AppFormatters.formatCurrency(member.amount)} ได้รับการยืนยันแล้ว',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (!hasPromptPay) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚠️ เจ้าของบิลยังไม่ได้ตั้งค่าพร้อมเพย์ กรุณาแนะนำให้เจ้าของบิลระบุเลขพร้อมเพย์ในหน้าโปรไฟล์',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.brown,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PromptPay QR Code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'คิวอาร์ระบุยอดเงินตรงเป๊ะ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // RepaintBoundary for QR image capturing
          Center(
            child: RepaintBoundary(
              key: _qrCaptureKey,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: qrPayload,
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
                    const SizedBox(height: 6),
                    Text(
                      'พร้อมเพย์: ${widget.hostPromptPay}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      '(${widget.hostName})',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ยอดสแกนจ่าย: ${AppFormatters.formatCurrency(member.amount)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons: Save QR & Copy Amount
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleSaveQrCode,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'บันทึก QR Code',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _handleCopyAmount,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text(
                    'คัดลอกยอดเงิน',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),

          // ทางเลือกโอนผ่านเลขบัญชีธนาคาร (ถ้ามี)
          if (widget.hostBankAccountNumber.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightPink.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.pink.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance,
                    color: AppColors.pink,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.hostBankName ?? 'ธนาคาร'}: ${widget.hostBankAccountNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ชื่อบัญชี: ${widget.hostBankAccountName ?? widget.hostName}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy,
                      size: 18,
                      color: AppColors.pink,
                    ),
                    tooltip: 'คัดลอกเลขบัญชี',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.hostBankAccountNumber),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('คัดลอกเลขบัญชีแล้ว 📋')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Card 5: Slip Upload & Verification Workflow
  Widget _buildSlipAndVerificationCard(MemberSummaryEntry member) {
    if (member.isOwner) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ระบบแจ้งและยืนยันการชำระเงิน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Divider(height: 20),

          // แสดงสลิปที่แนบไว้ (ถ้ามี)
          if (_slipUrl != null && _slipUrl!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _openSlipFullView(_slipUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.black12,
                        child: _buildSlipImageWidget(_slipUrl!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'หลักฐานการโอนเงิน (สลิป)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isPaid
                              ? 'ยืนยันความถูกต้องแล้ว ✅'
                              : 'สถานะ: รอเจ้าของบิลตรวจสอบ ⏳',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isPaid
                                ? Colors.green.shade700
                                : Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openSlipFullView(_slipUrl!),
                    icon: const Icon(Icons.fullscreen, size: 16),
                    label: const Text('ดูรูป', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ปุ่มแนบสลิป (Upload Payment Slip)
          if (!_isPaid) ...[
            FilledButton.icon(
              onPressed: _isUpdating ? null : _handleUploadSlip,
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                _slipUrl != null
                    ? 'แนบสลิปใหม่ / เปลี่ยนสลิป'
                    : 'แนบหลักฐานการโอนเงิน (Upload Slip)',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // เมนูจัดการสำหรับเจ้าของบิล (Approve / Reject)
          if (widget.isCurrentViewerOwner) ...[
            const Text(
              'สำหรับเจ้าของบิล:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            if (_isReviewing) ...[
              // แสดงปุ่ม ยืนยัน / ปฏิเสธ
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isUpdating ? null : _handleApprovePayment,
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('ยืนยันชำระเงิน'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.tealGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUpdating ? null : _handleRejectPayment,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('ปฏิเสธสลิป'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (_isPaid) ...[
              OutlinedButton.icon(
                onPressed: _isUpdating ? null : _handleRejectPayment,
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: const Text('ยกเลิกสถานะจ่ายแล้ว (เปลี่ยนเป็นรอจ่าย)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade300),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ] else ...[
              FilledButton.tonalIcon(
                onPressed: _isUpdating ? null : _handleApprovePayment,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('ทำเครื่องหมายว่าชำระแล้ว'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
