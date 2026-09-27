import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🚀 นำเข้า dotenv
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 โหลดไฟล์ .env ก่อนเรียกใช้ตัวแปร
  await dotenv.load(fileName: ".env");
  
  // 🚀 เริ่มต้น Supabase โดยดึงค่าจาก .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // ใช้ anonKey สำหรับ Supabase
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
      // 🚀 เริ่มที่ Root Route ('/') เพื่อให้ไปหน้า Login
      initialRoute: '/', 
      onGenerateRoute: AppRoutes.generateRoute, 
    );
  }
}