import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/theme_provider.dart';
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
  String _historyFilter = 'all'; // 'all', 'unpaid', 'completed'

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
    final amount =
        double.tryParse(
          (bill['total_amount'] ?? bill['sub_total'])?.toString() ?? '0',
        ) ??
        0.0;
    final message = '📢 สะกิดเตือนเพื่อนตี้ "$shopName" จ้า!\n'
        '🍲 ยอดบิลรวม ฿${amount.toStringAsFixed(2)} ยังมียอดค้างชำระอยู่น้า\n'
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('เข้าร่วมห้องหารบิล', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรอกรหัส 6 หลักที่เพื่อนแชร์มาให้', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: _isCheckingRoom
                ? null
                : () {
                    Navigator.pop(dialogContext);
                    _joinRoom(codeController.text.trim());
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isCheckingRoom
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('เข้าร่วมตี้'),
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
    final email = _supabase.auth.currentUser?.email;
    final userName = email != null ? email.split('@')[0] : 'คุณ';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SNAP2BILL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  _historyFilter == 'all' ? 'Home' : 'History',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                tooltip: themeProvider.isDarkMode
                    ? 'สลับเป็นโหมดสว่าง'
                    : 'สลับเป็นโหมดมืด',
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_outline_rounded, color: AppColors.textPrimary, size: 22),
            tooltip: 'สมุดรายชื่อเพื่อน',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.friends),
          ),
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'แจ้งเตือน',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ไม่มีการแจ้งเตือนใหม่ในขณะนี้')),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  userName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
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

            // คำนวณยอดเงินค้างรับ และ ยอดทวงคืนสำเร็จ
            double unpaidTotal = 0.0;
            int unpaidCount = 0;
            double recoveredMonthlyTotal = 0.0;
            int recoveredMonthlyCount = 0;

            final now = DateTime.now();
            final currentMonthPrefix =
                '${now.year}-${now.month.toString().padLeft(2, '0')}';

            for (final b in bills) {
              final amount =
                  double.tryParse(
                    (b['total_amount'] ?? b['sub_total'])?.toString() ?? '0',
                  ) ??
                  0.0;
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

            // กรองบิลตามแท็บ
            final filteredBills = bills.where((b) {
              final settled = _isBillSettled(b);
              if (_historyFilter == 'unpaid') return !settled;
              if (_historyFilter == 'completed') return settled;
              return true;
            }).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. หัวข้อทักทาย + ป้ายสถานะ AI พร้อมทำงาน
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'สวัสดีคุณ$userName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('✌️', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'วันนี้ทานอะไรอร่อยๆ มาหรือยัง?',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 14, color: AppColors.success),
                            SizedBox(width: 3),
                            Text(
                              'AI พร้อมทำงาน',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. การ์ดสรุปยอดเงินค้างรับ (Soft Peach Card)
                  if (unpaidCount > 0)
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        setState(() => _historyFilter = 'unpaid');
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'บิลที่รอเคลียร์ $unpaidCount รายการ',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        AppFormatters.formatCurrency(unpaidTotal),
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'ค้างรับจากเพื่อน',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  if (unpaidCount > 0) const SizedBox(height: 14),

                  // 3. Hero Card: สแกนใบเสร็จ (Warm Terracotta / Coral Gradient)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE26A82),
                          Color(0xFFD95D77),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD95D77).withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // ป้ายมุมบน
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'สแกนแยกบิลอัตโนมัติ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Viewfinder กล้องขนาดใหญ่
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),

                        const Text(
                          'สร้างบิลใหม่ (สแกนใบเสร็จ)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ถ่ายรูปหรืออัปโหลดสลิปใบเสร็จ AI จะอ่านรายการให้ใน 2-3 วินาที',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // ปุ่มหลักเปิดกล้อง
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImageAndScan(ImageSource.camera),
                            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18, color: AppColors.primary),
                            label: const Text(
                              'เริ่มเปิดกล้องสแกน',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ปุ่มรอง: เลือกจากอัลบั้ม & กรอกรหัสห้อง
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImageAndScan(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined, size: 16, color: Colors.white),
                                label: const Text('เลือกจากอัลบั้ม', style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showJoinRoomDialog(context),
                                icon: const Icon(Icons.login_rounded, size: 16, color: Colors.white),
                                label: const Text('ใส่รหัสเข้าตี้', style: TextStyle(color: Colors.white, fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
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

                  // 4. การ์ดเคล็ดลับ (Warm Cream & Butter Peach Tint)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warmCream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.butterPeach),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_rounded, size: 18, color: Color(0xFFD97706)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'เคล็ดลับ: ถ่ายใบเสร็จในที่แสงสว่างและวางให้แบนเรียบเพื่อความแม่นยำ 99%',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. ส่วนรายการบิลล่าสุด & ฟิลเตอร์แท็บ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'บิลล่าสุดที่กำลังแชร์',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _historyFilter = 'all');
                        },
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'ดูทั้งหมด',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // แท็บสลับหมวด: ทั้งหมด | รอเก็บเงิน | เสร็จสิ้นแล้ว
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'ทั้งหมด', bills.length),
                        const SizedBox(width: 8),
                        _buildFilterChip('unpaid', 'รอเก็บเงิน (Active)', unpaidCount),
                        const SizedBox(width: 8),
                        _buildFilterChip('completed', 'เสร็จสิ้นแล้ว (Settled)', recoveredMonthlyCount),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // รายการบิล
                  if (filteredBills.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.receipt_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            _historyFilter == 'unpaid'
                                ? 'ไม่มีบิลที่ค้างชำระ เยี่ยมมาก! 🎉'
                                : _historyFilter == 'completed'
                                ? 'ยังไม่มีบิลที่ปิดยอดเสร็จสิ้น'
                                : 'ยังไม่มีประวัติบิล เริ่มต้นด้วยการสแกนได้เลย',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                        final totalAmount =
                            double.tryParse(
                              (bill['total_amount'] ?? bill['sub_total'])
                                      ?.toString() ??
                                  '0',
                            ) ??
                            0.0;
                        final date =
                            bill['created_at']?.toString().split('T')[0] ?? '';
                        final isSettled = _isBillSettled(bill);

                        return BillCard(
                          shopName: shopName,
                          totalAmount: totalAmount,
                          dateText: date,
                          status: isSettled ? 'completed' : 'pending',
                          memberCount: 4,
                          unpaidCount: isSettled ? 0 : 1,
                          unpaidMemberName: isSettled ? null : 'เพื่อนในตี้',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.detail,
                            arguments: bill,
                          ),
                          onRemind: !isSettled ? () => _pokeFriends(bill) : null,
                        );
                      },
                    ),

                  const SizedBox(height: 14),

                  // 6. การ์ดสถิติประจำเดือน (Emerald / Deep Teal Card)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F766E),
                          Color(0xFF065F46),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.savings_rounded, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'สถิติประจำเดือน  ตุลาคม 2024',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'ยอดที่คุณสำรองจ่ายและทวงคืนสำเร็จเดือนนี้',
                          style: TextStyle(fontSize: 12, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              AppFormatters.formatCurrency(
                                recoveredMonthlyTotal > 0 ? recoveredMonthlyTotal : 16467.73,
                              ),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'ครบ 100%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.bolt, size: 13, color: Color(0xFF34D399)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'ประหยัดเวลาคำนวณและทวงคืนสำเร็จ $recoveredMonthlyCount บิล ไม่ต้องคอยทวงให้เสียบรรยากาศ',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFD1FAE5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String title, int count) {
    final isSelected = _historyFilter == key;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() => _historyFilter = key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (count > 0 && !isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
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
                height: 90,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.5),
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
