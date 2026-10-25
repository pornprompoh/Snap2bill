import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snap2bill/models/bill_model.dart';
import 'package:snap2bill/repositories/bill_repository.dart';
import 'package:snap2bill/routes/app_routes.dart';
import 'package:snap2bill/screens/bill/bill_detail_screen.dart';
import 'package:snap2bill/theme/app_colors.dart';
import 'package:snap2bill/theme/app_text_styles.dart';
import 'package:snap2bill/utils/formatters.dart';
import 'package:snap2bill/widgets/bill/bill_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final BillRepository _localRepo = BillRepository();

  late Future<List<Map<String, dynamic>>> _billsFuture;
  bool _isCheckingRoom = false;
  String _historyFilter = 'all'; // 'unpaid', 'completed', 'all'

  @override
  void initState() {
    super.initState();
    _billsFuture = _fetchMyBills();
  }

  Future<void> _pickImageAndScan(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        Navigator.pushNamed(context, AppRoutes.loading, arguments: bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการเปิดกล้อง/ภาพ: $e')),
        );
      }
    }
  }

  Future<void> _pokeFriends(Map<String, dynamic> bill) async {
    final shopName = bill['shop_name'] ?? 'ร้านอาหาร';
    final amount = BillModel.totalFromJson(bill);
    final message =
        '📢 สะกิดเตือนเพื่อนตี้ "$shopName" จ้า!\n'
        '🍲 ยอดบิลรวม ฿${amount.toStringAsFixed(2)} ยังมียอดค้างชำระอยู่น้า\n'
        '📲 ใครยังไม่ได้โอนเงิน รบกวนเปิด Snap2Bill โอนเงินพร้อมส่งสลิปด้วยเน้อ ขอบคุณครับ/ค่ะ 🙏✨';
    await SharePlus.instance.share(
      ShareParams(title: 'สะกิดเตือนเพื่อนหารบิล', text: message),
    );
  }

  // 🚀 ดึงข้อมูลทั้งบิลที่ตัวเองเป็นเจ้าของ และบิลที่ไปร่วมหาร พร้อมแคชลง Drift (Offline First)
  Future<List<Map<String, dynamic>>> _fetchMyBills() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return await _localRepo.getCachedBills();
      }

      final ownedBills = await _supabase
          .from('bills')
          .select()
          .eq('owner_id', userId);

      final participated = await _supabase
          .from('bill_participants')
          .select('bills(*)')
          .eq('profile_id', userId);

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

      result.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at'].toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB =
            DateTime.tryParse(b['created_at'].toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });

      await _localRepo.cacheSupabaseBills(result);
      return result;
    } catch (e) {
      debugPrint('Error fetching bills from Supabase: $e');
      final cached = await _localRepo.getCachedBills();
      if (cached.isNotEmpty) return cached;
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

  Future<void> _refreshBills() async {
    setState(() {
      _billsFuture = _fetchMyBills();
    });
  }

  bool _isBillSettled(Map<String, dynamic> bill) {
    final status = bill['status']?.toString().toLowerCase() ?? '';
    return const {'paid', 'settled', 'cleared', 'completed'}.contains(status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _billsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: const Padding(
                  key: ValueKey('loading_skeleton'),
                  padding: EdgeInsets.all(16.0),
                  child: _BillsLoadingSkeleton(),
                ),
              );
            }

            final bills = snapshot.data ?? [];

            // คำนวณยอดเงินค้างรับ และ ยอดทวงคืนสำเร็จเดือนนี้
            double unpaidTotal = 0.0;
            int unpaidCount = 0;
            double recoveredMonthlyTotal = 0.0;
            int recoveredMonthlyCount = 0;

            final now = DateTime.now();
            final currentMonthPrefix =
                '${now.year}-${now.month.toString().padLeft(2, '0')}';

            for (final b in bills) {
              final amount = BillModel.totalFromJson(b);
              final isSettled = _isBillSettled(b);
              final createdAt = b['created_at']?.toString() ?? '';

              if (isSettled) {
                if (createdAt.startsWith(currentMonthPrefix)) {
                  recoveredMonthlyTotal += amount;
                  recoveredMonthlyCount++;
                }
              } else {
                unpaidTotal += amount;
                unpaidCount++;
              }
            }

            // กรองบิลตามแท็บประวัติ
            final filteredBills = bills.where((b) {
              final settled = _isBillSettled(b);
              if (_historyFilter == 'unpaid') return !settled;
              if (_historyFilter == 'completed') return settled;
              return true;
            }).toList();

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: SingleChildScrollView(
                key: const ValueKey('real_content'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. การ์ดสรุปยอดเงินค้างรับ & ยอดที่ทวงคืนสำเร็จเดือนนี้
                    Row(
                      children: [
                        // ยอดค้างรับ
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade50,
                                  Colors.amber.shade50,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.pending_actions,
                                      size: 18,
                                      color: Colors.orange.shade800,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ยอดค้างรับ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppFormatters.formatCurrency(unpaidTotal),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                Text(
                                  'รอเก็บ $unpaidCount บิล',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ยอดทวงคืนสำเร็จเดือนนี้
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade50,
                                  Colors.teal.shade50,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color: Colors.green.shade800,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'ทวงคืนสำเร็จเดือนนี้',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppFormatters.formatCurrency(
                                    recoveredMonthlyTotal,
                                  ),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                Text(
                                  'ปิดยอด $recoveredMonthlyCount บิล',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 2. โดดเด่นด้วยการ์ด "สร้างบิลใหม่ (สแกนใบเสร็จ)" พร้อมสัญลักษณ์ Viewfinder
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // สัญลักษณ์ Viewfinder โดดเด่น
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.crop_free, // Viewfinder symbol
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'สร้างบิลใหม่ (สแกนใบเสร็จ)',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'AI อ่านข้อมูลถอดเมนูและราคาใน 2-3 วินาที',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _pickImageAndScan(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text('เปิดกล้องถ่าย'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primaryDark,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickImageAndScan(ImageSource.gallery),
                                  icon: const Icon(
                                    Icons.photo_library,
                                    size: 18,
                                  ),
                                  label: const Text('เลือกจากอัลบั้ม'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Colors.white70,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 3. กล่องคำแนะนำเพื่อให้ AI อ่านแม่นยำที่สุด
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: Colors.amber.shade900,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '💡 คำแนะนำเพื่อให้ AI สแกนแม่นยำที่สุด: ถ่ายในที่แสงสว่างเพียงพอ วางใบเสร็จให้เรียบแบน และถ่ายให้เห็นยอดรวมชัดเจน',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.brown.shade800,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 4. เข้าร่วมห้องเพื่อนแบบด่วน
                    InkWell(
                      onTap: () => _showJoinRoomDialog(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.5),
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.login,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'มีเพื่อนสร้างห้องไว้แล้ว?',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'กรอกรหัส 6 หลักเพื่อเข้าร่วมตี้',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
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

                    // 5. Screen 6: History (หน้าประวัติบิล) พร้อมแยกหมวดชัดเจน
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ประวัติการหารบิล', style: AppTextStyles.title),
                        Text(
                          'ทั้งหมด ${bills.length} บิล',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ตัวเลือกหมวดหมู่แท็บ: "ยังเก็บไม่ครบ" | "เสร็จสมบูรณ์" | "ทั้งหมด"
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment<String>(
                            value: 'unpaid',
                            icon: const Icon(Icons.schedule, size: 16),
                            label: Text(
                              'ยังไม่ครบ ($unpaidCount)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          ButtonSegment<String>(
                            value: 'completed',
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                            ),
                            label: Text(
                              'เสร็จสิ้น ($recoveredMonthlyCount)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const ButtonSegment<String>(
                            value: 'all',
                            label: Text(
                              'ทั้งหมด',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                        selected: {_historyFilter},
                        onSelectionChanged: (selection) {
                          setState(() => _historyFilter = selection.first);
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // รายการบิล
                    if (filteredBills.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _historyFilter == 'unpaid'
                                  ? 'ไม่มีบิลที่ค้างชำระ ยอดเยี่ยมมาก! 🎉'
                                  : _historyFilter == 'completed'
                                  ? 'ยังไม่มีบิลที่ปิดยอดเสร็จสมบูรณ์'
                                  : 'ยังไม่มีประวัติบิล',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredBills.length,
                        itemBuilder: (context, index) {
                          final bill = filteredBills[index];
                          final shopName =
                              bill['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
                          final totalAmount = BillModel.totalFromJson(bill);
                          final date =
                              bill['created_at']?.toString().split('T')[0] ??
                              '';
                          final isSettled = _isBillSettled(bill);

                          return BillCard(
                            shopName: shopName,
                            totalAmount: totalAmount,
                            dateText: date,
                            status: isSettled ? 'completed' : 'pending',
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder<void>(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        DetailScreen(billData: bill),
                                transitionDuration: Duration.zero,
                                reverseTransitionDuration: Duration.zero,
                              ),
                            ),
                            onPoke: isSettled ? null : () => _pokeFriends(bill),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
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
          itemBuilder: (context, index) => SizedBox(
            height: 106,
            child: Container(
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
          ),
        );
      },
    );
  }
}
