import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrCompactFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static String format(double amount) {
    if (amount % 1 == 0) {
      return _inrCompactFormatter.format(amount);
    }
    return _inrFormatter.format(amount);
  }

  static String formatCompact(double amount) {
    return _inrCompactFormatter.format(amount);
  }
}
