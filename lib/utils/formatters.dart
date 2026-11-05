import 'package:intl/intl.dart';
import 'constants.dart';

class AppFormatters {
  /// แปลงตัวเลขเป็นสกุลเงิน: ปัดเศษขึ้นเป็นจำนวนเต็มเสมอ (Round Up / Ceiling)
  /// และไม่แสดงทศนิยมในทุกหน้าจอตามเงื่อนไข Requirement 5
  static String formatCurrency(double amount) {
    if (amount.isNaN || amount.isInfinite) return '0 ${AppConstants.currencySymbol}';
    final int ceilAmount = amount.ceil();
    final formatter = NumberFormat('#,##0', 'th_TH');
    return '${formatter.format(ceilAmount)} ${AppConstants.currencySymbol}';
  }

  /// แปลงวันที่และเวลา
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy HH:mm', 'th_TH');
    return formatter.format(date);
  }
}
