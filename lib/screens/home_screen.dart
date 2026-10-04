import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/bill_card.dart';
import '../widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _billsFuture;
  bool _isCheckingRoom = false;

  @override
  void initState() {
    super.initState();
    _billsFuture = _fetchMyBills();
  }

  // 🚀 ดึงข้อมูลทั้งบิลที่ตัวเองเป็นเจ้าของ และบิลที่ไปร่วมหาร
  Future<List<Map<String, dynamic>>> _fetchMyBills() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // 1. ดึงบิลที่ฉันเป็นเจ้าของ (Host)
      final ownedBills = await _supabase
          .from('bills')
          .select()
          .eq('owner_id', userId);

      // 2. ดึงบิลที่ฉันเป็นผู้ร่วมหาร (Guest) ผ่านตาราง bill_participants
      final participated = await _supabase
          .from('bill_participants')
          .select('bills(*)') // ดึงข้อมูลบิลที่เชื่อมอยู่มาด้วย
          .eq('profile_id', userId);

      // ใช้ Map เพื่อรวมบิลและป้องกันการแสดงบิลซ้ำ (กรณีเป็นทั้ง Host และควบตำแหน่งคนหารด้วย)
      final Map<String, Map<String, dynamic>> uniqueBills = {};

      for (var b in ownedBills) {
        uniqueBills[b['id'].toString()] = b;
      }

      for (var p in participated) {
        if (p['bills'] != null) {
          final b = p['bills'] as Map<String, dynamic>;
          uniqueBills[b['id'].toString()] = b;
        }
      }

      final result = uniqueBills.values.toList();

      // เรียงลำดับจากวันที่ใหม่สุดไปเก่าสุด
      result.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at'].toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            DateTime.tryParse(b['created_at'].toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      return result;
    } catch (e) {
      debugPrint('Error fetching bills: $e');
      return [];
    }
  }

  Future<void> _joinRoom(String roomCode) async {
    if (roomCode.length != 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสห้องให้ครบ 6 หลัก')),
      );
      return;
    }

    setState(() => _isCheckingRoom = true);

    try {
      final response = await _supabase
          .from('lobbies')
          .select()
          .eq('room_code', roomCode)
          .maybeSingle();

      if (!mounted) return;

      if (response != null) {
        final shopName = response['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
        final receiptData = response['receipt_json'] as Map<String, dynamic>?;

        Navigator.pushNamed(
          context,
          AppRoutes.lobby,
          arguments: {
            'lobbyId': roomCode,
            'shop_name': shopName,
            'receiptData': receiptData,
            'isHost': false,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('รหัสไม่ถูกต้อง หรือไม่มีห้องนี้อยู่จริง'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการตรวจสอบห้อง: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingRoom = false);
    }
  }

  void _showJoinRoomDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('เข้าร่วมห้องหารบิล'),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'กรอกรหัส 6 หลัก',
            filled: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: _isCheckingRoom
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    _joinRoom(codeController.text);
                  },
            child: _isCheckingRoom
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('เข้าร่วม'),
          ),
        ],
      ),
    );
  }

  // 🚀 ฟังก์ชันรีเฟรชหน้าจอเมื่อดึงหน้าจอลง
  Future<void> _refreshBills() async {
    setState(() {
      _billsFuture = _fetchMyBills();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Snap2Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'สมุดรายชื่อเพื่อน',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBills,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _showJoinRoomDialog(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.login,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'มีเพื่อนสร้างห้องไว้แล้ว?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'กรอกรหัส 6 หลักเพื่อเข้าร่วม',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text('ประวัติการหารบิล', style: AppTextStyles.title),
              const SizedBox(height: 12),

              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _billsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _BillsLoadingSkeleton();
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'เกิดข้อผิดพลาด: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final bills = snapshot.data ?? [];

                    if (bills.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 300,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withValues(
                                          alpha: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 42,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'บิลแรกของคุณเริ่มได้ที่นี่',
                                      style: AppTextStyles.title,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'สแกนใบเสร็จเพื่อสร้างบิลและแบ่งรายการกับเพื่อน',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: 240,
                                      child: CustomButton(
                                        text: 'สแกนบิลใหม่',
                                        onPressed: () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.scan,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        final shopName = bill['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
                        final totalAmount =
                            double.tryParse(
                              (bill['total_amount'] ?? bill['sub_total'])
                                      ?.toString() ??
                                  '0',
                            ) ??
                            0.0;
                        final date =
                            bill['created_at']?.toString().split('T')[0] ?? '';

                        return BillCard(
                          shopName: shopName,
                          totalAmount: totalAmount,
                          dateText: date,
                          status: bill['status']?.toString() ?? 'pending',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.detail,
                            arguments: bill,
                          ),
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

class _BillsLoadingSkeleton extends StatefulWidget {
  const _BillsLoadingSkeleton();

  @override
  State<_BillsLoadingSkeleton> createState() => _BillsLoadingSkeletonState();
}

class _BillsLoadingSkeletonState extends State<_BillsLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulseColor = Color.lerp(
          AppColors.border,
          AppColors.secondary.withValues(alpha: 0.65),
          _pulseController.value,
        )!;

        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) => Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: pulseColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index.isEven ? 148 : 118,
                        height: 14,
                        decoration: BoxDecoration(
                          color: pulseColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 9),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 84,
                        height: 10,
                        decoration: BoxDecoration(
                          color: pulseColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 68,
                  height: 15,
                  decoration: BoxDecoration(
                    color: pulseColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
