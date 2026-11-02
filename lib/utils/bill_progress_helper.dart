import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'formatters.dart';

class BillParticipantStatus {
  final String id;
  final String name;
  final double amount;
  final bool isOwner;
  final bool isPaid;
  final bool isGuest;

  const BillParticipantStatus({
    required this.id,
    required this.name,
    required this.amount,
    required this.isOwner,
    required this.isPaid,
    required this.isGuest,
  });
}

class BillProgressSummary {
  final double totalAmount;
  final String shopName;
  final String ownerId;
  final int totalMembers;
  final int totalPayingCount;
  final int paidCount;
  final int unpaidCount;
  final int percentage; // 0 to 100
  final double averagePerPerson;
  final double? equalPerPerson;
  final bool isEqualSplit;
  final bool isSettled;
  final List<BillParticipantStatus> unpaidMembers;
  final List<BillParticipantStatus> allMembers;

  const BillProgressSummary({
    required this.totalAmount,
    required this.shopName,
    required this.ownerId,
    required this.totalMembers,
    required this.totalPayingCount,
    required this.paidCount,
    required this.unpaidCount,
    required this.percentage,
    required this.averagePerPerson,
    this.equalPerPerson,
    this.isEqualSplit = false,
    required this.isSettled,
    required this.unpaidMembers,
    required this.allMembers,
  });

  String get progressPercentageText => 'เก็บเงินแล้ว $percentage%';

  String get paidCountText => unpaidCount == 0 && totalPayingCount > 0
      ? 'จ่ายครบแล้ว $totalPayingCount/$totalPayingCount คน'
      : 'จ่ายแล้ว $paidCount/$totalPayingCount คน';

  String get waitingText =>
      unpaidCount > 0 ? 'รออีก $unpaidCount คน' : 'ครบแล้ว 🎉';

  String get formattedAverage => equalPerPerson != null
      ? AppFormatters.formatCurrency(equalPerPerson!)
      : AppFormatters.formatCurrency(averagePerPerson);
}

class BillProgressHelper {
  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String && value.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return {};
  }

  static double extractBillTotal(Map<String, dynamic> bill) {
    final receipt = _asMap(bill['receipt_json']);
    final candidates = [
      bill['total_amount'],
      bill['sub_total'],
      receipt['final_total'],
      receipt['total_amount'],
      receipt['sub_total'],
    ];
    for (final c in candidates) {
      if (c != null) {
        final val = double.tryParse(c.toString()) ?? 0.0;
        if (val > 0) return val;
      }
    }

    // Fallback: sum up items inside receipt_json['items']
    final items = receipt['items'];
    if (items is List) {
      double itemsSum = 0.0;
      for (final it in items) {
        if (it is Map) {
          final qty =
              int.tryParse((it['qty'] ?? it['quantity'] ?? 1).toString()) ?? 1;
          final price =
              double.tryParse(
                (it['unit_price'] ?? it['price'] ?? 0).toString(),
              ) ??
              0.0;
          final total =
              double.tryParse((it['total_price'] ?? '').toString()) ??
              (qty * price);
          itemsSum += total;
        }
      }
      if (itemsSum > 0) return itemsSum;
    }

    // Fallback: sum bill_participants amounts
    final rawParticipants = bill['bill_participants'];
    if (rawParticipants is List) {
      double participantsSum = 0.0;
      for (final p in rawParticipants) {
        if (p is Map) {
          final owed =
              double.tryParse(p['amount_owed']?.toString() ?? '') ?? 0.0;
          participantsSum += owed;
        }
      }
      if (participantsSum > 0) return participantsSum;
    }

    return 0.0;
  }

  static String extractShopName(Map<String, dynamic> bill) {
    final receipt = _asMap(bill['receipt_json']);
    final name =
        bill['shop_name']?.toString() ?? receipt['shop_name']?.toString();
    if (name != null && name.trim().isNotEmpty && name.trim() != 'null') {
      return name.trim();
    }
    return 'ไม่ระบุชื่อร้าน';
  }

  static String extractOwnerId(Map<String, dynamic> bill) {
    final receipt = _asMap(bill['receipt_json']);
    final ownerId =
        bill['owner_id']?.toString() ??
        bill['user_id']?.toString() ??
        receipt['owner_id']?.toString();
    return ownerId ?? '';
  }

  static BillProgressSummary calculate(Map<String, dynamic> bill) {
    final totalAmount = extractBillTotal(bill);
    final shopName = extractShopName(bill);
    final ownerId = extractOwnerId(bill);

    final receipt = _asMap(bill['receipt_json']);
    final sharersJson = _asMap(bill['sharers_json']);
    final paidStatuses = _asMap(receipt['paid_statuses']);

    // Collect all participant IDs
    final memberIds = <String>{};
    if (ownerId.isNotEmpty) {
      memberIds.add(ownerId);
    }

    // 1. From bill_participants table relation
    final rawParticipants = bill['bill_participants'];
    final participantsList = rawParticipants is List ? rawParticipants : [];
    final participantMap = <String, Map<String, dynamic>>{};
    for (final p in participantsList) {
      if (p is Map) {
        final pid =
            p['profile_id']?.toString() ??
            p['friend_id']?.toString() ??
            p['id']?.toString();
        if (pid != null && pid.isNotEmpty) {
          memberIds.add(pid);
          participantMap[pid] = Map<String, dynamic>.from(p);
        }
      }
    }

    // 2. From paid_statuses in receipt_json (e.g. guests)
    for (final gid in paidStatuses.keys) {
      if (gid.isNotEmpty) memberIds.add(gid);
    }

    // 3. From items userQuantities / sharedUsers
    final items = receipt['items'];
    if (items is List) {
      for (final it in items) {
        if (it is Map) {
          final uq = it['user_quantities'] ?? it['userQuantities'];
          if (uq is Map) {
            for (final k in uq.keys) {
              if (k != null && k.toString().isNotEmpty) {
                memberIds.add(k.toString());
              }
            }
          }
          final su = it['shared_users'] ?? it['sharedUsers'];
          if (su is Iterable) {
            for (final u in su) {
              if (u != null && u.toString().isNotEmpty) {
                memberIds.add(u.toString());
              }
            }
          }
        }
      }
    }

    // 4. From sharers_json
    for (final entry in sharersJson.entries) {
      final val = entry.value;
      if (val is Iterable) {
        for (final s in val) {
          if (s is Map) {
            final sid =
                s['id']?.toString() ??
                s['userId']?.toString() ??
                s['user_id']?.toString();
            if (sid != null && sid.isNotEmpty) memberIds.add(sid);
          } else if (s is String && s.isNotEmpty) {
            memberIds.add(s);
          }
        }
      }
    }

    // Build participant status objects
    final allMembers = <BillParticipantStatus>[];
    final memberNames = <String, String>{};

    // Extract names from sharers_json if available
    for (final entry in sharersJson.entries) {
      final val = entry.value;
      if (val is Iterable) {
        for (final s in val) {
          if (s is Map) {
            final sid =
                s['id']?.toString() ??
                s['userId']?.toString() ??
                s['user_id']?.toString();
            final sname =
                s['name']?.toString() ??
                s['displayName']?.toString() ??
                s['user_name']?.toString();
            if (sid != null && sname != null && sname.isNotEmpty) {
              memberNames[sid] = sname;
            }
          }
        }
      }
    }

    final totalMembers = memberIds.isEmpty
        ? (ownerId.isNotEmpty ? 1 : 0)
        : memberIds.length;
    final averagePerPerson = totalMembers > 0
        ? totalAmount / totalMembers
        : totalAmount;

    String currentUserId = '';
    String currentEmailPrefix = '';
    try {
      final currentAuthUser = Supabase.instance.client.auth.currentUser;
      currentUserId = currentAuthUser?.id ?? '';
      currentEmailPrefix = currentAuthUser?.email?.split('@').first ?? '';
    } catch (_) {}

    for (final mid in memberIds) {
      final isOwner =
          (ownerId.isNotEmpty && mid == ownerId) ||
          (currentUserId.isNotEmpty &&
              mid == currentUserId &&
              (ownerId.isEmpty || ownerId == currentUserId)) ||
          (currentEmailPrefix.isNotEmpty &&
              mid == currentEmailPrefix &&
              (ownerId.isEmpty || ownerId == currentUserId));
      final isGuest = mid.startsWith('guest_');

      // Determine payment status
      bool isPaid = false;
      if (isOwner) {
        isPaid = true; // Owner is not a debtor to themselves
      } else if (paidStatuses.containsKey(mid)) {
        isPaid = paidStatuses[mid]?.toString().toLowerCase() == 'paid';
      } else if (participantMap.containsKey(mid)) {
        final status = participantMap[mid]?['status']?.toString().toLowerCase();
        isPaid = status == 'paid';
      }

      // Determine amount owed
      double amount = 0.0;
      if (participantMap.containsKey(mid)) {
        amount =
            double.tryParse(
              participantMap[mid]?['amount_owed']?.toString() ?? '0',
            ) ??
            0.0;
      }
      if (amount <= 0.0) {
        amount = averagePerPerson;
      }

      final name =
          memberNames[mid] ??
          (isOwner ? 'เจ้าของบิล' : (isGuest ? 'เพื่อน (Guest)' : 'เพื่อน'));

      allMembers.add(
        BillParticipantStatus(
          id: mid,
          name: name,
          amount: amount,
          isOwner: isOwner,
          isPaid: isPaid,
          isGuest: isGuest,
        ),
      );
    }

    // Calculate paying members (excluding owner)
    final payingMembers = allMembers.where((m) => !m.isOwner).toList();
    final totalPayingCount = payingMembers.length;
    final paidCount = payingMembers.where((m) => m.isPaid).length;
    final unpaidCount = totalPayingCount - paidCount;

    // Requirement 2:
    // เปอร์เซ็นต์ความคืบหน้า = (จำนวนผู้เข้าร่วมที่ชำระเงินแล้ว ÷ จำนวนผู้เข้าร่วมทั้งหมดที่ไม่รวมเจ้าของ) × 100
    // หากสร้างบิลใหม่และยังไม่มีใครชำระเงิน ให้แสดง 0%
    final int percentage;
    if (totalPayingCount == 0) {
      // ยังไม่มีผู้ต้องชำระ: ห้ามนับเป็นสำเร็จ ให้อยู่แท็บ "ยังไม่ครบ" (0%)
      percentage = 0;
    } else {
      percentage = ((paidCount / totalPayingCount) * 100).round();
    }

    // Requirement 4:
    // หากผู้เข้าร่วมทุกคนมียอดเงินที่ต้องชำระเท่ากัน ให้แสดงข้อความ "ตกคนละ X บาท"
    // หากผู้เข้าร่วมแต่ละคนมียอดเงินไม่เท่ากัน ไม่ต้องแสดงข้อความยอดเฉลี่ยต่อคน
    // ตรวจสอบความเท่ากันของยอดเงินก่อนปัดเศษ เพื่อไม่ให้ยอดที่แตกต่างกันถูกแสดงเป็นยอดเดียวกันโดยไม่ถูกต้อง
    bool isEqualSplit = false;
    double? equalPerPerson;
    if (allMembers.length > 1) {
      final firstRawAmount = allMembers.first.amount;
      final allEqual = allMembers.every(
        (m) => (m.amount - firstRawAmount).abs() < 0.01,
      );
      if (allEqual && firstRawAmount > 0) {
        isEqualSplit = true;
        equalPerPerson = firstRawAmount.ceilToDouble();
      }
    } else if (allMembers.length == 1 && allMembers.first.amount > 0) {
      isEqualSplit = true;
      equalPerPerson = allMembers.first.amount.ceilToDouble();
    }

    // Requirement 1:
    // หากยังมีผู้เข้าร่วมค้างชำระอยู่ (unpaidCount > 0) ต้องไม่แสดงบิลในแท็บ "สำเร็จ" โดยเด็ดขาด
    // สำเร็จ (Completed): แสดงเฉพาะบิลที่ผู้เข้าร่วมทุกคนชำระเงินครบถ้วนแล้ว (unpaidCount == 0)
    final bool isSettled;
    // บิลใหม่ (ยังไม่มีผู้ชำระ) ต้องอยู่ "ยังไม่ครบ" เสมอ จนกว่าผู้เข้าร่วมทุกคนจ่ายครบ
    isSettled = totalPayingCount > 0 && unpaidCount == 0;

    final unpaidMembers = payingMembers.where((m) => !m.isPaid).toList();

    return BillProgressSummary(
      totalAmount: totalAmount,
      shopName: shopName,
      ownerId: ownerId,
      totalMembers: totalMembers,
      totalPayingCount: totalPayingCount,
      paidCount: paidCount,
      unpaidCount: unpaidCount,
      percentage: percentage,
      averagePerPerson: averagePerPerson,
      equalPerPerson: equalPerPerson,
      isEqualSplit: isEqualSplit,
      isSettled: isSettled,
      unpaidMembers: unpaidMembers,
      allMembers: allMembers,
    );
  }
}
