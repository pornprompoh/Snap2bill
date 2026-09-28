import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart';
import '../../utils/formatters.dart';
import '../../widgets/custom_button.dart';

class ClaimScreen extends StatefulWidget {
  final String lobbyId;
  final Map<String, dynamic> receiptData;

  const ClaimScreen({
    super.key,
    required this.lobbyId,
    required this.receiptData,
  });

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  // เก็บจำนวนที่กด: รายการที่ (index) -> ไอดีคนกด -> จำนวน (qty)
  final Map<int, Map<String, int>> _claimedItems = {};
  
  // เก็บชื่อเพื่อน: ไอดีคนกด -> ชื่อ (เอาไว้โชว์บนป้ายแทนคำว่า "เพื่อน")
  final Map<String, String> _userNames = {};
  
  final _supabase = Supabase.instance.client;
  late String _currentUserId;
  late String _currentUserName;
  late RealtimeChannel _claimChannel; // 🚀 เพิ่มตัวแปรช่องสัญญาณ

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    
    // ดึงอีเมลมาใช้เป็นชื่อชั่วคราว ถ้าไม่มีให้เป็น Guest
    final email = _supabase.auth.currentUser?.email;
    _currentUserName = email != null ? email.split('@')[0] : 'ผู้เข้าร่วม';
    
    _userNames[_currentUserId] = _currentUserName;
    
    _setupRealtime();
  }

  // 🚀 ฟังก์ชันตั้งค่าดักฟังการแย่งเมนู
  void _setupRealtime() {
    _claimChannel = _supabase.channel('room_${widget.lobbyId}');
    
    // ดักฟัง Event ชื่อ 'update_claim' ที่เพื่อนส่งมา
    _claimChannel.onBroadcast(event: 'update_claim', callback: (payload) {
      final index = payload['item_index'] as int;
      final userId = payload['user_id'] as String;
      final userName = payload['user_name'] as String;
      final qty = payload['qty'] as int;

      setState(() {
        _userNames[userId] = userName; // จำชื่อเพื่อนไว้
        
        final itemClaims = _claimedItems[index] ?? {};
        if (qty > 0) {
          itemClaims[userId] = qty;
        } else {
          itemClaims.remove(userId);
        }
        _claimedItems[index] = itemClaims;
      });
    }).subscribe();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_claimChannel); // ปิดช่องสัญญาณเมื่อออกจากหน้า
    super.dispose();
  }

  // 🚀 ฟังก์ชันส่งสัญญาณบอกทุกคนในห้องว่าเรากดอัปเดตเมนู
  void _broadcastUpdate(int index, int qty) {
    _claimChannel.sendBroadcastMessage(
      event: 'update_claim',
      payload: {
        'item_index': index,
        'user_id': _currentUserId,
        'user_name': _currentUserName,
        'qty': qty,
      },
    );
  }

  void _increment(int index, int maxQty) {
    final itemClaims = _claimedItems[index] ?? {};
    int totalClaimed = 0;
    for (var qty in itemClaims.values) {
      totalClaimed += qty;
    }

    if (totalClaimed < maxQty) {
      setState(() {
        final newQty = (itemClaims[_currentUserId] ?? 0) + 1;
        itemClaims[_currentUserId] = newQty;
        _claimedItems[index] = itemClaims;
        
        _broadcastUpdate(index, newQty); // 🚀 ส่งคลื่นกระจายเสียง
      });
    }
  }

  void _decrement(int index) {
    final itemClaims = _claimedItems[index] ?? {};
    final myClaimedQty = itemClaims[_currentUserId] ?? 0;

    if (myClaimedQty > 0) {
      setState(() {
        final newQty = myClaimedQty - 1;
        if (newQty == 0) {
          itemClaims.remove(_currentUserId);
        } else {
          itemClaims[_currentUserId] = newQty;
        }
        _claimedItems[index] = itemClaims;
        
        _broadcastUpdate(index, newQty); // 🚀 ส่งคลื่นกระจายเสียง
      });
    }
  }

  void _goToSummary() {
    Map<int, List<Map<String, dynamic>>> itemSharers = {};
    
    _claimedItems.forEach((index, userClaims) {
      List<Map<String, dynamic>> sharersList = [];
      userClaims.forEach((userId, qty) {
        for (int i = 0; i < qty; i++) {
          sharersList.add({
            'user_id': userId,
            'user_name': _userNames[userId] ?? 'เพื่อน',
          });
        }
      });
      itemSharers[index] = sharersList;
    });

    Navigator.pushNamed(
      context,
      AppRoutes.summary,
      arguments: {
        'lobbyId': widget.lobbyId,
        'receiptData': widget.receiptData,
        'itemSharers': itemSharers, 
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopName = widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกเมนูอาหาร (Claim)')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Text('รหัสห้อง: ${widget.lobbyId} | ร้าน: $shopName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemName = item['item_name'] ?? 'ไม่ระบุชื่อ';
                final maxQty = int.tryParse(item['qty']?.toString() ?? '1') ?? 1;
                final unitPrice = double.tryParse(item['unit_price']?.toString() ?? '0') ?? 0.0;
                
                final itemClaims = _claimedItems[index] ?? {};
                final myClaimedQty = itemClaims[_currentUserId] ?? 0;
                
                int totalClaimed = 0;
                for (var q in itemClaims.values) {
                  totalClaimed += q;
                }

                final isFullyClaimed = totalClaimed >= maxQty;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isFullyClaimed ? Colors.green.shade300 : Colors.grey.shade300,
                      width: isFullyClaimed ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                '${AppFormatters.formatCurrency(unitPrice)} / ชิ้น (มีทั้งหมด $maxQty)',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                              
                              if (itemClaims.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: itemClaims.entries.map((entry) {
                                    final userId = entry.key;
                                    final qty = entry.value;
                                    final name = _userNames[userId] ?? 'เพื่อน';
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: userId == _currentUserId ? Colors.blue.shade50 : Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: userId == _currentUserId ? Colors.blue.shade200 : Colors.orange.shade200),
                                      ),
                                      child: Text(
                                        '$name: $qty', 
                                        style: TextStyle(
                                          fontSize: 12, 
                                          color: userId == _currentUserId ? Colors.blue.shade700 : Colors.orange.shade700, 
                                          fontWeight: FontWeight.bold
                                        )
                                      ),
                                    );
                                  }).toList(),
                                )
                              ]
                            ],
                          ),
                        ),
                        
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              color: myClaimedQty > 0 ? Colors.red : Colors.grey,
                              onPressed: myClaimedQty > 0 ? () => _decrement(index) : null,
                            ),
                            Text(
                              '$myClaimedQty',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: isFullyClaimed ? Colors.grey : Colors.green,
                              onPressed: isFullyClaimed ? null : () => _increment(index, maxQty),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'สรุปยอดและเคลียร์บิล',
              onPressed: _goToSummary,
            ),
          ),
        ],
      ),
    );
  }
}