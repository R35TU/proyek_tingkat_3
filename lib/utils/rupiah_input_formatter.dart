import 'package:flutter/services.dart';

/// Utility untuk format dan parsing mata uang Rupiah secara konsisten dan tangguh.
/// Mampu menangani:
/// - Input angka murni: '3000000000' -> 3000000000.0
/// - Format titik standar: '3.000.000.000' -> 3000000000.0
/// - Format desimal Indonesia: '288.350.326,79' -> 288350326.79
/// - Format dengan awalan 'Rp ': 'Rp 288.350.326,79' -> 288350326.79
/// - Keterangan tambahan: '3.000.000.000 (Termasuk PPN+PPH)' -> 3000000000.0
class RupiahUtil {
  /// Memisahkan digit dan memformatnya dengan pemisah ribuan titik (Indonesian format).
  /// Contoh: '3000000000' -> '3.000.000.000'
  static String formatDigits(String digits) {
    if (digits.isEmpty) return '';
    // Buang leading zero berlebih kecuali angka tunggal '0'
    String cleaned = digits;
    while (cleaned.length > 1 && cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  /// Format angka integer / double menjadi string berformat titik dan koma desimal Indonesia.
  /// Contoh:
  /// - 3000000000 -> '3.000.000.000'
  /// - 288350326.79 -> '288.350.326,79'
  static String formatNumber(
    num value, {
    bool allowDecimals = true,
    bool forceDecimals = false,
    int decimalDigits = 2,
  }) {
    if (value == 0) {
      return forceDecimals ? '0,00' : '0';
    }
    final isNegative = value < 0;
    final absVal = value.abs();
    final parts = absVal.toStringAsFixed(decimalDigits).split('.');
    final integerPart = parts[0];
    final formatted = formatDigits(integerPart);
    final decPart = parts.length > 1 ? parts[1] : '';

    String result;
    if (forceDecimals || (allowDecimals && decPart.isNotEmpty && decPart != '00')) {
      result = '$formatted,$decPart';
    } else {
      result = formatted;
    }
    return isNegative ? '-$result' : result;
  }

  /// Format string angka / kotor menjadi string berformat titik rapi dan koma desimal.
  /// Contoh:
  /// - '3000000000' -> '3.000.000.000'
  /// - '288.350.326,79' -> '288.350.326,79'
  /// - 'Rp 288.350.326,79' -> '288.350.326,79'
  static String formatString(String input, {bool allowDecimals = true}) {
    if (input.trim().isEmpty) return '';
    String clean = input.trim();
    if (clean.contains('(')) {
      clean = clean.split('(').first.trim();
    }
    clean = clean.replaceAll('Rp', '').replaceAll('rp', '').replaceAll(' ', '');
    if (clean.isEmpty) return '';

    // Jika mengandung koma desimal
    if (clean.contains(',')) {
      final parts = clean.split(',');
      final intPartDigits = parts[0].replaceAll(RegExp(r'[^\d]'), '');
      final formattedInt = formatDigits(intPartDigits.isEmpty ? '0' : intPartDigits);
      if (!allowDecimals) return formattedInt;
      final decPartDigits = parts.length > 1 ? parts.sublist(1).join('').replaceAll(RegExp(r'[^\d]'), '') : '';
      return decPartDigits.isNotEmpty ? '$formattedInt,$decPartDigits' : '$formattedInt,';
    }

    // Jika ada satu titik (.) dan 1-2 digit di belakangnya (bukan 3 digit ribuan)
    final dotCount = '.'.allMatches(clean).length;
    if (dotCount == 1) {
      final parts = clean.split('.');
      if (parts[1].length != 3 && RegExp(r'^\d+$').hasMatch(parts[0]) && RegExp(r'^\d+$').hasMatch(parts[1])) {
        final formattedInt = formatDigits(parts[0]);
        return allowDecimals ? '$formattedInt,${parts[1]}' : formattedInt;
      }
    }

    final numVal = parseToDouble(clean);
    if (numVal == 0.0 && !clean.contains('0')) return '';
    return formatNumber(numVal, allowDecimals: allowDecimals);
  }

  /// Format dengan awalan 'Rp '
  /// Contoh:
  /// - 3000000000 -> 'Rp 3.000.000.000'
  /// - 288350326.79 -> 'Rp 288.350.326,79'
  static String formatWithRp(
    num value, {
    bool allowDecimals = true,
    bool forceDecimals = false,
  }) {
    return 'Rp ${formatNumber(value, allowDecimals: allowDecimals, forceDecimals: forceDecimals)}';
  }

  /// Membulatkan nilai nominal ke bawah ke kelipatan Rp 1.000 terdekat (floor to nearest thousand).
  /// Sesuai format standar dokumen Dinas PU:
  /// Contoh:
  /// - 1234999.00 -> 1234000.0
  /// - 1234500.00 -> 1234000.0
  /// - 1234001.00 -> 1234000.0
  /// - 1999999.00 -> 1999000.0
  /// - 384550289.24 -> 384550000.0
  /// - 288350703.03 -> 288350000.0
  static double floorToNearestThousand(num value) {
    if (value <= 0) return 0.0;
    return (value / 1000.0).floorToDouble() * 1000.0;
  }

  /// Parsing teks apa pun ke dalam double secara aman dengan presisi penuh.
  /// Mengabaikan 'Rp', spasi, dan keterangan tambahan.
  /// Standar Indonesia: KOMA (,) adalah pemisah desimal, TITIK (.) adalah pemisah ribuan.
  static double parseToDouble(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;

    String clean = text.trim();

    // Buang teks keterangan dalam kurung seperti '(Termasuk PPN+PPH)'
    if (clean.contains('(')) {
      clean = clean.split('(').first.trim();
    }

    // Buang kata 'Rp', spasi, dsb.
    clean = clean.replaceAll('Rp', '').replaceAll('rp', '').replaceAll(' ', '');

    // 1. Format Indonesia: koma (,) adalah pemisah desimal
    if (clean.contains(',')) {
      final parts = clean.split(',');
      final integerPart = parts[0].replaceAll(RegExp(r'[^\d]'), '');
      final decimalPart = parts.length > 1
          ? parts.sublist(1).join('').replaceAll(RegExp(r'[^\d]'), '')
          : '';

      if (integerPart.isEmpty && decimalPart.isEmpty) return 0.0;
      final fullStr = decimalPart.isNotEmpty ? '$integerPart.$decimalPart' : integerPart;
      return double.tryParse(fullStr) ?? 0.0;
    }

    // 2. Jika ada satu titik (.) dan digit di belakangnya BUKAN 3 digit (misal: "100.5" atau "288350326.79")
    // Catatan: Jika 3 digit persis seperti "100.000" atau "288.350", itu adalah ribuan!
    final dotCount = '.'.allMatches(clean).length;
    if (dotCount == 1) {
      final parts = clean.split('.');
      if (parts[1].length != 3 &&
          RegExp(r'^\d+$').hasMatch(parts[0]) &&
          RegExp(r'^\d+$').hasMatch(parts[1])) {
        return double.tryParse(clean) ?? 0.0;
      }
    }

    // 3. Jika tidak ada koma dan bukan single-dot decimal, semua titik dianggap pemisah ribuan
    final digitsOnly = clean.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return 0.0;

    return double.tryParse(digitsOnly) ?? 0.0;
  }
}

/// TextInputFormatter cerdas yang memformat input angka menjadi format ribuan Rupiah secara otomatis saat diketik,
/// serta mendukung input angka desimal (koma) dengan presisi penuh.
class RupiahInputFormatter extends TextInputFormatter {
  final bool allowDecimals;
  final int maxDecimals;

  RupiahInputFormatter({this.allowDecimals = true, this.maxDecimals = 4});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Jika tidak memperbolehkan desimal, gunakan format murni bilangan bulat
    if (!allowDecimals) {
      final cursorPosition = newValue.selection.baseOffset;
      final textBeforeCursor = (cursorPosition >= 0 && cursorPosition <= newValue.text.length)
          ? newValue.text.substring(0, cursorPosition)
          : newValue.text;
      final digitsBeforeCursor = textBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;

      String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.isEmpty) {
        return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      }
      while (digitsOnly.length > 1 && digitsOnly.startsWith('0')) {
        digitsOnly = digitsOnly.substring(1);
      }
      final formatted = RupiahUtil.formatDigits(digitsOnly);

      int newCursorOffset = 0;
      int countedDigits = 0;
      for (int i = 0; i < formatted.length; i++) {
        if (RegExp(r'\d').hasMatch(formatted[i])) {
          countedDigits++;
        }
        if (countedDigits >= digitsBeforeCursor) {
          newCursorOffset = i + 1;
          break;
        }
      }
      if (digitsBeforeCursor == 0) {
        newCursorOffset = 0;
      } else if (newCursorOffset == 0 || countedDigits < digitsBeforeCursor) {
        newCursorOffset = formatted.length;
      }
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: newCursorOffset),
      );
    }

    // Mendukung Desimal Indonesia (koma ',')
    final text = newValue.text;
    final cursorPosition = newValue.selection.baseOffset;
    final textBeforeCursor = (cursorPosition >= 0 && cursorPosition <= text.length)
        ? text.substring(0, cursorPosition)
        : text;

    final hasComma = text.contains(',');
    final commaIndex = text.indexOf(',');
    final cursorInDecimal = hasComma && cursorPosition > commaIndex;

    String intPartRaw;
    String decPartRaw;

    if (hasComma) {
      final parts = text.split(',');
      intPartRaw = parts[0].replaceAll(RegExp(r'[^\d]'), '');
      decPartRaw = parts.length > 1
          ? parts.sublist(1).join('').replaceAll(RegExp(r'[^\d]'), '')
          : '';
      if (decPartRaw.length > maxDecimals) {
        decPartRaw = decPartRaw.substring(0, maxDecimals);
      }
    } else {
      intPartRaw = text.replaceAll(RegExp(r'[^\d]'), '');
      decPartRaw = '';
    }

    if (intPartRaw.isEmpty && decPartRaw.isEmpty && !hasComma) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    while (intPartRaw.length > 1 && intPartRaw.startsWith('0')) {
      intPartRaw = intPartRaw.substring(1);
    }

    final formattedInt = intPartRaw.isEmpty ? '0' : RupiahUtil.formatDigits(intPartRaw);
    final String formattedText = hasComma ? '$formattedInt,$decPartRaw' : formattedInt;

    // Perhitungan posisi kursor baru yang presisi
    int newCursorOffset = formattedText.length;
    if (!cursorInDecimal) {
      final intDigitsBeforeCursor = (hasComma ? textBeforeCursor.split(',')[0] : textBeforeCursor)
          .replaceAll(RegExp(r'[^\d]'), '')
          .length;

      int counted = 0;
      for (int i = 0; i < formattedInt.length; i++) {
        if (RegExp(r'\d').hasMatch(formattedInt[i])) {
          counted++;
        }
        if (counted >= intDigitsBeforeCursor) {
          newCursorOffset = i + 1;
          break;
        }
      }
      if (intDigitsBeforeCursor == 0) {
        newCursorOffset = 0;
      }
      if (hasComma && cursorPosition == commaIndex + 1 && textBeforeCursor.endsWith(',')) {
        newCursorOffset = formattedInt.length + 1;
      }
    } else {
      final decTextBeforeCursor = textBeforeCursor.substring(commaIndex + 1).replaceAll(RegExp(r'[^\d]'), '');
      newCursorOffset = formattedInt.length + 1 + decTextBeforeCursor.length;
    }

    if (newCursorOffset > formattedText.length) {
      newCursorOffset = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }
}
