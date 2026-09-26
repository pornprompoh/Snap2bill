import 'package:flutter/material.dart';
import '../models/bill_model.dart';
import '../services/supabase_db_service.dart';

class BillProvider with ChangeNotifier {
  final SupabaseDbService _dbService = SupabaseDbService();

  List<BillModel> _bills = [];
  bool _isLoading = false;

  List<BillModel> get bills => _bills;
  bool get isLoading => _isLoading;

  // ดึงประวัติบิลของเรามาแสดง
  Future<void> loadMyBills() async {
    _isLoading = true;
    notifyListeners();

    _bills = await _dbService.getMyBills();

    _isLoading = false;
    notifyListeners();
  }

  // สร้างบิลใหม่ แล้วยัดใส่บนสุดของลิสต์ให้ผู้ใช้เห็นทันที
  Future<BillModel> createBill(String shopName, double totalAmount) async {
    final newBill = await _dbService.createBill(shopName, totalAmount);
    _bills.insert(0, newBill);
    notifyListeners();
    return newBill;
  }
}