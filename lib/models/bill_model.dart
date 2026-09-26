class BillModel {
  final String id;
  final String ownerId;
  final String? shopName;
  final String? receiptDate;
  final double subTotal;
  final double vatAmount;
  final double serviceCharge;
  final double totalAmount;
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
    this.receiptImageUrl,
    this.status = 'draft',
  });

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      shopName: json['shop_name'] as String?,
      receiptDate: json['receipt_date'] as String?,
      subTotal: (json['sub_total'] ?? 0).toDouble(),
      vatAmount: (json['vat_amount'] ?? 0).toDouble(),
      serviceCharge: (json['service_charge'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      receiptImageUrl: json['receipt_image_url'] as String?,
      status: json['status'] as String? ?? 'draft',
    );
  }
}

class BillItemModel {
  final String id;
  final String billId;
  final String itemName;
  final double price;
  final int quantity;
  final double? totalPrice;

  BillItemModel({
    required this.id,
    required this.billId,
    required this.itemName,
    required this.price,
    this.quantity = 1,
    this.totalPrice,
  });

  factory BillItemModel.fromJson(Map<String, dynamic> json) {
    return BillItemModel(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      itemName: json['item_name'] as String,
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      totalPrice: json['total_price'] != null ? (json['total_price']).toDouble() : null,
    );
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