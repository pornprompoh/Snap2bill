import 'package:intl/intl.dart';
import 'constants.dart';

class AppFormatters {
  // แปลงตัวเลขเป็นสกุลเงิน
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'th_TH');
    return '${formatter.format(amount)} ${AppConstants.currencySymbol}';
  }

  // แปลงวันที่และเวลา
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy HH:mm', 'th_TH');
    return formatter.format(date);
  }
}