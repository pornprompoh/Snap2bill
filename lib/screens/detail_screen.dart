import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  // ในอนาคตจะรับ ID ของบิลที่ส่งมาจากหน้า Home
  // final String billId; 
  // const DetailScreen({super.key, required this.billId});
  
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดบิลย้อนหลัง')),
      body: const Center(
        child: Text(
          'กำลังพัฒนาระบบดูประวัติย้อนหลัง...',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}