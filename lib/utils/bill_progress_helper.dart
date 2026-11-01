import 'dart:convert';
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
    required this.isSettled,
    required this.unpaidMembers,
    required this.allMembers,
  });

  String get progressPercentageText => 'เก็บเงินแล้ว $percentage%';

  String get paidCountText => unpaidCount == 0 && totalPayingCount > 0
      ? 'จ่ายครบแล้ว $totalPayingCount/$totalPayingCount คน'
      : 'จ่ายแล้ว $paidCount/$totalPayingCount คน';

  String get waitingText => unpaidCount > 0 ? 'รออีก $unpaidCount คน' : 'ครบแล้ว 🎉';

  String get formattedAverage => AppFormatters.formatCurrency(averagePerPerson);
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
    return 0.0;
  }

  static String extractShopName(Map<String, dynamic> bill) {
    final receipt = _asMap(bill['receipt_json']);
    final name = bill['shop_name']?.toString() ?? receipt['shop_name']?.toString();
    if (name != null && name.trim().isNotEmpty && name.trim() != 'null') {
      return name.trim();
    }
    return 'ไม่ระบุชื่อร้าน';
  }

  static String extractOwnerId(Map<String, dynamic> bill) {
    final receipt = _asMap(bill['receipt_json']);
    final ownerId = bill['owner_id']?.toString() ??
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
        final pid = p['profile_id']?.toString() ?? p['friend_id']?.toString() ?? p['id']?.toString();
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
              if (k != null && k.toString().isNotEmpty) memberIds.add(k.toString());
            }
          }
          final su = it['shared_users'] ?? it['sharedUsers'];
          if (su is Iterable) {
            for (final u in su) {
              if (u != null && u.toString().isNotEmpty) memberIds.add(u.toString());
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
            final sid = s['id']?.toString() ?? s['userId']?.toString();
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
            final sid = s['id']?.toString() ?? s['userId']?.toString();
            final sname = s['name']?.toString() ?? s['displayName']?.toString();
            if (sid != null && sname != null && sname.isNotEmpty) {
              memberNames[sid] = sname;
            }
          }
        }
      }
    }

    final totalMembers = memberIds.isEmpty ? (ownerId.isNotEmpty ? 1 : 0) : memberIds.length;
    final averagePerPerson = totalMembers > 0 ? (totalAmount / totalMembers) : totalAmount;

    for (final mid in memberIds) {
      final isOwner = ownerId.isNotEmpty && mid == ownerId;
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
        amount = double.tryParse(participantMap[mid]?['amount_owed']?.toString() ?? '0') ?? 0.0;
      }
      if (amount <= 0.0) {
        amount = averagePerPerson;
      }

      final name = memberNames[mid] ??
          (isOwner
              ? 'เจ้าของบิล'
              : (isGuest ? 'เพื่อน (Guest)' : 'เพื่อน'));

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

    final int percentage;
    if (totalPayingCount == 0) {
      // Solo bill or no other paying members
      percentage = 100;
    } else {
      percentage = ((paidCount / totalPayingCount) * 100).round();
    }

    final billStatus = bill['status']?.toString().toLowerCase() ?? '';
    final isExplicitlyCompleted = {'completed', 'paid', 'settled', 'cleared'}.contains(billStatus);
    final isSettled = totalPayingCount == 0 || (totalPayingCount > 0 && unpaidCount == 0) || isExplicitlyCompleted;

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
      isSettled: isSettled,
      unpaidMembers: unpaidMembers,
      allMembers: allMembers,
    );
  }
}
