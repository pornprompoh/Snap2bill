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
    await fetchCurrentUserProfile();
  }

  Future<UserModel?> fetchCurrentUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _dbService.getMyProfile();
      return _currentUser;
    } catch (error, stackTrace) {
      debugPrint('Failed to load profile: $error\n$stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveProfile({
    required String name,
    String? promptPayNumber,
    String? promptPayType,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final trimmedPromptPayNumber = promptPayNumber?.trim();
      final paymentInfo = trimmedPromptPayNumber == null || trimmedPromptPayNumber.isEmpty
          ? null
          : {
              'type': promptPayType,
              'number': trimmedPromptPayNumber,
            };

      _currentUser = await _dbService.updateUserProfile(
        displayName: name,
        paymentInfo: paymentInfo,
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to save profile: $error\n$stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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