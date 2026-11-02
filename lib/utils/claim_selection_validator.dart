class ClaimSelectionValidator {
  const ClaimSelectionValidator._();

  static bool isComplete({
    required List<dynamic> items,
    required Map<int, Map<String, int>> claimedItems,
    required Map<int, Set<String>> sharedItems,
  }) {
    if (items.isEmpty) return false;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item is! Map) return false;

      final quantity =
          int.tryParse((item['qty'] ?? item['quantity'] ?? 1).toString()) ?? 1;
      if (quantity <= 0) return false;

      final personalQuantity = (claimedItems[index]?.values ?? const <int>[])
          .fold<int>(
            0,
            (total, value) => total + value.clamp(0, quantity).toInt(),
          );
      final sharedUsers = sharedItems[index] ?? const <String>{};

      // Shared selection covers every unit not assigned personally.
      if (personalQuantity < quantity && sharedUsers.isEmpty) return false;
    }

    return true;
  }
}
