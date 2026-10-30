import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_db_service.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuthService _authService;
  final FirebaseDbService _dbService;
  late final StreamSubscription<User?> _authSubscription;

  UserModel? _currentUser;
  List<FriendModel> _friends = [];
  bool _isLoading = false;
  bool _disposed = false;
  String? _error;
  int _profileRequestId = 0;

  UserProvider({FirebaseAuthService? authService, FirebaseDbService? dbService})
    : _authService = authService ?? FirebaseAuthService(),
      _dbService = dbService ?? FirebaseDbService() {
    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthStateChanged,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Firebase auth state stream failed: $error\n$stackTrace');
        _error = 'ตรวจสอบสถานะการเข้าสู่ระบบไม่สำเร็จ';
        _notifyListeners();
      },
    );
    final user = _authService.currentUser;
    if (user != null) _handleAuthStateChanged(user);
  }

  UserModel? get currentUser => _currentUser;
  String? get currentUserId => _authService.currentUserId;
  User? get firebaseUser => _authService.currentUser;
  Stream<User?> get authStateChanges => _authService.authStateChanges;
  List<FriendModel> get friends => List.unmodifiable(_friends);
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _handleAuthStateChanged(User? user) {
    final requestId = ++_profileRequestId;
    _error = null;
    if (user == null) {
      _currentUser = null;
      _friends = [];
      _isLoading = false;
      _notifyListeners();
      return;
    }

    _isLoading = true;
    _currentUser = UserModel(
      id: user.uid,
      displayName: user.displayName,
      email: user.email,
      avatarUrl: user.photoURL,
    );
    _notifyListeners();
    unawaited(_loadProfileForUser(requestId));
  }

  Future<void> _loadProfileForUser(int requestId) async {
    try {
      final profile = await _dbService.getMyProfile();
      if (_disposed || requestId != _profileRequestId) return;
      _currentUser = profile;
    } catch (error, stackTrace) {
      debugPrint('Failed to load Firebase profile: $error\n$stackTrace');
      if (!_disposed && requestId == _profileRequestId) {
        _error = 'โหลดข้อมูลโปรไฟล์ไม่สำเร็จ';
      }
    } finally {
      if (!_disposed && requestId == _profileRequestId) {
        _isLoading = false;
        _notifyListeners();
      }
    }
  }

  Future<void> loadProfile() async {
    await fetchCurrentUserProfile();
  }

  Future<UserModel?> fetchCurrentUserProfile() async {
    if (_authService.currentUser == null) {
      _currentUser = null;
      _notifyListeners();
      return null;
    }
    _isLoading = true;
    _notifyListeners();
    try {
      _currentUser = await _dbService.getMyProfile();
      _error = null;
      return _currentUser;
    } catch (error, stackTrace) {
      debugPrint('Failed to load profile: $error\n$stackTrace');
      _error = 'โหลดข้อมูลโปรไฟล์ไม่สำเร็จ';
      rethrow;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<FirebaseAuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    _error = result.errorMessage;
    _notifyListeners();
    return result;
  }

  Future<FirebaseAuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final result = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );
    _error = result.errorMessage;
    _notifyListeners();
    return result;
  }

  Future<FirebaseAuthResult> signInWithFacebook() async {
    final result = await _authService.signInWithFacebook();
    _error = result.errorMessage;
    _notifyListeners();
    return result;
  }

  Future<UserCredential> signInWithGoogle() async {
    try {
      final credential = await _authService.signInWithGoogle();
      _error = null;
      _notifyListeners();
      return credential;
    } catch (error) {
      _error = error.toString();
      _notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      _friends = [];
      _error = null;
      _notifyListeners();
    } catch (error) {
      _error = 'ออกจากระบบไม่สำเร็จ: $error';
      _notifyListeners();
      rethrow;
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
    _notifyListeners();

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

      _currentUser = await _dbService.updateUserProfile(
        displayName: name,
        paymentInfo: paymentInfo.isEmpty ? null : paymentInfo,
      );
      _error = null;
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to save profile: $error\n$stackTrace');
      _error = 'บันทึกโปรไฟล์ไม่สำเร็จ';
      return false;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> loadFriends() async {
    _isLoading = true;
    _notifyListeners();
    try {
      _friends = await _dbService.getMyFriends();
      _error = null;
    } catch (error, stackTrace) {
      debugPrint('Failed to load friends: $error\n$stackTrace');
      _error = 'โหลดรายชื่อเพื่อนไม่สำเร็จ';
      rethrow;
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<void> addFriend(String name) async {
    await _dbService.addFriend(name);
    await loadFriends();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}
