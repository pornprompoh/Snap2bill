class PromptPayHelper {
  static String _tlv(String tag, String value) {
    return '$tag${value.length.toString().padLeft(2, '0')}$value';
  }

  static String calculateCRC16(String payload) {
    int crc = 0xFFFF;
    for (int i = 0; i < payload.length; i++) {
      crc ^= (payload.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc = crc << 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  static bool isValidTarget(String target) {
    final clean = target.replaceAll(RegExp(r'[^0-9]'), '');
    return (clean.length == 10 && clean.startsWith('0')) || clean.length == 13;
  }

  /// Masks a PromptPay target number for display privacy
  /// e.g. Phone: 081-xxx-5678, National ID: 1-xxxx-xxxxx-12-3
  static String maskPromptPay(String target) {
    final clean = target.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 3)}-xxx-${clean.substring(6)}';
    } else if (clean.length == 13) {
      return '${clean.substring(0, 1)}-xxxx-xxxxx-${clean.substring(10, 12)}-${clean.substring(12)}';
    }
    return target;
  }

  static String generatePayload(String target, {double? amount, String? targetType}) {
    final cleanTarget = target.replaceAll(RegExp(r'[^0-9]'), '');
    late final String proxyField;

    if (targetType == 'phone' && cleanTarget.length == 10 && cleanTarget.startsWith('0')) {
      proxyField = _tlv('01', '0066${cleanTarget.substring(1)}');
    } else if (targetType == 'id_card' && cleanTarget.length == 13) {
      proxyField = _tlv('02', cleanTarget);
    } else if (cleanTarget.length == 10 && cleanTarget.startsWith('0')) {
      proxyField = _tlv('01', '0066${cleanTarget.substring(1)}');
    } else if (cleanTarget.length == 13) {
      proxyField = _tlv('02', cleanTarget);
    } else {
      return '';
    }

    final merchantAccountInfo = _tlv(
      '29',
      _tlv('00', 'A000000677010111') + proxyField,
    );

    final amountField = amount != null && amount > 0
        ? _tlv('54', amount.toStringAsFixed(2))
        : '';

    final payload =
        '000201'
        '${_tlv('01', amount != null && amount > 0 ? '12' : '11')}'
        '$merchantAccountInfo'
        '${_tlv('52', '0000')}'
        '${_tlv('53', '764')}'
        '$amountField'
        '${_tlv('58', 'TH')}'
        '6304';

    return '$payload${calculateCRC16(payload)}';
  }
}

