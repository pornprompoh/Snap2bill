import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🚀 นำเข้า dotenv
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'providers/user_provider.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 โหลดไฟล์ .env ก่อนเรียกใช้ตัวแปร
  await dotenv.load(fileName: ".env");

  // 🚀 เริ่มต้น Supabase โดยดึงค่าจาก .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!, // ใช้ anonKey สำหรับ Supabase
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snap2Bill',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        useMaterial3: true,
      ),
      // OAuth returns to the app after Supabase has restored the session.
      initialRoute: Supabase.instance.client.auth.currentSession == null
          ? '/'
          : AppRoutes.home,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
