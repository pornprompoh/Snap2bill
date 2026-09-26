import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class OcrService {
  Future<Map<String, dynamic>?> processReceipt(File imageFile) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) throw 'ไม่พบคีย์ GEMINI_API_KEY ในไฟล์ .env';

    // กลับมาใช้แพ็กเกจเดิมที่คุ้นเคย และใช้โมเดล flash ที่อ่านรูปได้เร็ว
    final model = GenerativeModel(
      model: 'gemini-3.8-flash', 
      apiKey: apiKey,
      // [แก้ไข] เอา generationConfig (responseMimeType) ออก เพื่อไม่ให้เกิด Error unsupported
    );

    final imageBytes = await imageFile.readAsBytes();
    
    final prompt = TextPart('''
โปรดอ่านข้อมูลจากใบเสร็จนี้และแปลงเป็นรูปแบบ JSON ให้ตรงกับโครงสร้างต่อไปนี้อย่างเคร่งครัด:
{
  "shop_name": "ชื่อร้านอาหาร (ถ้าไม่มีให้คืนค่า null)",
  "receipt_date": "วันที่บนใบเสร็จ รูปแบบ YYYY-MM-DD (ถ้าไม่มีให้คืนค่า null)",
  "sub_total": ยอดรวมอาหารก่อนภาษีและ service charge (ตัวเลขทศนิยม),
  "vat_amount": ยอด VAT 7% หรือภาษี (ตัวเลขทศนิยม),
  "service_charge": ยอด Service Charge (ตัวเลขทศนิยม),
  "total_amount": ยอดสุทธิรวมทั้งหมด (ตัวเลขทศนิยม),
  "items": [
    {
      "item_name": "ชื่อเมนูอาหาร",
      "price": ราคาต่อหน่วย (ตัวเลขทศนิยม),
      "quantity": จำนวนที่สั่ง (ตัวเลขจำนวนเต็ม),
      "total_price": ราคารวมของเมนูนี้ (ตัวเลขทศนิยม)
    }
  ]
}
ส่งกลับมาเฉพาะก้อน JSON เท่านั้น ห้ามพิมพ์ข้อความอธิบายหรือเครื่องหมาย markdown ใดๆ เพิ่มเติม
''');

    final imagePart = DataPart('image/jpeg', imageBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      var text = response.text;
      if (text != null && text.isNotEmpty) {
        // [แก้ไข] เพิ่มตัวช่วยทำความสะอาดข้อความ เผื่อ AI แอบส่งสัญลักษณ์ ```json มาคล่อม
        text = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(text);
      }
      return null;
    } catch (e) {
      throw 'เกิดข้อผิดพลาดในการประมวลผลรูปภาพ: $e';
    }
  }
}