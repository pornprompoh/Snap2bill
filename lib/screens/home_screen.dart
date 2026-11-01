import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/local_bill_repository.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/bill_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = Supabase.instance.client;
  final LocalBillRepository _localRepo = LocalBillRepository();

  late Future<List<Map<String, dynamic>>> _billsFuture;
  bool _isCheckingRoom = false;
  String _historyFilter = 'unpaid'; // 'unpaid', 'completed', 'all'

  @override
  void initState() {
    super.initState();
    _billsFuture = _fetchMyBills();
  }

  Future<void> _refreshBills() async {
    setState(() {
      _billsFuture = _fetchMyBills();
    });
    await _billsFuture;
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

  Future<void> _pokeFriends(Map<String, dynamic>? bill) async {
    final shopName = bill?['shop_name'] ?? 'ตี้อาหารของเรา';
    final amount = bill != null
        ? (double.tryParse(
              (bill['total_amount'] ?? bill['sub_total'])?.toString() ?? '0',
            ) ??
            0.0)
        : 0.0;
    final message = '📢 สะกิดเตือนเพื่อนตี้ "$shopName" จ้า!\n'
        '🍲 ${amount > 0 ? "ยอดบิลรวม ฿${amount.toStringAsFixed(2)} " : ""}ยังมียอดค้างชำระอยู่น้า\n'
        '📲 ใครยังไม่ได้โอนเงิน รบกวนเปิด Snap2Bill โอนเงินพร้อมส่งสลิปด้วยเน้อ ขอบคุณครับ/ค่ะ 🙏✨';
    await SharePlus.instance.share(
      ShareParams(
        title: 'สะกิดเตือนเพื่อนหารบิล',
        text: message,
      ),
    );
  }

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
            backgroundColor: AppColors.primaryOrange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการค้นหาห้อง: $e'),
          backgroundColor: AppColors.primaryOrange,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('เข้าร่วมห้องหารบิล', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรอกรหัส 6 หลักที่เพื่อนแชร์มาให้', style: TextStyle(fontSize: 13, color: AppColors.gray)),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: '123456',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก', style: TextStyle(color: AppColors.gray)),
          ),
          ElevatedButton(
            onPressed: _isCheckingRoom
                ? null
                : () {
                    final code = codeController.text.trim();
                    Navigator.pop(dialogContext);
                    _joinRoom(code);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pink,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('เข้าร่วมเลย'),
          ),
        ],
      ),
    );
  }

  bool _isBillSettled(Map<String, dynamic> bill) {
    final status = bill['status']?.toString().toLowerCase() ?? '';
    return const {'paid', 'settled', 'cleared', 'completed'}.contains(status);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.black;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.gray;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Text(
          'Snap2Bill',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          // Friends button (Matching mockup top right)
          IconButton(
            icon: Icon(Icons.people_alt_outlined, color: textPrimary, size: 26),
            tooltip: 'เพื่อนในตี้',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.pink,
        onRefresh: _refreshBills,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _billsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: _BillsLoadingSkeleton(),
              );
            }

            final bills = snapshot.data ?? [];

            // Calculate active and completed sums
            double unpaidTotal = 0.0;
            int unpaidCount = 0;
            double recoveredMonthlyTotal = 0.0;
            int recoveredMonthlyCount = 0;

            final now = DateTime.now();
            final currentMonthPrefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';

            for (final b in bills) {
              final amount = double.tryParse((b['total_amount'] ?? b['sub_total'])?.toString() ?? '0') ?? 0.0;
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

            // Filter bills according to active segment
            final filteredBills = bills.where((b) {
              final settled = _isBillSettled(b);
              if (_historyFilter == 'unpaid') return !settled;
              if (_historyFilter == 'completed') return settled;
              return true;
            }).toList();

            // --- VIEW A: EMPTY STATE (Matching Image 3 Left) ---
            if (bills.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Join Room Card
                    _buildJoinRoomCard(isDark, textPrimary, textSecondary),
                    const SizedBox(height: 20),

                    // Section Heading
                    Text(
                      'ประวัติการหารบิล',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Center Empty State
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardBackground : AppColors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? AppColors.darkBorder : const Color(0xFFEEEEEE),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                'assets/images/bunny_mascot.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.receipt_long_rounded,
                                  size: 48,
                                  color: AppColors.pink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'บิลแรกของคุณเริ่มได้ที่นี่',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'สแกนใบเสร็จเพื่อสร้างบิลและแบ่งรายการกับเพื่อน',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 160,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => _pickImageAndScan(ImageSource.camera),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.pink,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'สแกนบิลใหม่',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              );
            }

            // --- VIEW B: ACTIVE CONTENT (Matching Image 3 Right & Image 4) ---
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Two Top Stat Cards Side-by-Side (Pale Yellow & Light Green)
                  Row(
                    children: [
                      // Card 1: Unpaid Amount (Pale Yellow)
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _historyFilter = 'unpaid'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C281E) : AppColors.paleYellow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF4A402A) : const Color(0xFFFFEEA8),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ยอดค้างชำระ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.white : AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.formatCurrency(unpaidTotal),
                                  style: TextStyle(
                                    fontSize: 19.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.white : AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'รอเก็บ $unpaidCount บิล',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Card 2: Recovered / Settled Amount (Light Green)
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _historyFilter = 'completed'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2C22) : AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF2E4D36) : const Color(0xFFA2EDB0),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ทวงคืนสำเร็จเดือนนี้',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.white : AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.formatCurrency(recoveredMonthlyTotal),
                                  style: TextStyle(
                                    fontSize: 19.5,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? AppColors.white : AppColors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ปิดยอด $recoveredMonthlyCount บิล',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. Hero Scan Card (Teal Green Linear Gradient)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.tealGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.tealGreen.withValues(alpha: 0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(
                                Icons.document_scanner_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'สร้างบิลใหม่ (สแกนใบเสร็จ)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'AI อ่านข้อมูลถอดเมนูและราคาใน 2-3 นาที',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Action Buttons in Hero Card
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _pickImageAndScan(ImageSource.camera),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.tealGreen,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'เปิดกล้องถ่าย',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.tealGreen,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _pickImageAndScan(ImageSource.gallery),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: AppColors.whiteOverlay24,
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'เลือกจากอัลบั้ม',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Tip Card (Pale Yellow)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C281E) : AppColors.paleYellow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF4A402A) : const Color(0xFFFFEEA8),
                      ),
                    ),
                    child: Text(
                      'คำแนะนำ: เพื่อให้ AI สแกนแม่นยำที่สุด ถ่ายในที่แสงสว่างเพียงพอ วางใบเสร็จให้เรียบแบน และถ่ายให้เห็นยอดรวมชัดเจน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFF0D58C) : const Color(0xFF8A6200),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. Join Room Card (Light Pink)
                  _buildJoinRoomCard(isDark, textPrimary, textSecondary),
                  const SizedBox(height: 18),

                  // 5. Section Header & Total Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ประวัติการหารบิล',
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'ทั้งหมด ${bills.length} บิล',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 6. Segmented Filter Tabs
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? AppColors.darkBorder : const Color(0xFFD6D6D6)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFilterTab(
                            key: 'unpaid',
                            title: 'ยังไม่ครบ ($unpaidCount)',
                            icon: Icons.access_time_rounded,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildFilterTab(
                            key: 'completed',
                            title: 'เสร็จสิ้น ($recoveredMonthlyCount)',
                            icon: Icons.check_circle_outline_rounded,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildFilterTab(
                            key: 'all',
                            title: 'ทั้งหมด',
                            icon: Icons.check_rounded,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 7. Poke Friend Reminder Button (Matching Image 3 & 4)
                  if (unpaidCount > 0)
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _pokeFriends(filteredBills.isNotEmpty ? filteredBills.first : null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFD6D6D6),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'สะกิดเตือนเพื่อน',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.gray,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.notifications_active_rounded,
                                size: 16,
                                color: AppColors.yellow,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // 8. Bill Card List
                  if (filteredBills.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.receipt_outlined, size: 44, color: textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text(
                            _historyFilter == 'unpaid'
                                ? 'ไม่มีบิลที่ค้างชำระ ยอดเคลียร์ครบแล้ว! 🎉'
                                : _historyFilter == 'completed'
                                ? 'ยังไม่มีบิลที่ปิดยอดเสร็จสิ้น'
                                : 'ยังไม่มีประวัติบิล',
                            style: TextStyle(color: textSecondary, fontSize: 13),
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
                        final shopName = bill['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
                        final totalAmount = double.tryParse(
                              (bill['total_amount'] ?? bill['sub_total'])?.toString() ?? '0',
                            ) ??
                            0.0;
                        final date = bill['created_at']?.toString().split('T')[0] ?? '';
                        final isSettled = _isBillSettled(bill);

                        return BillCard(
                          shopName: shopName,
                          totalAmount: totalAmount,
                          dateText: date,
                          status: isSettled ? 'completed' : 'pending',
                          memberCount: 4,
                          unpaidCount: isSettled ? 0 : 1,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.detail,
                            arguments: bill,
                          ),
                          onRemind: !isSettled ? () => _pokeFriends(bill) : null,
                        );
                      },
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildJoinRoomCard(bool isDark, Color textPrimary, Color textSecondary) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showJoinRoomDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E2028) : AppColors.lightPink,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF4A3340) : const Color(0xFFFFBCE3),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.login_rounded,
                color: AppColors.pink,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'มีเพื่อนสร้างห้องไว้แล้ว',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'กรอกรหัส 6 หลักเพื่อเข้าร่วม',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab({
    required String key,
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _historyFilter == key;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _historyFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF382330) : AppColors.lightPink)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.pink, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? AppColors.pink
                  : (isDark ? AppColors.darkTextSecondary : AppColors.gray),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.pink
                      : (isDark ? AppColors.darkTextPrimary : AppColors.black),
                ),
              ),
            ),
          ],
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
        final opacity = 0.45 + (_pulseController.value * 0.4);
        return Opacity(
          opacity: opacity,
          child: Column(
            children: List.generate(
              3,
              (index) => Container(
                height: 76,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
