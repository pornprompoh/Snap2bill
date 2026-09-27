import 'package:flutter/material.dart';
import '../routes/app_routes.dart'; // 🚀 นำเข้าระบบนำทาง

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snap2Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // 🚀 ไปหน้าโปรไฟล์
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.friends);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีประวัติการหารบิล\nกดปุ่มด้านล่างเพื่อเริ่มสแกนได้เลย!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      ),
      // 🚀 ปุ่มลอยสำหรับสแกนบิลใหม่
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 🚀 วิ่งไปหน้า ScanScreen เพื่อเริ่มกระบวนการ
          Navigator.pushNamed(context, AppRoutes.scan);
        },
        icon: const Icon(Icons.add_a_photo),
        label: const Text('สแกนบิลใหม่', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}