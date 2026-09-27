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
  // เก็บว่า รายการที่ (index) -> ใครกดไปบ้าง (userId) -> จำนวนกี่ชิ้น (qty)
  final Map<int, Map<String, int>> _claimedItems = {};
  
  final _supabase = Supabase.instance.client;
  late String _currentUserId;
  late String _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id ?? 'host_id';
    _currentUserName = 'ฉัน (Host)';
  }

  void _increment(int index, int maxQty) {
    final itemClaims = _claimedItems[index] ?? {};
    int totalClaimed = 0;
    for (var qty in itemClaims.values) {
      totalClaimed += qty;
    }

    if (totalClaimed < maxQty) {
      setState(() {
        itemClaims[_currentUserId] = (itemClaims[_currentUserId] ?? 0) + 1;
        _claimedItems[index] = itemClaims;
      });
    }
  }

  void _decrement(int index) {
    final itemClaims = _claimedItems[index] ?? {};
    final myClaimedQty = itemClaims[_currentUserId] ?? 0;

    if (myClaimedQty > 0) {
      setState(() {
        itemClaims[_currentUserId] = myClaimedQty - 1;
        if (itemClaims[_currentUserId] == 0) {
          itemClaims.remove(_currentUserId);
        }
        _claimedItems[index] = itemClaims;
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
            'user_name': userId == _currentUserId ? _currentUserName : 'เพื่อน',
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
            child: Text('ร้าน: $shopName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              
                              // 🚀 ส่วนที่เพิ่มเข้ามา: แสดงป้ายชื่อคนกด
                              if (itemClaims.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: itemClaims.entries.map((entry) {
                                    final userId = entry.key;
                                    final qty = entry.value;
                                    // ถ้าเป็นไอดีเราให้แสดงชื่อเรา ถ้าไอดีคนอื่นให้แสดงชื่อเพื่อน
                                    final name = userId == _currentUserId ? _currentUserName : 'เพื่อน';
                                    
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Text(
                                        '$name: $qty', 
                                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold)
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