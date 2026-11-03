import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bill_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/menu_icon_helper.dart';

class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic> receiptData;
  final Uint8List? receiptImageBytes;

  const ReviewScreen({
    super.key,
    required this.receiptData,
    this.receiptImageBytes,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late String _shopName;
  late double _vat;
  late double _sc;
  late double _discount;
  late double _finalTotal;
  late bool _isVatIncluded;
  bool _enableVat = false;
  bool _enableSc = false;
  String _splitModel = 'proportional'; // 'proportional' or 'equal'
  bool _useReceiptTotal = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _shopName =
        widget.receiptData['shop_name']?.toString() ?? 'ไม่ระบุชื่อร้าน';
    _isVatIncluded = widget.receiptData['is_vat_included'] == true;
    _vat = _isVatIncluded
        ? 0
        : double.tryParse(
                widget.receiptData['vat_amount']?.toString() ?? '0',
              ) ??
              0.0;
    _sc =
        double.tryParse(
          widget.receiptData['service_charge']?.toString() ?? '0',
        ) ??
        0.0;
    _discount =
        double.tryParse(widget.receiptData['discount']?.toString() ?? '0') ??
        0.0;
    _finalTotal =
        double.tryParse(
          (widget.receiptData['final_total'] ??
                      widget.receiptData['total_amount'])
                  ?.toString() ??
              '',
        ) ??
        0.0;

    _enableVat = _vat > 0;
    _enableSc = _sc > 0;
    _useReceiptTotal = widget.receiptData['totals_reconciled'] == true;

    final aiItems = widget.receiptData['items'] as List<dynamic>? ?? [];
    _items = aiItems.map((e) => Map<String, dynamic>.from(e)).where((item) {
      final price =
          double.tryParse(
            (item['unit_price'] ?? item['price'] ?? 0).toString(),
          ) ??
          0.0;
      final total =
          double.tryParse((item['total_price'] ?? 0).toString()) ?? 0.0;
      final name = (item['name'] ?? item['item_name'])?.toString().trim() ?? '';
      return name.isNotEmpty && (price > 0 || total > 0);
    }).toList();
  }

  double _calculateSubtotal() {
    var subTotal = 0.0;
    for (final item in _items) {
      final qty = int.tryParse(item['qty'].toString()) ?? 1;
      final price = double.tryParse(item['unit_price'].toString()) ?? 0.0;
      subTotal += (qty * price);
    }
    return subTotal;
  }

  double _calculateTotal() {
    if (_useReceiptTotal && _finalTotal > 0) {
      return _finalTotal;
    }
    return _calculateSubtotal() + _vat + _sc - _discount;
  }

  double get _calculatedComponents =>
      _calculateSubtotal() + _vat + _sc - _discount;

  double get _receiptDifference => _finalTotal - _calculatedComponents;

  bool get _hasCalculationMismatch =>
      _receiptDifference.abs() > 0.05 && _finalTotal > 0;

  void _onToggleVat(bool enabled) {
    setState(() {
      _enableVat = enabled;
      if (enabled) {
        final sub = _calculateSubtotal();
        _vat = double.parse((sub * 0.07).toStringAsFixed(2));
      } else {
        _vat = 0.0;
      }
    });
  }

  void _onToggleSc(bool enabled) {
    setState(() {
      _enableSc = enabled;
      if (enabled) {
        final sub = _calculateSubtotal();
        _sc = double.parse((sub * 0.10).toStringAsFixed(2));
      } else {
        _sc = 0.0;
      }
    });
  }

  Future<void> _showEditHeaderDialog() async {
    final colors = context.appColors;
    final shopCtrl = TextEditingController(text: _shopName);
    final discCtrl = TextEditingController(text: _discount.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'แก้ไขข้อมูลร้านค้า & ส่วนลด',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: shopCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อร้านค้า'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'ส่วนลดทั้งหมด (บาท)',
                  prefixIcon: Icon(Icons.discount_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _shopName = shopCtrl.text.trim().isEmpty
                    ? 'ไม่ระบุชื่อร้าน'
                    : shopCtrl.text.trim();
                _discount = double.tryParse(discCtrl.text) ?? 0.0;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditItemDialog(int index) async {
    final colors = context.appColors;
    final isNew = index == -1;
    final item = isNew
        ? {'item_name': '', 'qty': 1, 'unit_price': 0.0}
        : _items[index];

    final nameCtrl = TextEditingController(text: item['item_name'].toString());
    final qtyCtrl = TextEditingController(text: item['qty'].toString());
    final priceCtrl = TextEditingController(
      text: item['unit_price'].toString(),
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isNew ? '➕ เพิ่มรายการใหม่' : '✏️ แก้ไขรายการอาหาร',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเมนู',
                  hintText: 'เช่น ชุดเนื้อวากิว, ชาเขียว',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'จำนวน'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'ราคา/หน่วย (฿)',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final rawName = nameCtrl.text.trim();
              if (rawName.isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              final unitPrice = double.tryParse(priceCtrl.text) ?? 0.0;
              if (unitPrice <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาระบุราคาที่มากกว่า 0 บาท'),
                  ),
                );
                return;
              }
              final updatedItem = {
                'item_name': rawName,
                'name': rawName,
                'qty': qty,
                'unit_price': unitPrice,
                'total_price': qty * unitPrice,
              };
              setState(() {
                if (isNew) {
                  _items.add(updatedItem);
                } else {
                  _items[index] = updatedItem;
                }

                if (_enableVat) {
                  _vat = double.parse(
                    (_calculateSubtotal() * 0.07).toStringAsFixed(2),
                  );
                }
                if (_enableSc) {
                  _sc = double.parse(
                    (_calculateSubtotal() * 0.10).toStringAsFixed(2),
                  );
                }
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  void _confirmAndGoNext() {
    context.read<BillProvider>().setSplitType(_splitModel);

    final updatedReceiptData = Map<String, dynamic>.from(widget.receiptData);
    updatedReceiptData['shop_name'] = _shopName;
    updatedReceiptData['vat_amount'] = _vat;
    updatedReceiptData['is_vat_included'] = _isVatIncluded;
    updatedReceiptData['service_charge'] = _sc;
    updatedReceiptData['discount'] = _discount;
    updatedReceiptData['split_model'] = _splitModel;

    // กรองเฉพาะรายการที่มีราคามากกว่า 0 บาทก่อนส่งต่อไปยัง Lobby และ Claim Items
    _items = _items.where((item) {
      final unitPrice =
          double.tryParse(
            (item['unit_price'] ?? item['price'] ?? 0).toString(),
          ) ??
          0.0;
      final totalPrice =
          double.tryParse((item['total_price'] ?? 0).toString()) ?? 0.0;
      final name = (item['name'] ?? item['item_name'])?.toString().trim() ?? '';
      return name.isNotEmpty && (unitPrice > 0 || totalPrice > 0);
    }).toList();

    double subTotal = 0;
    for (var item in _items) {
      final qty = int.tryParse(item['qty'].toString()) ?? 1;
      final price = double.tryParse(item['unit_price'].toString()) ?? 0.0;
      item['total_price'] = qty * price;
      subTotal += item['total_price'];
    }

    updatedReceiptData['sub_total'] = subTotal;
    updatedReceiptData['final_total'] = _calculateTotal();
    updatedReceiptData['total_amount'] = _calculateTotal();
    updatedReceiptData['items'] = _items;
    updatedReceiptData['receipt_total_used'] = _useReceiptTotal;

    Navigator.pushNamed(
      context,
      AppRoutes.lobby,
      arguments: {
        'receiptData': updatedReceiptData,
        'receiptImageBytes': widget.receiptImageBytes,
      },
    );
  }

  Color _getDishColor(int index) {
    const colors = [
      AppColors.lightPink,
      AppColors.paleYellow,
      AppColors.lightGreen,
      AppColors.lightPink,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final subTotal = _calculateSubtotal();
    final total = _calculateTotal();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('ตรวจสอบใบเสร็จ'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline_rounded,
              color: colors.tealText,
            ),
            tooltip: 'เพิ่มเมนูเอง',
            onPressed: () => _showEditItemDialog(-1),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasCalculationMismatch)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.warningContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: colors.textPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ยอดรายการไม่ตรงกับยอดสุทธิที่พิมพ์บนใบเสร็จ อาจเกิดจากร้านค้าคำนวณหรือพิมพ์ยอดคลาดเคลื่อน ไม่ใช่ความผิดพลาดของการอ่านข้อมูล',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                if (_receiptDifference > 0.05) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'รายการรวม ${AppFormatters.formatCurrency(_calculatedComponents)} บาท แต่ TOTAL บนใบเสร็จเป็น ${AppFormatters.formatCurrency(_finalTotal)} บาท (ต่างกัน ${AppFormatters.formatCurrency(_receiptDifference)} บาท)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'กรณีนี้อาจเป็นการพิมพ์ยอดรวมของร้านค้าผิด ระบบจะไม่เพิ่มส่วนต่างให้อัตโนมัติ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => setState(
                                          () => _useReceiptTotal = false,
                                        ),
                                        child: Text(
                                          _useReceiptTotal
                                              ? 'ใช้ยอดรายการ ${AppFormatters.formatCurrency(_calculatedComponents)}'
                                              : 'ใช้ยอดรายการอยู่',
                                        ),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => setState(
                                          () => _useReceiptTotal = true,
                                        ),
                                        child: Text(
                                          _useReceiptTotal
                                              ? 'ใช้ยอดใบเสร็จอยู่'
                                              : 'ใช้ TOTAL ${AppFormatters.formatCurrency(_finalTotal)}',
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (_receiptDifference < -0.05) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'ยอดรายการสูงกว่ายอดสุทธิบนใบเสร็จ ${AppFormatters.formatCurrency(_receiptDifference.abs())} กรุณาตรวจสอบรายการ ส่วนลด และค่าธรรมเนียม',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // แถบ Step Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.successContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ขั้นตอน 2 จาก 6  ตรวจสอบใบเสร็จ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.onSuccessContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'ยกเลิกบิล',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // การ์ดข้อมูลร้านค้า
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _showEditHeaderDialog,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.successContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: colors.onSuccessContainer,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _shopName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: colors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'แตะเพื่อแก้ไขชื่อร้าน หรือใส่ส่วนลด',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.edit_note_rounded,
                            color: colors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // แบนเนอร์แสดงความเร็ว AI OCR (Soft Periwinkle Card)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 18,
                          color: colors.tealText,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'AI ถอดข้อมูลสำเร็จใน ~1.8 วินาที',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.accentContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${_items.length} รายการ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: colors.onAccentContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'ตรวจสอบยอดถูกต้องครบถ้วน และกดไอคอนดินสอเพื่อปรับปรุงจำนวนหรือราคาได้ทันที',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ส่วนรายการอาหาร
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'รายการอาหาร',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colors.successContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_items.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.onSuccessContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'ราคาต่อหน่วย x จำนวน',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ลิสต์รายการอาหาร
                  if (_items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.fastfood_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ไม่มีรายการอาหาร',
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final name = item['item_name']?.toString() ?? 'เมนู';
                      final qty = int.tryParse(item['qty'].toString()) ?? 1;
                      final unitPrice =
                          double.tryParse(item['unit_price'].toString()) ?? 0.0;
                      final itemTotal = qty * unitPrice;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _getDishColor(index),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  MenuIconHelper.getDishEmoji(name),
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
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$qty ชุด • ${AppFormatters.formatCurrency(unitPrice)} / ชุด',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.formatCurrency(itemTotal),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: colors.textSecondary,
                              ),
                              tooltip: 'แก้ไข',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              onPressed: () => _showEditItemDialog(index),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.error,
                              ),
                              tooltip: 'ลบ',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 28,
                                height: 28,
                              ),
                              onPressed: () => setState(() {
                                _items.removeAt(index);
                              }),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 6),

                  // ปุ่มเพิ่มรายการเอง
                  OutlinedButton.icon(
                    onPressed: () => _showEditItemDialog(-1),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'เพิ่มรายการอาหารเอง',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.tealText,
                      side: BorderSide(color: colors.tealText, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ส่วนการตั้งค่าการคิดเงิน (Service Charge, VAT, Split Model)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '⚙️ ตั้งค่าการคิดเงิน',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: colors.textPrimary,
                              ),
                            ),
                            Text(
                              'ปรับตามใบเสร็จจริง',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Service Charge 10%
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Service Charge 10%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (_enableSc) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.successContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '+${AppFormatters.formatCurrency(_sc)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: colors.onSuccessContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'คำนวณอัตโนมัติจากค่าอาหาร',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _enableSc,
                              activeThumbColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withValues(
                                alpha: 0.5,
                              ),
                              onChanged: _onToggleSc,
                            ),
                          ],
                        ),
                        Divider(height: 18, color: colors.divider),

                        // VAT 7%
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'VAT 7%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (_enableVat) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.successContainer,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '+${AppFormatters.formatCurrency(_vat)}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: colors.onSuccessContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'คำนวณจากค่าอาหารรวม Service Charge',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _enableVat,
                              activeThumbColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withValues(
                                alpha: 0.5,
                              ),
                              onChanged: _onToggleVat,
                            ),
                          ],
                        ),
                        Divider(height: 18, color: colors.divider),

                        // โหมดการหาร
                        const Text(
                          'โหมดการหารค่าใช้จ่าย',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ตัวเลือก 1: หารตามสัดส่วน (แนะนำ)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              setState(() => _splitModel = 'proportional'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _splitModel == 'proportional'
                                  ? colors.successContainer
                                  : colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _splitModel == 'proportional'
                                    ? AppColors.primary
                                    : colors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _splitModel == 'proportional'
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: _splitModel == 'proportional'
                                      ? colors.onSuccessContainer
                                      : colors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'หารตามสัดส่วน',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colors.accentContainer,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'แนะนำ',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: colors.onAccentContainer,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'จ่ายเฉพาะสิ่งที่เลือกกินจริง แฟร์ที่สุด',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ตัวเลือก 2: หารเท่าทุกคน
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() => _splitModel = 'equal'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _splitModel == 'equal'
                                  ? colors.successContainer
                                  : colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _splitModel == 'equal'
                                    ? AppColors.primary
                                    : colors.border,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _splitModel == 'equal'
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: _splitModel == 'equal'
                                      ? colors.onSuccessContainer
                                      : colors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'หารเท่าทุกคน',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'นำยอดรวมสุทธิมาแบ่งเท่ากันตามจำนวนคน',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ทิปคำแนะนำ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.successContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          size: 16,
                          color: colors.onSuccessContainer,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'เพื่อนร่วมโต๊ะจะสแกนเลือกจานตัวเองได้ในหน้าถัดไป',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.onSuccessContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Sticky Bottom Summary Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Breakdown Chips
                  Row(
                    children: [
                      Text(
                        'ยอดอาหาร ${AppFormatters.formatCurrency(subTotal)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      if (_sc > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SVC ${AppFormatters.formatCurrency(_sc)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      if (_vat > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'VAT ${AppFormatters.formatCurrency(_vat)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.successContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _hasCalculationMismatch
                              ? (_useReceiptTotal
                                    ? 'ใช้ TOTAL ใบเสร็จ'
                                    : 'ใช้ยอดรายการ')
                              : '✓ ตรงใบเสร็จ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _hasCalculationMismatch
                                ? colors.textPrimary
                                : colors.onSuccessContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // แถวปุ่มยืนยันพร้อมราคารวมสุทธิ
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ยอดรวมสุทธิ',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                            Text(
                              AppFormatters.formatCurrency(total),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: colors.tealText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _confirmAndGoNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ยืนยัน & ชวนเพื่อน',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
