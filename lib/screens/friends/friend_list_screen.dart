import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../services/supabase_db_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/friend_item.dart';

class FriendListScreen extends StatefulWidget {
  const FriendListScreen({super.key});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final _supabase = Supabase.instance.client;
  final _dbService = SupabaseDbService();
  final Set<String> _selectedIds = {};
  late final Future<List<UserModel>>? _participantsFuture;

  @override
  void initState() {
    super.initState();
    final userId = _supabase.auth.currentUser?.id;
    _participantsFuture = userId == null
        ? null
        : _dbService.getPastParticipants(userId);
  }

  void _toggleSelection(String userId, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedIds.add(userId);
      } else {
        _selectedIds.remove(userId);
      }
    });
  }

  void _returnSelected(List<UserModel> participants) {
    final selectedFriends = participants
        .where((participant) => _selectedIds.contains(participant.id))
        .toList();
    Navigator.pop(context, selectedFriends);
  }

  String _displayName(UserModel user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return user.email ?? 'ไม่มีชื่อ';
  }

  @override
  Widget build(BuildContext context) {
    final userId = _supabase.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกเพื่อนเข้าห้อง')),
      body: userId == null
          ? const Center(child: Text('กรุณาล็อกอิน'))
          : Column(
              children: [
                Expanded(
                  child: FutureBuilder<List<UserModel>>(
                    future: _participantsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(
                              AppConstants.paddingL,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('โหลดรายชื่อเพื่อนไม่สำเร็จ'),
                                const SizedBox(height: AppConstants.paddingS),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _participantsFuture = _dbService
                                        .getPastParticipants(userId);
                                  }),
                                  child: const Text('ลองอีกครั้ง'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final participants = snapshot.data ?? [];
                      if (participants.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppConstants.paddingL),
                            child: Text(
                              'ยังไม่มีเพื่อนจากบิลก่อนหน้า\nที่สามารถเพิ่มเข้าห้องได้',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppConstants.paddingS,
                          AppConstants.paddingS,
                          AppConstants.paddingS,
                          AppConstants.paddingM,
                        ),
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          final participant = participants[index];
                          return FriendItem(
                            name: _displayName(participant),
                            subtitleText: participant.email,
                            isSelected: _selectedIds.contains(participant.id),
                            onSelectionChanged: (selected) =>
                                _toggleSelection(participant.id, selected),
                          );
                        },
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  minimum: const EdgeInsets.all(AppConstants.paddingM),
                  child: CustomButton(
                    text: 'ดึงเพื่อนเข้าห้อง (${_selectedIds.length})',
                    onPressed:
                        _selectedIds.isEmpty || _participantsFuture == null
                        ? null
                        : () async {
                            final participants = await _participantsFuture;
                            if (mounted) _returnSelected(participants);
                          },
                  ),
                ),
              ],
            ),
    );
  }
}
