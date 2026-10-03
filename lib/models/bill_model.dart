class BillModel {
  final String id;
  final String ownerId;
  final String? shopName;
  final String? receiptDate;
  final double subTotal;
  final double vatAmount;
  final double serviceCharge;
  final double totalAmount;
  final double finalTotal;
  final String splitType;
  final String? receiptImageUrl;
  final String status;

  BillModel({
    required this.id,
    required this.ownerId,
    this.shopName,
    this.receiptDate,
    this.subTotal = 0.0,
    this.vatAmount = 0.0,
    this.serviceCharge = 0.0,
    this.totalAmount = 0.0,
    this.finalTotal = 0.0,
    this.splitType = 'proportional',
    this.receiptImageUrl,
    this.status = 'draft',
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      shopName: json['shop_name'] as String?,
      receiptDate: json['receipt_date'] as String?,
      subTotal: _asDouble(json['sub_total']),
      vatAmount: _asDouble(json['vat_amount']),
      serviceCharge: _asDouble(json['service_charge']),
      totalAmount: _asDouble(json['total_amount'] ?? json['final_total']),
      finalTotal: _asDouble(json['final_total'] ?? json['total_amount']),
      splitType: json['split_type'] == 'equal' ? 'equal' : 'proportional',
      receiptImageUrl: json['receipt_image_url'] as String?,
      status: json['status'] as String? ?? 'draft',
    );
  }

  Map<String, dynamic> toJson() {
    final serializedFinalTotal = finalTotal == 0 && totalAmount != 0
        ? totalAmount
        : finalTotal;
    return {
      'id': id,
      'owner_id': ownerId,
      'shop_name': shopName,
      'receipt_date': receiptDate,
      'sub_total': subTotal,
      'vat_amount': vatAmount,
      'service_charge': serviceCharge,
      'total_amount': serializedFinalTotal,
      'final_total': serializedFinalTotal,
      'split_type': splitType,
      'receipt_image_url': receiptImageUrl,
      'status': status,
    };
  }
}

double _asDouble(Object? value) =>
    value == null ? 0 : double.tryParse(value.toString()) ?? 0;

class BillItemModel {
  final String id;
  final String billId;
  final String itemName;
  final double price;
  final int quantity;
  final double? totalPrice;
  final List<String> claimedBy;
  final Map<String, int> userQuantities;
  final List<String> sharedUsers;

  BillItemModel({
    required this.id,
    required this.billId,
    required this.itemName,
    required this.price,
    this.quantity = 1,
    this.totalPrice,
    this.claimedBy = const [],
    this.userQuantities = const {},
    this.sharedUsers = const [],
  });

  factory BillItemModel.fromJson(Map<String, dynamic> json) {
    final claimedByData = json['claimed_by'];
    final claimsData = json['claims'] ?? json['user_quantities'];
    final legacyClaimedBy = switch (claimedByData) {
      final String userId => [userId],
      final List<dynamic> userIds =>
        userIds.map((userId) => userId.toString()).toList(),
      _ => <String>[],
    };
    final userQuantities = <String, int>{};
    final rawClaims = claimsData ?? (claimedByData is Map ? claimedByData : null);
    if (rawClaims is Map) {
      rawClaims.forEach((userId, count) {
        final quantity = int.tryParse(count.toString()) ?? 0;
        if (quantity > 0) userQuantities[userId.toString()] = quantity;
      });
    } else if (rawClaims is List) {
      for (final userId in rawClaims) {
        userQuantities[userId.toString()] = 1;
      }
    } else if (rawClaims is String && rawClaims.isNotEmpty) {
      userQuantities[rawClaims] = 1;
    } else {
      for (final userId in legacyClaimedBy) {
        userQuantities[userId] = 1;
      }
    }

    final rawSharedUsers = json['shared_claims'] ?? json['shared_users'];
    final sharedUsers = switch (rawSharedUsers) {
      final String userId when userId.isNotEmpty => [userId],
      final List<dynamic> userIds =>
        userIds.map((userId) => userId.toString()).toSet().toList(),
      _ => <String>[],
    };

    return BillItemModel(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      itemName: json['item_name'] as String,
      price: (json['price'] ?? 0).toDouble(),
      quantity: int.tryParse(
            (json['quantity'] ?? json['qty'] ?? 1).toString(),
          ) ??
          1,
      totalPrice: json['total_price'] != null
          ? _asDouble(json['total_price'])
          : null,
      claimedBy: legacyClaimedBy.isNotEmpty
          ? legacyClaimedBy
          : userQuantities.keys.toList(),
      userQuantities: userQuantities,
      sharedUsers: sharedUsers,
    );
  }

  Map<String, dynamic> toJson() {
    final allClaimants = {
      ...userQuantities.keys,
      ...sharedUsers,
      ...claimedBy,
    };
    return {
      'id': id,
      'bill_id': billId,
      'item_name': itemName,
      'price': price,
      'quantity': quantity,
      'total_price': totalPrice,
      'claims': userQuantities,
      'shared_claims': sharedUsers,
      'claimed_by': allClaimants.toList(),
    };
  }
}

class BillParticipantModel {
  final String id;
  final String billId;
  final String? profileId;
  final String? friendId;
  final double amountOwed;
  final String status;

  BillParticipantModel({
    required this.id,
    required this.billId,
    this.profileId,
    this.friendId,
    this.amountOwed = 0.0,
    this.status = 'pending',
  });

  factory BillParticipantModel.fromJson(Map<String, dynamic> json) {
    return BillParticipantModel(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      profileId: json['profile_id'] as String?,
      friendId: json['friend_id'] as String?,
      amountOwed: (json['amount_owed'] ?? 0).toDouble(),
      status: json['status'] as String? ?? 'pending',
    );
  }
}