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

  Future<UserModel> updateUserProfile({
    required String displayName,
    required Map<String, dynamic>? paymentInfo,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw 'ผู้ใช้ยังไม่ได้ล็อกอิน';

    final promptPayType = paymentInfo?['type'];
    if (promptPayType != null &&
        promptPayType != 'phone' &&
        promptPayType != 'id_card') {
      throw ArgumentError.value(promptPayType, 'paymentInfo.type');
    }

    final response = await _supabase
        .from('profiles')
        .update({
          'display_name': displayName,
          'payment_info': paymentInfo,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select()
        .single();

    return UserModel.fromMap(response);
  }

  Future<List<UserModel>> getPastParticipants(String currentUserId) async {
    final participantBillRows = await _supabase
        .from('bill_participants')
        .select('bill_id')
        .eq('profile_id', currentUserId);
    final ownedBillRows = await _supabase
        .from('bills')
        .select('id')
        .eq('owner_id', currentUserId);

    final billIds = <String>{
      for (final row in participantBillRows)
        if (row['bill_id'] != null) row['bill_id'].toString(),
      for (final row in ownedBillRows)
        if (row['id'] != null) row['id'].toString(),
    };
    if (billIds.isEmpty) return [];

    final bills = await _supabase
        .from('bills')
        .select('id, owner_id, created_at, sharers_json')
        .inFilter('id', billIds.toList());
    final participantRows = await _supabase
        .from('bill_participants')
        .select('bill_id, profile_id')
        .inFilter('bill_id', billIds.toList());

    final participantIdsByBill = <String, Set<String>>{};
    for (final row in participantRows) {
      final billId = row['bill_id']?.toString();
      final profileId = row['profile_id']?.toString();
      if (billId == null || profileId == null || profileId.isEmpty) continue;
      participantIdsByBill.putIfAbsent(billId, () => <String>{}).add(profileId);
    }

    final participantCounts = <String, int>{};
    final mostRecentBillByParticipant = <String, DateTime>{};
    for (final bill in bills) {
      final billId = bill['id']?.toString();
      if (billId == null) continue;

      final ownerId = bill['owner_id']?.toString();
      final memberIds = participantIdsByBill[billId] ?? <String>{};
      if (ownerId != null && ownerId.isNotEmpty) memberIds.add(ownerId);
      final rawSharers = bill['sharers_json'];
      if (rawSharers is Map) {
        for (final sharers in rawSharers.values) {
          if (sharers is! Iterable) continue;
          for (final sharer in sharers) {
            if (sharer is Map && sharer['user_id'] != null) {
              memberIds.add(sharer['user_id'].toString());
            }
          }
        }
      }
      if (!memberIds.contains(currentUserId)) continue;

      final billDate =
          DateTime.tryParse(bill['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      for (final participantId in memberIds) {
        if (participantId == currentUserId ||
            participantId.startsWith('guest_')) {
          continue;
        }
        participantCounts.update(
          participantId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
        final previousDate = mostRecentBillByParticipant[participantId];
        if (previousDate == null || billDate.isAfter(previousDate)) {
          mostRecentBillByParticipant[participantId] = billDate;
        }
      }
    }
    if (participantCounts.isEmpty) return [];

    final profileRows = await _supabase
        .from('profiles')
        .select()
        .inFilter('id', participantCounts.keys.toList());
    final profilesById = <String, UserModel>{};
    for (final row in profileRows) {
      final profile = UserModel.fromMap(row);
      profilesById[profile.id] = profile;
    }
    final participants = profilesById.values.toList()
      ..sort((first, second) {
        final countOrder = (participantCounts[second.id] ?? 0).compareTo(
          participantCounts[first.id] ?? 0,
        );
        if (countOrder != 0) return countOrder;
        return (mostRecentBillByParticipant[second.id] ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
            .compareTo(
              mostRecentBillByParticipant[first.id] ??
                  DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            );
      });

    return participants;
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

    final response = await _supabase
        .from('bills')
        .insert({
          'owner_id': userId,
          'shop_name': shopName,
          'total_amount': totalAmount,
          'status': 'draft',
        })
        .select()
        .single();

    return BillModel.fromJson(response);
  }
}
