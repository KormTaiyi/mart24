import 'package:flutter/services.dart';

class PriceInputUtils {
  PriceInputUtils._();

  static final TextInputFormatter decimalFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final String sanitized = sanitizeDecimal(newValue.text);
        return TextEditingValue(
          text: sanitized,
          selection: TextSelection.collapsed(offset: sanitized.length),
        );
      });

  static String sanitizeDecimal(String value, {int maxDecimalPlaces = 2}) {
    final StringBuffer buffer = StringBuffer();
    bool hasDecimalPoint = false;

    for (final int codeUnit in value.codeUnits) {
      final bool isDigit = codeUnit >= 48 && codeUnit <= 57;
      final bool isDot = codeUnit == 46;

      if (isDigit) {
        buffer.writeCharCode(codeUnit);
        continue;
      }

      if (isDot && !hasDecimalPoint) {
        if (buffer.isEmpty) {
          continue;
        }
        buffer.write('.');
        hasDecimalPoint = true;
      }
    }

    final String sanitized = buffer.toString();
    if (!sanitized.contains('.') || maxDecimalPlaces < 0) {
      return sanitized;
    }

    final List<String> parts = sanitized.split('.');
    final String decimals = parts.length > 1 ? parts[1] : '';
    if (decimals.length <= maxDecimalPlaces) {
      return sanitized;
    }

    return '${parts[0]}.${decimals.substring(0, maxDecimalPlaces)}';
  }

  static double? tryParseNumber(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  static String? validateNumberRequired(
    String? value, {
    String requiredMessage = 'Price is required',
    String invalidMessage = 'Enter numbers only',
  }) {
    final double? parsed = tryParseNumber(value);
    if (value == null || value.trim().isEmpty) {
      return requiredMessage;
    }
    if (parsed == null) {
      return invalidMessage;
    }
    return null;
  }

  static String? validatePositiveRequired(
    String? value, {
    String requiredMessage = 'Price is required',
    String invalidMessage = 'Price must be greater than 0',
  }) {
    final double? parsed = tryParseNumber(value);
    if (value == null || value.trim().isEmpty) {
      return requiredMessage;
    }
    if (parsed == null || parsed <= 0) {
      return invalidMessage;
    }
    return null;
  }
}
