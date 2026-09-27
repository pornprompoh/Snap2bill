import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes/app_routes.dart'; // 🚀 นำเข้าระบบนำทาง
import '../../widgets/custom_button.dart'; // 🚀 นำเข้าปุ่ม
import '../../utils/formatters.dart'; // 🚀 นำเข้าตัวจัดรูปแบบเงิน

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
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _participants = [];
  final Map<int, List<Map<String, dynamic>>> _itemSharers = {};

  @override
  void initState() {
    super.initState();
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    try {
      final data = await _supabase
          .from('participants')
          .select()
          .eq('lobby_id', widget.lobbyId)
          .order('joined_at', ascending: true);
          
      if (mounted) {
        setState(() {
          _participants = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching participants: $e');
    }
  }

  Future<void> _selectSharers(int itemIndex) async {
    final currentSharers = _itemSharers[itemIndex] ?? [];
    
    final selected = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) {
        final tempSelection = List<Map<String, dynamic>>.from(currentSharers);
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('เลือกคนหารเมนูนี้'),
              content: _participants.isEmpty
                  ? const Text('ยังไม่มีเพื่อนในห้อง')
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: _participants.map((person) {
                          final isSelected = tempSelection.any((p) => p['id'] == person['id']);
                          return CheckboxListTile(
                            title: Text(person['user_name']),
                            subtitle: person['is_host'] == true ? const Text('หัวหน้าห้อง') : null,
                            value: isSelected,
                            onChanged: (bool? val) {
                              setStateDialog(() {
                                if (val == true) {
                                  tempSelection.add(person);
                                } else {
                                  tempSelection.removeWhere((p) => p['id'] == person['id']);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempSelection),
                  child: const Text('ตกลง'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected != null) {
      setState(() {
        _itemSharers[itemIndex] = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.receiptData['items'] as List<dynamic>? ?? [];
    final shopName = widget.receiptData['shop_name'] ?? 'ไม่ระบุชื่อร้าน';

    return Scaffold(
      appBar: AppBar(title: const Text('เลือกเมนูอาหาร (Claim)')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            width: double.infinity,
            child: Text('ร้าน: $shopName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemName = item['item_name'] ?? 'ไม่มีชื่อ';
                // แปลงค่าเงินเพื่อเอาเข้า Formatter
                final itemTotal = double.tryParse(item['total_price']?.toString() ?? '0') ?? 0.0;
                final sharers = _itemSharers[index] ?? [];
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(itemName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🚀 ใช้ AppFormatters แสดงค่าเงิน
                        Text('ราคา: ${AppFormatters.formatCurrency(itemTotal)}'),
                        if (sharers.isNotEmpty)
                          Text(
                            'คนจ่าย: ${sharers.map((s) => s['user_name']).join(", ")}', 
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    trailing: OutlinedButton(
                      onPressed: () => _selectSharers(index),
                      child: const Text('เลือกคนจ่าย'),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            // 🚀 เรียกใช้ CustomButton 
            child: CustomButton(
              text: 'สรุปยอดและเคลียร์บิล',
              onPressed: () {
                if (_itemSharers.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('กรุณาเลือกคนจ่ายอย่างน้อย 1 รายการ')),
                  );
                  return;
                }

                // 🚀 ใช้ AppRoutes ยิงข้อมูลเข้าหน้า Summary
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.summary,
                  arguments: {
                    'lobbyId': widget.lobbyId,
                    'receiptData': widget.receiptData,
                    'itemSharers': _itemSharers,
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}