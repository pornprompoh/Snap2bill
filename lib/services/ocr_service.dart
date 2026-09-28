import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OcrService {
  static const String _primaryModelName = 'gemini-3.5-flash-lite';
  static const String _fallbackModelName = 'gemini-3.1-flash-lite';

  Future<Map<String, dynamic>?> processReceipt(File imageFile) async {
    try {
      // ดึง API Key จากไฟล์ .env
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('ไม่พบ GEMINI_API_KEY ในไฟล์ .env');
      }

      final imageBytes = await imageFile.readAsBytes();

      // 🚀 ปรับ Prompt ใหม่ให้ AI คาย Qty และแยก VAT ออกจาก items
      final prompt = TextPart('''
กรุณาอ่านข้อมูลใบเสร็จนี้และแปลงเป็น JSON format อย่างเคร่งครัด โดยใช้โครงสร้างดังนี้:
{
  "shop_name": "ชื่อร้าน",
  "sub_total": ยอดรวมเฉพาะค่าอาหาร/สินค้าก่อนรวม VAT (number),
  "vat_amount": ภาษีมูลค่าเพิ่ม ถ้าไม่มีให้เป็น 0 (number),
  "service_charge": เซอร์วิสชาร์จ ถ้าไม่มีให้เป็น 0 (number),
  "discount": ส่วนลด ถ้าไม่มีให้เป็น 0 (number),
  "total_amount": ยอดเงินสุทธิที่ต้องจ่ายทั้งหมด (number),
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
1. ในอาร์เรย์ "items" ห้ามใส่รายการที่เป็น VAT, Service Charge, ส่วนลด, เงินทอน หรือ ยอดรวมเด็ดขาด ให้ใส่เฉพาะสินค้าที่จับต้องได้เท่านั้น
2. ถ้าเมนูไหนไม่ได้ระบุจำนวนชัดเจน ให้ถือว่า qty = 1
3. ส่งกลับมาเฉพาะ JSON text เท่านั้น ห้ามมีคำอธิบายอื่น และห้ามมี markdown ```json ครอบ
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

      return jsonDecode(cleanText) as Map<String, dynamic>;
    } catch (error, stackTrace) {
      debugPrint('OCR Error: $error');
      Error.throwWithStackTrace(error, stackTrace);
    }
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
