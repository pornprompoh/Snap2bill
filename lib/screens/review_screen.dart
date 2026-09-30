import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../utils/formatters.dart';
import '../widgets/custom_button.dart';

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
    double subTotal = 0;
    for (var item in _items) {
      final qty = int.tryParse(item['qty'].toString()) ?? 1;
      final price = double.tryParse(item['unit_price'].toString()) ?? 0.0;
      subTotal += (qty * price);
    }
    return subTotal + _vat + _sc - _discount;
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
      arguments: {
        'receiptData': updatedReceiptData,
        'receiptImageBytes': widget.receiptImageBytes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตรวจสอบบิล')),
      body: Column(
        children: [
          // 1. ส่วนหัวบิล (กดแก้ไขได้)
          GestureDetector(
            onTap: _showEditHeaderDialog,
            child: Container(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.4),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ร้าน: $_shopName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SC: ${AppFormatters.formatCurrency(_sc)} | VAT: ${AppFormatters.formatCurrency(_vat)} | ลด: ${AppFormatters.formatCurrency(_discount)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, color: Colors.blue, size: 20),
                ],
              ),
            ),
          ),

          // 2. รายการอาหาร (กดแก้ไข/ลบได้)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final qty = int.tryParse(item['qty'].toString()) ?? 1;
                final price =
                    double.tryParse(item['unit_price'].toString()) ?? 0.0;

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    title: Text(
                      item['item_name'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$qty x ${AppFormatters.formatCurrency(price)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppFormatters.formatCurrency(qty * price),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () => _showEditItemDialog(index),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () =>
                              setState(() => _items.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. ปุ่มเพิ่มรายการ และยืนยัน
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditItemDialog(-1),
                      icon: const Icon(Icons.add),
                      label: const Text('เพิ่มรายการ'),
                    ),
                    Text(
                      'ยอดสุทธิ: ${AppFormatters.formatCurrency(_calculateTotal())}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'ข้อมูลถูกต้อง ไปตั้งห้องหารบิล',
                  onPressed: _confirmAndGoNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
