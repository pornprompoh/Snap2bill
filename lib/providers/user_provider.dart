import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/supabase_db_service.dart';

class UserProvider with ChangeNotifier {
  final SupabaseDbService _dbService = SupabaseDbService();

  UserModel? _currentUser;
  List<FriendModel> _friends = [];
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  List<FriendModel> get friends => _friends;
  bool get isLoading => _isLoading;

  // ดึงข้อมูลโปรไฟล์ (เรียกใช้ตอนเข้าแอป)
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _dbService.getMyProfile();

    _isLoading = false;
    notifyListeners();
  }

  // ดึงรายชื่อเพื่อนมาแสดง
  Future<void> loadFriends() async {
    _isLoading = true;
    notifyListeners();

    _friends = await _dbService.getMyFriends();

    _isLoading = false;
    notifyListeners();
  }

  // เพิ่มเพื่อนใหม่ แล้วสั่งให้รีเฟรชหน้าจอ
  Future<void> addFriend(String name) async {
    await _dbService.addFriend(name);
    await loadFriends(); 
  }
}