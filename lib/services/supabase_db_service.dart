import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/bill_model.dart';

class SupabaseDbService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. ดึงข้อมูลโปรไฟล์ของตัวเอง
  Future<UserModel?> getMyProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle(); // ใช้ maybeSingle เพื่อป้องกัน Error กรณีเพิ่งสมัครแล้ว Trigger ยังทำงานไม่เสร็จ
        
    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  // 2. ดึงสมุดรายชื่อเพื่อน (ดึงเฉพาะคนที่ยังไม่ถูกซ่อน/ลบ)
  Future<List<FriendModel>> getMyFriends() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('friends')
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    return response.map((json) => FriendModel.fromJson(json)).toList();
  }

  // 3. เพิ่มเพื่อนใหม่เข้าสมุดรายชื่อ
  Future<void> addFriend(String friendName) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw 'ผู้ใช้ยังไม่ได้ล็อกอิน';

    await _supabase.from('friends').insert({
      'user_id': userId,
      'friend_name': friendName,
    });
  }

  // 4. ดึงประวัติบิลของตัวเอง (เรียงจากล่าสุดไปเก่าสุด)
  Future<List<BillModel>> getMyBills() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('bills')
        .select()
        .eq('owner_id', userId)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    return response.map((json) => BillModel.fromJson(json)).toList();
  }

  // 5. สร้างบิลใหม่เริ่มต้น (สถานะ draft)
  Future<BillModel> createBill(String shopName, double totalAmount) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw 'ผู้ใช้ยังไม่ได้ล็อกอิน';

    final response = await _supabase.from('bills').insert({
      'owner_id': userId,
      'shop_name': shopName,
      'total_amount': totalAmount,
      'status': 'draft',
    }).select().single();

    return BillModel.fromJson(response);
  }
}