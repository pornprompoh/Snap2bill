import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/join/pending_join_store.dart';

class JoinRoomScreen extends StatefulWidget {
  final String? roomId;

  const JoinRoomScreen({super.key, this.roomId});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _pendingJoinStore = const PendingJoinStore();
  String? _errorMessage;
  bool _isJoining = true;
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasStarted) return;
    _hasStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _join());
  }

  Future<void> _join() async {
    if (!mounted) return;
    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final roomId = widget.roomId ?? await _pendingJoinStore.read();
      if (roomId == null || roomId.isEmpty) {
        throw StateError('ไม่พบรหัสบิลหรือห้องที่ต้องการเข้าร่วม');
      }

      await _pendingJoinStore.save(roomId);
      if (!mounted) return;
      if (Supabase.instance.client.auth.currentUser == null) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        return;
      }

      if (RegExp(r'^\d{6}$').hasMatch(roomId)) {
        await _joinLegacyRoom(roomId);
      } else if (RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(roomId)) {
        await _joinBill(roomId);
      } else {
        throw FormatException('รูปแบบรหัสบิลหรือห้องไม่ถูกต้อง');
      }
    } catch (error, stackTrace) {
      debugPrint('เข้าร่วมบิลหรือห้องไม่สำเร็จ: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isJoining = false;
        _errorMessage = 'เข้าร่วมไม่สำเร็จ: $error';
      });
    }
  }

  Future<void> _joinLegacyRoom(String roomId) async {
    final supabase = Supabase.instance.client;
    final room = await supabase
        .from('lobbies')
        .select('host_id, receipt_json')
        .eq('room_code', roomId)
        .maybeSingle();
    if (room == null) throw StateError('ไม่พบห้องรหัส $roomId');

    final receiptData = _asMap(room['receipt_json']);
    final hostId = room['host_id']?.toString();
    if (hostId != null) receiptData['owner_id'] = hostId;
    await _pendingJoinStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.lobby,
      (route) => false,
      arguments: {
        'lobbyId': roomId,
        'receiptData': receiptData,
        'isHost': hostId == supabase.auth.currentUser?.id,
      },
    );
  }

  Future<void> _joinBill(String billId) async {
    final supabase = Supabase.instance.client;
    await supabase.rpc('join_bill', params: {'p_bill_id': billId});
    final bill = await supabase
        .from('bills')
        .select()
        .eq('id', billId)
        .single();

    await _pendingJoinStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.detail,
      (route) => false,
      arguments: Map<String, dynamic>.from(bill),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isJoining
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังนำคุณเข้าสู่บิล...'),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage ?? 'ไม่สามารถเข้าร่วมได้',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _join,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        await _pendingJoinStore.clear();
                        if (!mounted || !navigator.mounted) return;
                        navigator.pushNamedAndRemoveUntil(
                          AppRoutes.home,
                          (_) => false,
                        );
                      },
                      child: const Text('กลับหน้าหลัก'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
