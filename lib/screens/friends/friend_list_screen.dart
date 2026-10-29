import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/contact_model.dart';
import '../../models/user_model.dart';
import '../../providers/contact_provider.dart';
import '../../services/supabase_db_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/friend_item.dart';

class FriendListScreen extends StatefulWidget {
  final bool selectionMode;

  const FriendListScreen({super.key, this.selectionMode = false});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final _supabase = Supabase.instance.client;
  final _dbService = SupabaseDbService();
  final Set<String> _selectedIds = {};
  Future<List<UserModel>>? _participantsFuture;

  @override
  void initState() {
    super.initState();
    unawaited(context.read<ContactProvider>().loadContacts());
    if (widget.selectionMode) _loadPastParticipants();
  }

  void _loadPastParticipants() {
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
    Navigator.pop(
      context,
      participants
          .where((participant) => _selectedIds.contains(participant.id))
          .toList(),
    );
  }

  String _displayName(UserModel user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    return user.email ?? 'ไม่มีชื่อ';
  }

  Future<bool> _confirmDelete(ContactModel contact) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ลบรายชื่อ'),
        content: Text('ลบ ${contact.name} ออกจากประวัติรายชื่อหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (!mounted || shouldDelete != true) return false;

    try {
      await context.read<ContactProvider>().deleteContact(contact.id);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบรายชื่อไม่สำเร็จ: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  Widget _buildSavedContacts(ContactProvider provider) {
    if (provider.isLoading && provider.contacts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(provider.error!, textAlign: TextAlign.center),
            ),
            TextButton(
              onPressed: () => provider.loadContacts(),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      );
    }
    if (provider.contacts.isEmpty) {
      return const Center(
        child: Text('รายชื่อเพื่อนที่เคยหารบิลด้วยกันจะแสดงที่นี่'),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadContacts,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.paddingS),
        itemCount: provider.contacts.length,
        itemBuilder: (context, index) {
          final contact = provider.contacts[index];
          return Dismissible(
            key: ValueKey(contact.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(contact),
            background: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.only(right: 20),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            child: Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person_outline),
                ),
                title: Text(
                  contact.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  contact.note?.trim().isNotEmpty == true
                      ? contact.note!.trim()
                      : 'ไม่มีหมายเหตุ',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPastParticipants() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return const Center(child: Text('กรุณาล็อกอิน'));
    }
    return Column(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('โหลดรายชื่อเพื่อนไม่สำเร็จ'),
                      TextButton(
                        onPressed: () => setState(_loadPastParticipants),
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
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
                padding: const EdgeInsets.all(AppConstants.paddingS),
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
            onPressed: _selectedIds.isEmpty
                ? null
                : () async {
                    final participants = await _participantsFuture;
                    if (mounted && participants != null) {
                      _returnSelected(participants);
                    }
                  },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactProvider = context.watch<ContactProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.selectionMode ? 'เลือกเพื่อนจากบิลก่อนหน้า' : 'เพื่อนที่เคยหารบิล',
        ),
      ),
      body: widget.selectionMode
          ? _buildPastParticipants()
          : _buildSavedContacts(contactProvider),
    );
  }
}
