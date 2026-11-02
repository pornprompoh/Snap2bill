import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OcrService {
  static const String _primaryModelName = 'gemini-3.5-flash-lite';
  static const String _fallbackModelName = 'gemini-3.1-flash-lite';

  Future<Map<String, dynamic>?> processReceipt(Uint8List imageBytes) async {
    try {
      // ดึง API Key จากไฟล์ .env
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('ไม่พบ GEMINI_API_KEY ในไฟล์ .env');
      }

      final prompt = TextPart('''
กรุณาอ่านข้อมูลใบเสร็จนี้และแปลงเป็น JSON format อย่างเคร่งครัด โดยใช้โครงสร้างดังนี้:
{
  "shop_name": "ชื่อร้าน",
  "sub_total": ผลรวมราคาของอาหาร/สินค้าก่อนส่วนเกินและส่วนลด (number),
  "vat_amount": เฉพาะ VAT ที่คิดแยกเพิ่มจากยอดอาหารเท่านั้น (number),
  "is_vat_included": มี VAT รวมอยู่ในราคาอาหารหรือยอดสุทธิแล้วหรือไม่ (boolean),
  "service_charge": เซอร์วิสชาร์จ ถ้าไม่มีให้เป็น 0 (number),
  "discount": ส่วนลด ถ้าไม่มีให้เป็น 0 (number),
  "final_total": ยอดสุทธิท้ายสุดที่ต้องจ่ายจริงตามใบเสร็จ (number),
  "total_amount": ยอดเดียวกับ final_total เพื่อรองรับข้อมูลเดิม (number),
  "items": [
    {
      "item_name": "ชื่อเมนูอาหาร/สินค้า (ตัดตัวเลขจำนวนออกจากชื่อ)",
      "qty": จำนวนชิ้น (integer),
      "unit_price": ราคาต่อหน่วย (number),
      "total_price": ราคารวมของรายการนี้ (number)
    }
  ]
}

กฎเหล็กที่ต้องทำตาม:
1. ในอาร์เรย์ "items" ให้นำเข้าเฉพาะรายการอาหารและเครื่องดื่ม/สินค้าที่มีราคามากกว่า 0 บาท (> 0) เท่านั้น
2. หากตรวจพบรายการที่มีราคา 0 บาท (เช่น ของแถม, สิทธิ์แลกซื้อ, ส่วนลดสมาชิก, บัตรกำนัล, น้ำดื่มฟรี หรือรายการ 0 บาท) ให้ตัดรายการนั้นออกเด็ดขาด ห้ามนำมาใส่ใน "items"
3. ห้ามนำเข้ารายการที่ไม่มีราคา หรือไม่สามารถระบุราคาได้อย่างชัดเจน
4. ห้ามนำรายการหัวข้อ, หมวดหมู่, ข้อความกำกับ หรือข้อความอื่น ๆ ที่ไม่ใช่สินค้าที่มีราคามาแสดงเป็นเมนู
5. ห้ามใส่รายการที่เป็น VAT, Service Charge, ส่วนลด, เงินทอน หรือ ยอดรวมใน "items"
6. ถ้าเมนูไหนไม่ได้ระบุจำนวนชัดเจน ให้ถือว่า qty = 1
7. ใช้ยอดสุทธิท้ายสุดที่พิมพ์บนใบเสร็จเป็น final_total เสมอ ห้ามคำนวณ total ขึ้นใหม่จากการบวก VAT ซ้ำ
8. ถ้าใบเสร็จระบุ "VAT INCLUDED", "รวมภาษีมูลค่าเพิ่มแล้ว" หรือข้อความความหมายเดียวกัน ให้ตั้ง is_vat_included = true และ vat_amount = 0
9. ถ้าไม่มีข้อความ VAT included แต่ sub_total + service_charge เท่ากับ final_total ให้ถือว่า VAT รวมอยู่แล้ว ตั้ง is_vat_included = true และ vat_amount = 0
10. นับเฉพาะ VAT ที่แสดงเป็นค่าใช้จ่ายแยกเพิ่มจากยอดอาหารเป็น vat_amount บวกเพิ่มเท่านั้น
11. ก่อนส่ง JSON ให้ตรวจสมการ: ผลรวม total_price ของรายการอาหาร + service_charge + vat_amount - discount ต้องเท่ากับ final_total (ยอมรับส่วนต่างจากการปัดเศษไม่เกิน 0.05) หากเป็น VAT included ให้ใช้ vat_amount = 0
12. ส่งกลับมาเฉพาะ JSON text เท่านั้น ห้ามมีคำอธิบายอื่น และห้ามมี markdown ```json ครอบ
''');

      final imagePart = DataPart('image/jpeg', imageBytes);

      final content = [
        Content.multi([prompt, imagePart]),
      ];
      final response = await _generateWithFallback(
        apiKey: apiKey,
        content: content,
      );

      final text = response.text ?? '';
      // ทำความสะอาดข้อความ เผื่อ AI เผลอส่ง markdown ติดมา
      final cleanText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final receipt = jsonDecode(cleanText) as Map<String, dynamic>;
      return _validateAndNormalizeReceipt(receipt);
    } catch (error, stackTrace) {
      debugPrint('OCR Error: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Map<String, dynamic> _validateAndNormalizeReceipt(
    Map<String, dynamic> receipt,
  ) {
    return validateAndNormalizeReceipt(receipt);
  }

  /// ตรวจสอบและกรองข้อมูลใบเสร็จจาก OCR:
  /// - นำเข้ารายการเฉพาะเมนูอาหารและเครื่องดื่มที่มีราคามากกว่า 0 บาท (> 0) เท่านั้น
  /// - ตัดรายการที่มีราคา 0 บาท (ของแถม, สิทธิ์แลกซื้อ, ส่วนลด 0 บาท) ออกเด็ดขาด
  /// - ตัดรายการที่ไม่มีราคา หรือไม่สามารถระบุราคาได้ชัดเจนออก
  /// - ตัดรายการหัวข้อ หมวดหมู่ ข้อความกำกับออก
  static Map<String, dynamic> validateAndNormalizeReceipt(
    Map<String, dynamic> receipt,
  ) {
    double numberValue(Object? value) =>
        double.tryParse(value?.toString() ?? '') ?? 0;

    var isVatIncluded = receipt['is_vat_included'] == true;
    final declaredVatAmount = numberValue(receipt['vat_amount']);
    final serviceCharge = numberValue(receipt['service_charge']);
    final discount = numberValue(receipt['discount']);
    final rawItems = receipt['items'];
    if (rawItems is! List) {
      throw const FormatException('OCR response has no valid items list.');
    }

    // กรองเฉพาะรายการอาหารและเครื่องดื่มที่มีราคามากกว่า 0 บาทเท่านั้น
    final validItems = <Map<String, dynamic>>[];
    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final itemName =
          (item['item_name'] ?? item['name'])?.toString().trim() ?? '';
      final unitPrice = numberValue(item['unit_price'] ?? item['price']);
      final qty = int.tryParse(
            (item['qty'] ?? item['quantity'] ?? 1).toString(),
          ) ??
          1;
      final totalPrice = item['total_price'] != null
          ? numberValue(item['total_price'])
          : unitPrice * qty;

      // กฎข้อบังคับ:
      // 1. ชื่อรายการต้องไม่ว่าง
      // 2. ราคาต่อหน่วยและราคารวมต้องมากกว่า 0 บาท (> 0)
      if (itemName.isEmpty) continue;
      if (unitPrice <= 0 || totalPrice <= 0) continue;

      validItems.add({
        ...item,
        'item_name': itemName,
        'name': itemName,
        'qty': qty > 0 ? qty : 1,
        'quantity': qty > 0 ? qty : 1,
        'unit_price': unitPrice,
        'price': unitPrice,
        'total_price': totalPrice,
      });
    }

    if (validItems.isEmpty) {
      throw const FormatException('ไม่พบรายการอาหารที่มีราคามากกว่า 0 บาทในใบเสร็จ');
    }

    final itemTotal = validItems.fold<double>(0, (sum, item) {
      return sum + (item['total_price'] as double);
    });
    final rawFinalTotal = receipt['final_total'] ?? receipt['total_amount'];
    if (rawFinalTotal == null) {
      throw const FormatException('OCR response has no final_total.');
    }
    final finalTotal = numberValue(rawFinalTotal);
    if ((itemTotal + serviceCharge - discount - finalTotal).abs() <= 0.05) {
      isVatIncluded = true;
    }
    final vatAmount = isVatIncluded ? 0.0 : declaredVatAmount;
    final calculatedTotal = itemTotal + serviceCharge + vatAmount - discount;

    if ((calculatedTotal - finalTotal).abs() > 0.05) {
      throw FormatException(
        'Receipt totals do not reconcile: items + service charge + exclusive '
        'VAT - discount = $calculatedTotal, final_total = $finalTotal.',
      );
    }

    return {
      ...receipt,
      'items': validItems,
      'is_vat_included': isVatIncluded,
      'vat_amount': vatAmount,
      'sub_total': itemTotal,
      'final_total': finalTotal,
      'total_amount': finalTotal,
    };
  }

  Future<GenerateContentResponse> _generateWithFallback({
    required String apiKey,
    required List<Content> content,
  }) async {
    try {
      return await _generateWithModel(
        modelName: _primaryModelName,
        apiKey: apiKey,
        content: content,
      );
    } catch (primaryError, primaryStackTrace) {
      if (!_isTransientCapacityError(primaryError)) {
        Error.throwWithStackTrace(primaryError, primaryStackTrace);
      }

      debugPrint(
        'Primary OCR model failed ($primaryError); '
        'retrying immediately with $_fallbackModelName.',
      );

      try {
        return await _generateWithModel(
          modelName: _fallbackModelName,
          apiKey: apiKey,
          content: content,
        );
      } catch (fallbackError, fallbackStackTrace) {
        debugPrint('Fallback OCR model failed: $fallbackError');
        Error.throwWithStackTrace(
          Exception(
            'OCR failed with both models. '
            'Primary: $primaryError; fallback: $fallbackError',
          ),
          fallbackStackTrace,
        );
      }
    }
  }

  Future<GenerateContentResponse> _generateWithModel({
    required String modelName,
    required String apiKey,
    required List<Content> content,
  }) {
    final model = GenerativeModel(model: modelName, apiKey: apiKey);
    return model.generateContent(content);
  }

  bool _isTransientCapacityError(Object error) {
    return RegExp(r'\[(429|503)\]').hasMatch(error.toString());
  }
}
