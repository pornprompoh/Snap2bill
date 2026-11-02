import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../data/repositories/supabase_user_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/usecases/user_use_cases.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository;
  late final GetMyProfile _getMyProfile;
  late final UpdateUserProfile _updateUserProfile;
  late final GetMyFriends _getMyFriends;
  late final AddFriend _addFriend;

  UserModel? _currentUser;
  List<FriendModel> _friends = [];
  bool _isLoading = false;

  UserProvider({UserRepository? userRepository})
      : _userRepository = userRepository ?? SupabaseUserRepository() {
    _getMyProfile = GetMyProfile(_userRepository);
    _updateUserProfile = UpdateUserProfile(_userRepository);
    _getMyFriends = GetMyFriends(_userRepository);
    _addFriend = AddFriend(_userRepository);
  }

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
      _currentUser = await _getMyProfile();
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
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final trimmedPromptPayNumber = promptPayNumber?.trim();
      final trimmedBankAccountNumber = bankAccountNumber?.trim();
      final trimmedBankName = bankName?.trim();
      final trimmedBankAccountName = bankAccountName?.trim();

      final paymentInfo = <String, dynamic>{};
      if (trimmedPromptPayNumber != null && trimmedPromptPayNumber.isNotEmpty) {
        paymentInfo['type'] = promptPayType;
        paymentInfo['number'] = trimmedPromptPayNumber;
      }
      if (trimmedBankAccountNumber != null && trimmedBankAccountNumber.isNotEmpty) {
        paymentInfo['bank_name'] = trimmedBankName ?? 'ธนาคารทั่วไป';
        paymentInfo['bank_account_number'] = trimmedBankAccountNumber;
        paymentInfo['bank_account_name'] = trimmedBankAccountName ?? name;
      }

      _currentUser = await _updateUserProfile(
        displayName: name,
        paymentInfo: paymentInfo.isEmpty ? null : paymentInfo,
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

    _friends = await _getMyFriends();

    _isLoading = false;
    notifyListeners();
  }

  // เพิ่มเพื่อนใหม่ แล้วสั่งให้รีเฟรชหน้าจอ
  Future<void> addFriend(String name) async {
    await _addFriend(name);
    await loadFriends(); 
  }
}