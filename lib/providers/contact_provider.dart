import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/contact_model.dart';

class ContactProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<ContactModel> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<ContactModel> get contacts => List.unmodifiable(_contacts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadContacts() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _contacts = [];
      _error = 'กรุณาล็อกอินเพื่อดูรายชื่อเพื่อนที่บันทึกไว้';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _supabase
          .from('saved_contacts')
          .select()
          .eq('user_id', userId)
          .order('name');
      _contacts = rows
          .map((row) => ContactModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } catch (error) {
      _error = 'โหลดรายชื่อเพื่อนไม่สำเร็จ: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveContactIfNotExists(String name) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('กรุณาล็อกอินก่อนบันทึกรายชื่อเพื่อน');
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'ชื่อเพื่อนต้องไม่เป็นค่าว่าง');
    }

    final existingRows = await _supabase
        .from('saved_contacts')
        .select('id, name, user_id, note, created_at')
        .eq('user_id', userId);
    final normalizedName = trimmedName.toLowerCase();
    if (existingRows.any(
      (row) => row['name']?.toString().trim().toLowerCase() == normalizedName,
    )) {
      return;
    }

    final row = await _supabase
        .from('saved_contacts')
        .insert({'user_id': userId, 'name': trimmedName})
        .select()
        .single();
    final contact = ContactModel.fromJson(Map<String, dynamic>.from(row));
    _contacts = [..._contacts, contact]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _error = null;
    notifyListeners();
  }

  Future<void> deleteContact(String id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw StateError('กรุณาล็อกอินก่อนลบรายชื่อเพื่อน');
    final deletedRows = await _supabase
        .from('saved_contacts')
        .delete()
        .eq('id', id)
        .eq('user_id', userId)
        .select('id');
    if (deletedRows.isEmpty) {
      throw StateError('ไม่พบรายชื่อเพื่อนที่ต้องการลบ');
    }
    _contacts = _contacts.where((contact) => contact.id != id).toList();
    notifyListeners();
  }

}
