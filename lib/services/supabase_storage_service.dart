import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final _supabase = Supabase.instance.client;

  // ฟังก์ชันอัปโหลดรูปใบเสร็จ
  Future<String?> uploadReceiptImage(File imageFile, String lobbyId) async {
    try {
      // ดึงนามสกุลไฟล์ (เช่น .jpg, .png)
      final extension = imageFile.path.split('.').last;
      // ตั้งชื่อไฟล์ใหม่ให้ไม่ซ้ำกัน โดยใช้ Timestamp
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
      // กำหนดที่อยู่ไฟล์ (โฟลเดอร์ receipts -> โฟลเดอร์เลขห้อง -> ชื่อไฟล์)
      final filePath = 'receipts/$lobbyId/$fileName';

      // อัปโหลดไฟล์ขึ้น Storage บักเก็ตชื่อ 'receipts'
      await _supabase.storage.from('receipts').upload(filePath, imageFile);

      // ดึง URL แบบ Public เพื่อเอาไปโชว์ในแอป
      final publicUrl = _supabase.storage.from('receipts').getPublicUrl(filePath);
      return publicUrl;
      
    } catch (e) {
      print('เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ: $e');
      return null;
    }
  }
}