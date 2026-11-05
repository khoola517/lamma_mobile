import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat('#,###', 'en_US');

  /// Formats amount in Yemeni Rial: e.g. 450000 -> "450,000 ر.ي"
  static String formatYer(num amount) {
    return '${_formatter.format(amount)} ر.ي';
  }

  /// Formats amount in USD: e.g. 470 -> "$470"
  static String formatUsd(num amount) {
    return '\$${_formatter.format(amount)}';
  }
}
