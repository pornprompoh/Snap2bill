import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart'; // เช็ก path ให้ตรงกับโฟลเดอร์ของคุณนะครับ

void main() async {
  // บังคับให้ Flutter เตรียมความพร้อมก่อนรันแอป
  WidgetsFlutterBinding.ensureInitialized();

  // ใส่ URL และ Anon Key ของ Supabase โปรเจกต์คุณตรงนี้
  await Supabase.initialize(
    url: 'https://nuwrxianosqkaeygnici.supabase.co',
    publishableKey: 'sb_publishable_sqC4-hhueVkPnw0sCFrNPA_GKYZ7PoQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap2Bill',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // ตั้งให้เปิดแอปมาวิ่งไปที่หน้า LoginScreen เสมอ
      home: const LoginScreen(), 
    );
  }
}