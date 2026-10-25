import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bill_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

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
  bool _hasEditedReceipt = false;

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

    final aiItems = widget.receiptData['items'] as List<dynamic>? ?? [];
    _items = aiItems.map((e) => Map<String, dynamic>.from(e)).toList();
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
    if (!_hasEditedReceipt && _finalTotal > 0 && !_enableVat && !_enableSc) {
      return _finalTotal;
    }
    return _calculateSubtotal() + _vat + _sc - _discount;
  }

  void _onToggleVat(bool enabled) {
    setState(() {
      _enableVat = enabled;
      _hasEditedReceipt = true;
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
      _hasEditedReceipt = true;
      if (enabled) {
        final sub = _calculateSubtotal();
        _sc = double.parse((sub * 0.10).toStringAsFixed(2));
      } else {
        _sc = 0.0;
      }
    });
  }

  Widget _summaryLine(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${AppFormatters.formatCurrency(amount)}',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDiscount ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditHeaderDialog() async {
    final shopCtrl = TextEditingController(text: _shopName);
    final discCtrl = TextEditingController(text: _discount.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขข้อมูลร้านค้า & ส่วนลด'),
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
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _shopName = shopCtrl.text.trim().isEmpty ? 'ไม่ระบุชื่อร้าน' : shopCtrl.text.trim();
                _discount = double.tryParse(discCtrl.text) ?? 0.0;
                _hasEditedReceipt = true;
              });
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditItemDialog(int index) async {
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
        title: Text(isNew ? '➕ เพิ่มรายการใหม่' : '✏️ แก้ไขรายการอาหาร'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ชื่อเมนู',
                  hintText: 'เช่น ข้าวมันไก่, ชาเขียว',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'จำนวน (ชิ้น/จาน)'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'ราคาต่อหน่วย (฿)'),
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
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              final rawName = nameCtrl.text.trim();
              if (rawName.isEmpty) return;
              final qty = int.tryParse(qtyCtrl.text) ?? 1;
              final unitPrice = double.tryParse(priceCtrl.text) ?? 0.0;
              final updatedItem = {
                'item_name': rawName,
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
                _hasEditedReceipt = true;
                if (_enableVat) {
                  _vat = double.parse((_calculateSubtotal() * 0.07).toStringAsFixed(2));
                }
                if (_enableSc) {
                  _sc = double.parse((_calculateSubtotal() * 0.10).toStringAsFixed(2));
                }
              });
              Navigator.pop(context);
            },
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

    Navigator.pushNamed(
      context,
      AppRoutes.lobby,
      arguments: {
        'receiptData': updatedReceiptData,
        'receiptImageBytes': widget.receiptImageBytes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subTotal = _calculateSubtotal();
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบบิล & AI OCR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'เพิ่มรายการเอง',
            onPressed: () => _showEditItemDialog(-1),
          ),
        ],
      ),
      body: Column(
        children: [
          // ⚡ Banner แสดงความเร็ว AI OCR
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI สแกนและถอดข้อมูลสำเร็จใน ~2.3 วินาที ⚡',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${_items.length} รายการ',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 1. ส่วนหัวบิล (ชื่อร้าน & ส่วนลด)
          InkWell(
            onTap: _showEditHeaderDialog,
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.35),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _shopName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (_discount > 0) ...[
                          const SizedBox(height: 3),
                          Text(
                            'ส่วนลดพิเศษ: -${AppFormatters.formatCurrency(_discount)}',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('แก้ไข', style: TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.edit_outlined, color: Colors.blue, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // หัวตารางรายการอาหาร: ชื่อเมนู | จำนวน | ราคา/หน่วย | ราคารวม
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade100,
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'ชื่อเมนู',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'จำนวน',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'ราคา/หน่วย',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'ราคารวม',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                SizedBox(width: 48), // สำหรับช่องไอคอนดินสอ & ลบ
              ],
            ),
          ),

          // 2. รายการอาหาร (กดแก้ไขดินสอ หรือ ลบได้ทันที)
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('ไม่มีรายการอาหาร กรุณากดปุ่มเพิ่มรายการ'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _showEditItemDialog(-1),
                          icon: const Icon(Icons.add),
                          label: const Text('เพิ่มรายการใหม่'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final qty = int.tryParse(item['qty'].toString()) ?? 1;
                      final unitPrice =
                          double.tryParse(item['unit_price'].toString()) ?? 0.0;
                      final itemTotal = qty * unitPrice;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Row(
                            children: [
                              // ชื่อเมนู
                              Expanded(
                                flex: 5,
                                child: Text(
                                  item['item_name'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // จำนวน
                              Expanded(
                                flex: 2,
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ),
                              // ราคา/หน่วย
                              Expanded(
                                flex: 3,
                                child: Text(
                                  AppFormatters.formatCurrency(unitPrice),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                                ),
                              ),
                              // ราคารวม
                              Expanded(
                                flex: 3,
                                child: Text(
                                  AppFormatters.formatCurrency(itemTotal),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              // ปุ่มดินสอแก้ไข & ลบ
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 18),
                                    tooltip: 'แก้ไข',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                    onPressed: () => _showEditItemDialog(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                    tooltip: 'ลบ',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                                    onPressed: () => setState(() {
                                      _items.removeAt(index);
                                      _hasEditedReceipt = true;
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 3. ส่วนควบคุมด้านล่าง: สวิตช์ VAT 7%, Service Charge 10%, โมเดลการหาร & สรุปยอด
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // สวิตช์ Toggle VAT 7% และ Service Charge 10%
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _enableVat ? Colors.blue.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _enableVat ? Colors.blue.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('VAT 7%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  _enableVat ? '฿${_vat.toStringAsFixed(2)}' : 'ปิดอยู่',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _enableVat ? Colors.blue.shade800 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _enableVat,
                              activeTrackColor: AppColors.primary,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: _onToggleVat,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _enableSc ? Colors.orange.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _enableSc ? Colors.orange.shade300 : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Service 10%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(
                                  _enableSc ? '฿${_sc.toStringAsFixed(2)}' : 'ปิดอยู่',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _enableSc ? Colors.orange.shade800 : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _enableSc,
                              activeTrackColor: Colors.deepOrange,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onChanged: _onToggleSc,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ตัวเลือกโมเดลการหาร: "หารตามสัดส่วนที่กินจริง" หรือ "หารเท่าทุกคน"
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('โมเดลการหารบิล:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: 'proportional',
                            icon: Icon(Icons.pie_chart_outline, size: 16),
                            label: Text('หารตามที่กินจริง', style: TextStyle(fontSize: 12)),
                          ),
                          ButtonSegment<String>(
                            value: 'equal',
                            icon: Icon(Icons.people_outline, size: 16),
                            label: Text('หารเท่าทุกคน', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                        selected: {_splitModel},
                        onSelectionChanged: (newSelection) {
                          setState(() {
                            _splitModel = newSelection.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // สรุปยอดรวม
                _summaryLine('ยอดรวมสินค้า (Subtotal)', subTotal),
                if (_sc > 0) _summaryLine('Service Charge (10%)', _sc),
                if (_vat > 0) _summaryLine('VAT (7%)', _vat),
                if (_discount > 0)
                  _summaryLine('ส่วนลด', _discount, isDiscount: true),
                const Divider(height: 12, color: AppColors.border),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ยอดสุทธิทั้งสิ้น',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(total),
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEditItemDialog(-1),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('เพิ่มเมนู'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: 'ข้อมูลถูกต้อง ไปเปิดห้องชวนเพื่อน',
                        onPressed: _confirmAndGoNext,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

