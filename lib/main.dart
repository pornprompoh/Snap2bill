import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // [แก้ไข] 1. เพิ่ม import สำหรับอ่านไฟล์ .env
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth/login_screen.dart'; 

// [แก้ไข] 2. เติม Future<void> หน้า main เพื่อให้การใช้ await ทำงานได้อย่างสมบูรณ์
Future<void> main() async { 
  WidgetsFlutterBinding.ensureInitialized();

  // [แก้ไข] 3. สั่งโหลดไฟล์ .env ก่อนที่จะเรียกใช้งาน API ใดๆ
  await dotenv.load(fileName: ".env");

  // [แก้ไข] 4. เปลี่ยนมาดึงค่าจากตัวแปรใน .env และเปลี่ยน publishableKey เป็น anonKey ให้ตรงกับคำสั่งของ Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
      home: const LoginScreen(), 
    );
  }
}