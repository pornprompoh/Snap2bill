import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';
import '../widgets/custom_button.dart';

class ReviewScreen extends StatefulWidget {
  final Map<String, dynamic> receiptData;

  const ReviewScreen({super.key, required this.receiptData});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late String _shopName;
  late double _vat;
  late double _sc;
  late double _discount;

  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _shopName =
        widget.receiptData['shop_name']?.toString() ?? 'ไม่ระบุชื่อร้าน';
    _vat =
        double.tryParse(widget.receiptData['vat_amount']?.toString() ?? '0') ??
        0.0;
    _sc =
        double.tryParse(
          widget.receiptData['service_charge']?.toString() ?? '0',
        ) ??
        0.0;
    _discount =
        double.tryParse(widget.receiptData['discount']?.toString() ?? '0') ??
        0.0;

    final aiItems = widget.receiptData['items'] as List<dynamic>? ?? [];
    _items = aiItems.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  double _calculateTotal() {
    return _calculateSubtotal() + _vat + _sc - _discount;
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

  // 🚀 โชว์ Pop-up สำหรับแก้ข้อมูลส่วนหัว (ร้าน, VAT, SC)
  Future<void> _showEditHeaderDialog() async {
    final shopCtrl = TextEditingController(text: _shopName);
    final scCtrl = TextEditingController(text: _sc.toString());
    final vatCtrl = TextEditingController(text: _vat.toString());
    final discCtrl = TextEditingController(text: _discount.toString());

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขข้อมูลร้านค้า'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: shopCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อร้านค้า'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: scCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Service Charge'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: vatCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'VAT'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: discCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ส่วนลด'),
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
                _shopName = shopCtrl.text;
                _sc = double.tryParse(scCtrl.text) ?? 0.0;
                _vat = double.tryParse(vatCtrl.text) ?? 0.0;
                _discount = double.tryParse(discCtrl.text) ?? 0.0;
              });
              Navigator.pop(context);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // 🚀 โชว์ Pop-up สำหรับแก้รายการอาหารแต่ละชิ้น
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
        title: Text(isNew ? 'เพิ่มรายการใหม่' : 'แก้ไขรายการ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อรายการ'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'จำนวน'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'ราคา/ชิ้น'),
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
              final updatedItem = {
                'item_name': nameCtrl.text,
                'qty': int.tryParse(qtyCtrl.text) ?? 1,
                'unit_price': double.tryParse(priceCtrl.text) ?? 0.0,
              };
              setState(() {
                if (isNew) {
                  _items.add(updatedItem);
                } else {
                  _items[index] = updatedItem;
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
    final updatedReceiptData = Map<String, dynamic>.from(widget.receiptData);
    updatedReceiptData['shop_name'] = _shopName;
    updatedReceiptData['vat_amount'] = _vat;
    updatedReceiptData['service_charge'] = _sc;
    updatedReceiptData['discount'] = _discount;

    double subTotal = 0;
    for (var item in _items) {
      final qty = int.tryParse(item['qty'].toString()) ?? 1;
      final price = double.tryParse(item['unit_price'].toString()) ?? 0.0;
      item['total_price'] = qty * price;
      subTotal += item['total_price'];
    }

    updatedReceiptData['sub_total'] = subTotal;
    updatedReceiptData['total_amount'] = _calculateTotal();
    updatedReceiptData['items'] = _items;

    Navigator.pushNamed(
      context,
      AppRoutes.lobby,
      arguments: updatedReceiptData,
    );
  }

  Widget _summaryLine(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '${isDiscount ? '- ' : ''}${AppFormatters.formatCurrency(amount)}',
            style: AppTextStyles.body.copyWith(
              color: isDiscount ? AppColors.error : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subTotal = _calculateSubtotal();

    return Scaffold(
      appBar: AppBar(title: const Text('ตรวจสอบบิล')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: 3),
                      Text('ข้อมูลร้านและภาษี', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'แก้ไขข้อมูลร้านและภาษี',
                  onPressed: _showEditHeaderDialog,
                  icon: const Icon(Icons.edit_outlined),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.receipt_long_outlined,
                            size: 44,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'ยังไม่มีรายการอาหาร',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'เพิ่มรายการก่อนสร้างห้องหารบิล',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final qty = int.tryParse(item['qty'].toString()) ?? 1;
                      final price =
                          double.tryParse(item['unit_price'].toString()) ?? 0.0;

                      return Card(
                        color: AppColors.cardBackground,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['item_name'].toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$qty x ${AppFormatters.formatCurrency(price)}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppFormatters.formatCurrency(qty * price),
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'แก้ไขจำนวนและราคา',
                                        visualDensity: VisualDensity.compact,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 38,
                                              height: 38,
                                            ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 19,
                                        ),
                                        color: AppColors.primary,
                                        onPressed: () =>
                                            _showEditItemDialog(index),
                                      ),
                                      IconButton(
                                        tooltip: 'ลบรายการ',
                                        visualDensity: VisualDensity.compact,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                              width: 38,
                                              height: 38,
                                            ),
                                        style: IconButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          backgroundColor: AppColors.error
                                              .withValues(alpha: 0.08),
                                        ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 19,
                                        ),
                                        onPressed: () => setState(
                                          () => _items.removeAt(index),
                                        ),
                                      ),
                                    ],
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.border)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'สรุปยอด',
                        style: AppTextStyles.title.copyWith(fontSize: 16),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showEditHeaderDialog,
                      icon: const Icon(Icons.tune, size: 18),
                      label: const Text('แก้ภาษี'),
                    ),
                  ],
                ),
                _summaryLine('ยอดสินค้า', subTotal),
                if (_sc > 0) _summaryLine('Service Charge', _sc),
                if (_vat > 0) _summaryLine('VAT', _vat),
                if (_discount > 0)
                  _summaryLine('ส่วนลด', _discount, isDiscount: true),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Divider(height: 1, color: AppColors.border),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ยอดสุทธิ',
                        style: AppTextStyles.title.copyWith(fontSize: 17),
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(_calculateTotal()),
                      style: AppTextStyles.title.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showEditItemDialog(-1),
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มรายการ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomButton(
                        text: 'ไปตั้งห้องหารบิล',
                        onPressed: _confirmAndGoNext,
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
