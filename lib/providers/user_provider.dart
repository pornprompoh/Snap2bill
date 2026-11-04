import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../data/repositories/supabase_user_repository.dart';
import '../data/repositories/local_bill_repository.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/usecases/user_use_cases.dart';
import '../services/offline/offline_service.dart';
import '../services/storage/local_receipt_storage.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository;
  late final LocalBillRepository _localRepository = LocalBillRepository();
  late final OfflineQueue _offlineQueue = OfflineQueue();
  late final GetMyProfile _getMyProfile;
  late final UpdateUserProfile _updateUserProfile;
  late final GetMyFriends _getMyFriends;
  late final AddFriend _addFriend;
  OfflineService? _offlineService;

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

  void setOfflineService(OfflineService offlineService) {
    _offlineService = offlineService;
  }

  // ดึงข้อมูลโปรไฟล์ (เรียกใช้ตอนเข้าแอป)
  Future<void> loadProfile() async {
    await fetchCurrentUserProfile();
  }

  Future<UserModel?> fetchCurrentUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final cached = await _localRepository.getCachedProfile(userId);
        if (cached != null) {
          _currentUser = UserModel.fromJson(cached);
          _isLoading = false;
          notifyListeners();
          if (_offlineService?.isOffline != true) {
            _syncCurrentProfile();
          }
          return _currentUser;
        }
      } catch (error, stackTrace) {
        debugPrint('Failed to read cached profile: $error\n$stackTrace');
      }
    }

    if (_offlineService?.isOffline == true) {
      _isLoading = false;
      notifyListeners();
      return _currentUser;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _getMyProfile();
      if (_currentUser != null) {
        _currentUser = await _cacheProfile(_currentUser!);
      }
      return _currentUser;
    } catch (error, stackTrace) {
      debugPrint('Failed to load profile: $error\n$stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncCurrentProfile() async {
    try {
      final profile = await _getMyProfile();
      if (profile == null) return;
      _currentUser = await _cacheProfile(profile);
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Background profile sync failed: $error\n$stackTrace');
    }
  }

  Future<UserModel> _cacheProfile(UserModel profile) async {
    var cachedProfile = profile;
    final avatarUrl = profile.avatarUrl;
    final avatarUri = Uri.tryParse(avatarUrl ?? '');
    if (profile.localAvatarPath == null &&
        avatarUri != null &&
        (avatarUri.scheme == 'http' || avatarUri.scheme == 'https') &&
        avatarUri.host.isNotEmpty) {
      try {
        final bytes = await NetworkAssetBundle(
          avatarUri,
        ).load(avatarUrl!).timeout(const Duration(seconds: 5));
        final path = await saveLocalReceipt(
          bytes.buffer.asUint8List(),
          'avatar-${profile.id}',
        );
        cachedProfile = profile.copyWith(localAvatarPath: path);
      } catch (error, stackTrace) {
        debugPrint('Failed to cache profile avatar: $error\n$stackTrace');
      }
    }
    await _localRepository.cacheProfile(cachedProfile.toMap());
    return cachedProfile;
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
      if (trimmedBankAccountNumber != null &&
          trimmedBankAccountNumber.isNotEmpty) {
        paymentInfo['bank_name'] = trimmedBankName ?? 'ธนาคารทั่วไป';
        paymentInfo['bank_account_number'] = trimmedBankAccountNumber;
        paymentInfo['bank_account_name'] = trimmedBankAccountName ?? name;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw StateError('ผู้ใช้ยังไม่ได้ล็อกอิน');
      final updatedPaymentInfo = paymentInfo.isEmpty ? null : paymentInfo;
      final cachedProfile = _currentUser?.toMap() ?? {'id': userId};
      cachedProfile
        ..['display_name'] = name
        ..['payment_info'] = updatedPaymentInfo;
      await _localRepository.cacheProfile(cachedProfile);
      _currentUser = UserModel.fromJson(cachedProfile);

      if (_offlineService?.isOffline == true) {
        await _offlineQueue.enqueue(
          type: 'update_profile',
          payload: {
            'id': userId,
            'data': {
              'display_name': name,
              'payment_info': updatedPaymentInfo,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          },
        );
      } else {
        try {
          _currentUser = await _updateUserProfile(
            displayName: name,
            paymentInfo: updatedPaymentInfo,
          );
          await _localRepository.cacheProfile(_currentUser!.toMap());
        } catch (error) {
          if (!OfflineService.isLikelyNetworkError(error)) rethrow;
          await _offlineQueue.enqueue(
            type: 'update_profile',
            payload: {
              'id': userId,
              'data': {
                'display_name': name,
                'payment_info': updatedPaymentInfo,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              },
            },
          );
        }
      }
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
