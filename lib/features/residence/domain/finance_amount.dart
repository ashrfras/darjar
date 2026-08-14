import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Accepts monetary values with up to two decimal places.
///
/// Both separators commonly available on Arabic and Latin keyboards are
/// supported. The value is normalized before it is parsed.
final TextInputFormatter financeAmountInputFormatter =
    TextInputFormatter.withFunction((oldValue, newValue) {
      final isValid = RegExp(
        r'^\d*(?:[.,٫]\d{0,2})?$',
      ).hasMatch(newValue.text);
      return isValid ? newValue : oldValue;
    });

num? parseFinanceAmount(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'[,٫]'), '.');
  return num.tryParse(normalized);
}

String formatFinanceAmountForInput(num amount) {
  if (amount == amount.roundToDouble()) return amount.toInt().toString();
  return NumberFormat('0.##', 'en').format(amount);
}

String formatFinanceAmount(num amount, String locale) {
  final formatter = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 2;
  return formatter.format(amount);
}
