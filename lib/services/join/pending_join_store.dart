import 'package:shared_preferences/shared_preferences.dart';

class PendingJoinStore {
  static const _key = 'pending_join_room_id';

  const PendingJoinStore();

  Future<void> save(String roomId) async {
    await SharedPreferencesAsync().setString(_key, roomId);
  }

  Future<String?> read() async {
    final roomId = await SharedPreferencesAsync().getString(_key);
    return roomId?.trim().isEmpty == true ? null : roomId;
  }

  Future<void> clear() async {
    await SharedPreferencesAsync().remove(_key);
  }
}
