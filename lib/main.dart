import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // จำเป็นต้องเรียกใช้คำสั่งนี้เมื่อมีการตั้งค่าก่อน runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 1. โหลดไฟล์ .env
  await dotenv.load(fileName: ".env");

  // 2. เริ่มต้นเชื่อมต่อ Supabase ด้วยค่าจาก .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
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
      home: const ConnectionTestScreen(),
    );
  }
}

// หน้าจอสำหรับทดสอบการเชื่อมต่อ
class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  String _statusMessage = 'คลิกปุ่มด้านล่างเพื่อทดสอบ';
  Color _statusColor = Colors.grey;
  bool _isLoading = false;

  void _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'กำลังส่งคำขอไปที่ Supabase...';
      _statusColor = Colors.blue;
    });

    try {
      // ดึงตัว client ที่เชื่อมต่อแล้วมาใช้งาน
      final supabase = Supabase.instance.client;

      // ทดสอบการทำงานของ client โดยลองดึง Session ของ Auth
      // (ถ้า URL หรือ Key ผิด บรรทัดนี้จะโยน Error ไปเข้า catch)
      final session = supabase.auth.currentSession;

      setState(() {
        _statusMessage = '✅ เชื่อมต่อ Supabase สำเร็จ!\n(แอปพร้อมคุยกับฐานข้อมูลแล้ว)';
        _statusColor = Colors.green;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ เชื่อมต่อล้มเหลว\nกรุณาตรวจสอบ URL หรือ Key ใน .env อีกครั้ง\n\nError: $e';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทดสอบระบบ Snap2Bill'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isLoading ? Icons.cloud_sync : Icons.cloud_done_outlined,
                size: 100,
                color: _statusColor,
              ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, 
                  color: _statusColor, 
                  fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _testConnection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator() 
                  : const Text('ทดสอบเชื่อมต่อฐานข้อมูล', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}