import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../services/data/supabase_db_service.dart';
import '../../theme/app_colors.dart';
import '../common/mascot_state_view.dart';

class FriendHistoryDialog extends StatefulWidget {
  final Future<List<UserModel>> Function()? loadFriends;

  const FriendHistoryDialog({super.key, this.loadFriends});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ปิดรายชื่อเพื่อน',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const FriendHistoryDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
  }

  @override
  State<FriendHistoryDialog> createState() => _FriendHistoryDialogState();
}

class _FriendHistoryDialogState extends State<FriendHistoryDialog> {
  late Future<List<UserModel>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _fetchFriends();
  }

  Future<List<UserModel>> _fetchFriends() {
    if (widget.loadFriends != null) return widget.loadFriends!();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return Future.value(const <UserModel>[]);
    return SupabaseDbService().getPastParticipants(userId);
  }

  void _retry() {
    setState(() => _friendsFuture = _fetchFriends());
  }

  String _displayName(UserModel user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email?.trim().isNotEmpty == true ? user.email! : 'ไม่มีชื่อ';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = MediaQuery.of(context).size.height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 420,
        height: height * 0.68,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : Colors.white,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, color: AppColors.pink),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เพื่อนที่เคยหารบิล',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'จัดการรายชื่อเพื่อน',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/friends');
                    },
                    icon: const Icon(Icons.open_in_new, color: AppColors.pink),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<UserModel>>(
                  future: _friendsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.pink),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: MascotStateView(
                          state: MascotState.error,
                          message: 'โหลดรายชื่อเพื่อนไม่สำเร็จ',
                          detail: 'ลองใหม่อีกครั้งเพื่อดึงข้อมูลบัญชีจริง',
                          onRetry: _retry,
                          size: 110,
                        ),
                      );
                    }

                    final friends = snapshot.data ?? const <UserModel>[];
                    if (friends.isEmpty) {
                      return const Center(
                        child: MascotStateView(
                          state: MascotState.empty,
                          message: 'ยังไม่มีเพื่อนที่เคยหารบิล',
                          detail:
                              'เมื่อคุณหารบิลกับเพื่อน Bunny จะเก็บรายชื่อไว้ให้',
                          size: 130,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: friends.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.lightPink,
                            backgroundImage:
                                friend.avatarUrl?.isNotEmpty == true
                                ? NetworkImage(friend.avatarUrl!)
                                : null,
                            child: friend.avatarUrl?.isNotEmpty == true
                                ? null
                                : const Icon(
                                    Icons.person,
                                    color: AppColors.pink,
                                  ),
                          ),
                          title: Text(
                            _displayName(friend),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: friend.email == null
                              ? null
                              : Text(friend.email!),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
