import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/contact_model.dart';
import '../services/firebase_db_service.dart';

class ContactProvider extends ChangeNotifier {
  final FirebaseDbService _dbService;
  final FirebaseAuth _auth;

  List<ContactModel> _contacts = [];
  bool _isLoading = false;
  String? _error;

  ContactProvider({FirebaseDbService? dbService, FirebaseAuth? auth})
    : _dbService = dbService ?? FirebaseDbService(),
      _auth = auth ?? FirebaseAuth.instance;

  List<ContactModel> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadContacts([String? requestedUserId]) async {
    final userId = requestedUserId ?? _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      _contacts = [];
      _error = 'กรุณาล็อกอินเพื่อดูรายชื่อเพื่อนที่บันทึกไว้';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _dbService.getContacts(userId);
      _contacts = rows
          .map(
            (row) => ContactModel.fromJson({
              ...row,
              'user_id': row['user_id'] ?? row['userId'] ?? userId,
              'created_at':
                  row['created_at'] ??
                  row['createdAt'] ??
                  DateTime.now().toIso8601String(),
            }),
          )
          .toList();
    } catch (error, stackTrace) {
      debugPrint('Failed to load saved contacts: $error\n$stackTrace');
      _error = 'โหลดรายชื่อเพื่อนไม่สำเร็จ: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveContactIfNotExists(String name, [String? note]) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw StateError('กรุณาล็อกอินก่อนบันทึกรายชื่อเพื่อน');
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'ชื่อเพื่อนต้องไม่เป็นค่าว่าง');
    }

    final existingRows = await _dbService.getContacts(userId);
    final normalizedName = trimmedName.toLowerCase();
    if (existingRows.any(
      (row) => row['name']?.toString().trim().toLowerCase() == normalizedName,
    )) {
      return;
    }

    final contactId = await _dbService.saveContact({
      'userId': userId,
      'name': trimmedName,
      if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'created_at': FieldValue.serverTimestamp(),
    });
    final contact = ContactModel(
      id: contactId,
      userId: userId,
      name: trimmedName,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      createdAt: DateTime.now(),
    );
    _contacts = [..._contacts, contact]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _error = null;
    notifyListeners();
  }

  Future<void> deleteContact(String contactId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw StateError('กรุณาล็อกอินก่อนลบรายชื่อเพื่อน');
    await _dbService.deleteContact(contactId, userId: userId);
    _contacts = _contacts.where((contact) => contact.id != contactId).toList();
    notifyListeners();
  }
}
