import 'package:flutter/material.dart';

class AppColors {
  // 🌸 The 4 Signature Theme Colors (พาเลตต์หลัก 4 สีละมุนตามสั่ง)
  static const Color blossomPink = Color(
    0xFFFFCED8,
  ); // #FFCED8 ชมพูดอกซากุระละมุน
  static const Color blushPink = Color(0xFFFFDDDD); // #FFDDDD ชมพูบลัชพาสเทล
  static const Color warmCream = Color(0xFFFFF4DE); // #FFF4DE ครีมวานิลลาอบอุ่น
  static const Color butterPeach = Color(0xFFFFE8C4); // #FFE8C4 พีชเนยละมุน

  // Brand Primary & Accents (คุมโทนให้เข้ากับ FFCED8 และตัวหนังสือคมชัดอ่านง่าย)
  static const Color primary = Color(
    0xFFD95D77,
  ); // โทน Rose Berry ที่ดึงจาก FFCED8 อ่านง่าย ไม่แสบตา
  static const Color primaryDark = Color(0xFFBD4560);
  static const Color primaryLight = Color(0xFFFFCED8); // #FFCED8
  static const Color secondary = Color(0xFFFFDDDD); // #FFDDDD
  static const Color accent = Color(0xFFFFE8C4); // #FFE8C4

  // Neutral Background & Surface
  static const Color background = Color(
    0xFFFFFBF7,
  ); // รองพื้นครีมละมุน สบายตา อิงจาก #FFF4DE
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFF2E3E3); // เส้นขอบสีพาสเทลอ่อน

  // Typography (สีตัวหนังสือโทนอบอุ่น อ่านง่าย สบายตา)
  static const Color textPrimary = Color(
    0xFF2E2427,
  ); // น้ำตาลเอสเปรสโซเข้ม ไม่ดำกระด้าง
  static const Color textSecondary = Color(0xFF7A6E71);
  static const Color textMuted = Color(0xFFA69B9E);

  // Semantics & Status (คงสีแดงและเขียวตามหลักสากล UX)
  static const Color success = Color(
    0xFF10B981,
  ); // เขียวมิ้นต์ (จ่ายแล้ว/สำเร็จ)
  static const Color successLight = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // ส้มอำพัน (รอชำระ)
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444); // แดง (ลบ/แจ้งเตือนข้อผิดพลาด)
  static const Color errorLight = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF8B5CF6); // ม่วงลาเวนเดอร์พาสเทล
  static const Color infoLight = Color(0xFFF5F3FF);
  static const Color lineGreen = Color(0xFF06C755); // สีเขียวแอป LINE

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF161314);
  static const Color darkSurface = Color(0xFF201B1D);
  static const Color darkCardBackground = Color(0xFF282225);
  static const Color darkBorder = Color(0xFF382F33);
  static const Color darkTextPrimary = Color(0xFFF7F2F4);
  static const Color darkTextSecondary = Color(0xFFA89CA0);
}
