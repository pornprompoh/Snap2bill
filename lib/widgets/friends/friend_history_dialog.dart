import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../data/repositories/local_bill_repository.dart';
import '../../services/data/supabase_db_service.dart';
import '../../services/offline/offline_service.dart';
import '../../services/storage/local_receipt_storage.dart';
import '../../theme/app_colors.dart';
import '../common/mascot_state_view.dart';
import '../common/cached_avatar.dart';

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

  Future<List<UserModel>> _fetchFriends() async {
    if (widget.loadFriends != null) return widget.loadFriends!();
    final offline = context.read<OfflineService>();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return const <UserModel>[];

    final repository = LocalBillRepository();
    List<UserModel> cachedFriends = [];
    try {
      cachedFriends = await repository.getCachedPastParticipants(userId);
    } catch (error, stackTrace) {
      debugPrint('Failed to load local friends: $error\n$stackTrace');
    }
    if (cachedFriends.isNotEmpty) {
      if (!offline.isOffline) {
        unawaited(
          _syncFriends(repository, userId).catchError((error, stackTrace) {
            debugPrint('Background friend sync failed: $error\n$stackTrace');
            return cachedFriends;
          }),
        );
      }
      return cachedFriends;
    }
    if (offline.isOffline) return cachedFriends;
    return _syncFriends(repository, userId);
  }

  Future<List<UserModel>> _syncFriends(
    LocalBillRepository repository,
    String userId,
  ) async {
    final friends = await SupabaseDbService().getPastParticipants(userId);
    final cachedFriends = <UserModel>[];
    for (final friend in friends) {
      var cachedFriend = friend;
      final avatarUrl = friend.avatarUrl;
      final avatarUri = Uri.tryParse(avatarUrl ?? '');
      if (avatarUri != null &&
          (avatarUri.scheme == 'http' || avatarUri.scheme == 'https') &&
          avatarUri.host.isNotEmpty) {
        try {
          final localPath = await cacheRemoteImage(
            avatarUrl!,
            'avatar-${friend.id}',
          );
          cachedFriend = friend.copyWith(localAvatarPath: localPath);
        } catch (error, stackTrace) {
          debugPrint('Failed to cache friend avatar: $error\n$stackTrace');
        }
      }
      await repository.cacheProfile(cachedFriend.toMap());
      cachedFriends.add(cachedFriend);
    }
    return cachedFriends;
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
                            child:
                                friend.avatarUrl?.isNotEmpty == true ||
                                    friend.localAvatarPath != null
                                ? ClipOval(
                                    child: CachedAvatar(
                                      imageUrl: friend.avatarUrl,
                                      localImagePath: friend.localAvatarPath,
                                      size: 40,
                                      placeholder: const Icon(
                                        Icons.person,
                                        color: AppColors.pink,
                                      ),
                                    ),
                                  )
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
