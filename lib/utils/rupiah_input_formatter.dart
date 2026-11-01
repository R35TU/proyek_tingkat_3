import 'package:flutter/services.dart';

/// Utility untuk format dan parsing mata uang Rupiah secara konsisten dan tangguh.
/// Mampu menangani:
/// - Input angka murni: '3000000000' -> 3000000000.0
/// - Format titik standar: '3.000.000.000' -> 3000000000.0
/// - Format acak / salah ketik titik: '3.00.00.00.00.0' -> 3000000000.0
/// - Format dengan awalan 'Rp ': 'Rp 3.000.000.000,00' -> 3000000000.0
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

  /// Format angka integer / double menjadi string berformat titik.
  /// Contoh: 3000000000 -> '3.000.000.000'
  static String formatNumber(num value) {
    final integerPart = value.toInt().abs().toString();
    final formatted = formatDigits(integerPart);
    return value < 0 ? '-$formatted' : formatted;
  }

  /// Format string angka / kotor menjadi string berformat titik rapi.
  /// Contoh: '3000000000' -> '3.000.000.000'
  /// '3.00.00.00.00.0' -> '3.000.000.000'
  /// 'Rp 3.000.000.000,00' -> '3.000.000.000'
  static String formatString(String input) {
    if (input.trim().isEmpty) return '';
    final numVal = parseToDouble(input);
    if (numVal == 0.0 && !input.contains('0')) return '';
    return formatNumber(numVal);
  }

  /// Format dengan awalan 'Rp '
  /// Contoh: 3000000000 -> 'Rp 3.000.000.000'
  static String formatWithRp(num value) {
    return 'Rp ${formatNumber(value)}';
  }

  /// Parsing teks apa pun ke dalam double secara aman.
  /// Mengabaikan 'Rp', spasi, titik yang salah tempat, dan keterangan tambahan.
  static double parseToDouble(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;

    String clean = text.trim();

    // Buang teks keterangan dalam kurung seperti '(Termasuk PPN+PPH)'
    if (clean.contains('(')) {
      clean = clean.split('(').first.trim();
    }

    // Buang kata 'Rp', spasi, dsb.
    clean = clean.replaceAll('Rp', '').replaceAll('rp', '').replaceAll(' ', '');

    // Jika mengandung desimal Indonesia dengan koma (,00 atau ,50)
    if (clean.contains(',')) {
      final parts = clean.split(',');
      final integerPart = parts[0].replaceAll(RegExp(r'[^\d]'), '');
      String decimalPart = parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^\d]'), '') : '';
      if (decimalPart.length > 2) {
        decimalPart = decimalPart.substring(0, 2);
      }

      if (integerPart.isEmpty && decimalPart.isEmpty) return 0.0;
      final fullStr = decimalPart.isNotEmpty ? '$integerPart.$decimalPart' : integerPart;
      return double.tryParse(fullStr) ?? 0.0;
    }

    // Jika tidak ada koma, buang semua karakter non-digit (termasuk titik acak)
    final digitsOnly = clean.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return 0.0;

    return double.tryParse(digitsOnly) ?? 0.0;
  }
}

/// TextInputFormatter cerdas yang memformat input angka menjadi format ribuan Rupiah secara otomatis saat diketik.
/// - Menghapus titik acak (contoh user copas '3.00.00.00.00.0' langsung jadi '3.000.000.000')
/// - Otomatis menyisipkan titik ribuan tiap 3 digit
/// - Menjaga posisi kursor tetap akurat saat mengetik atau menghapus di tengah teks
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Hitung berapa digit angka murni yang berada sebelum kursor pengguna saat ini
    final cursorPosition = newValue.selection.baseOffset;
    final textBeforeCursor = (cursorPosition >= 0 && cursorPosition <= newValue.text.length)
        ? newValue.text.substring(0, cursorPosition)
        : newValue.text;
    final digitsBeforeCursor = textBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;

    // Bersihkan semua karakter non-digit
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Buang leading zeros yang berlebihan
    while (digitsOnly.length > 1 && digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }

    // Format angka ke format titik ribuan
    final formatted = RupiahUtil.formatDigits(digitsOnly);

    // Hitung posisi kursor baru agar tetap berada tepat setelah digit yang baru diketik
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
}
