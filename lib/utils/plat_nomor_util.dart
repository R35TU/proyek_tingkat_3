/// Utility untuk normalisasi plat nomor kendaraan dan kalkulasi waktu/suhu perjalanan dump truck (DT).
class PlatNomorUtil {
  /// Membersihkan dan menstandarkan format plat nomor Indonesia.
  /// Contoh: "r1234dt", "R-1234-DT", "r 1234 dt" -> "R 1234 DT"
  static String normalize(String raw) {
    if (raw.trim().isEmpty) return '';
    String clean = raw.trim().toUpperCase().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ');
    final regex = RegExp(r'^([A-Z]{1,2})\s*([0-9]{1,5})\s*([A-Z]{0,3})$');
    final match = regex.firstMatch(clean);
    if (match != null) {
      final prefix = match.group(1)!;
      final number = match.group(2)!;
      final suffix = match.group(3) ?? '';
      return suffix.isNotEmpty ? '$prefix $number $suffix' : '$prefix $number';
    }
    return clean;
  }

  /// Memecah plat nomor menjadi 3 bagian sesuai format dokumen resmi dinas:
  /// - [prefix]: Huruf wilayah depan (misal: "R", "AB", "G")
  /// - [number]: Angka plat (misal: "8076", "1234")
  /// - [suffix]: Huruf seri belakang (misal: "OE", "FM", "CL")
  static Map<String, String> split(String raw) {
    final clean = normalize(raw);
    final regex = RegExp(r'^([A-Z]{1,2})\s*([0-9]{1,5})\s*([A-Z]{0,3})$');
    final match = regex.firstMatch(clean);
    if (match != null) {
      return {
        'prefix': match.group(1) ?? '',
        'number': match.group(2) ?? '',
        'suffix': match.group(3) ?? '',
      };
    }
    final parts = clean.split(' ');
    return {
      'prefix': parts.isNotEmpty ? parts[0] : '',
      'number': parts.length > 1 ? parts[1] : '',
      'suffix': parts.length > 2 ? parts.sublist(2).join(' ') : '',
    };
  }

  /// Menghitung selisih waktu antara dua jam (HH:mm) dalam satuan desimal jam.
  /// Contoh: 09:21 ke 11:00 = 99 menit / 60 = 1.650 jam.
  static double calcHourDiff(String startTime, String endTime) {
    if (startTime.trim().isEmpty || endTime.trim().isEmpty) return 0.0;
    final matchStart = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(startTime);
    final matchEnd = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(endTime);
    if (matchStart == null || matchEnd == null) return 0.0;

    final h1 = int.parse(matchStart.group(1)!);
    final m1 = int.parse(matchStart.group(2)!);
    final h2 = int.parse(matchEnd.group(1)!);
    final m2 = int.parse(matchEnd.group(2)!);

    int startMin = h1 * 60 + m1;
    int endMin = h2 * 60 + m2;
    if (endMin < startMin) {
      endMin += 24 * 60; // Melewati tengah malam
    }
    return (endMin - startMin) / 60.0;
  }

  /// Menghitung selisih waktu dalam satuan menit (dengan nilai fallback jika kosong).
  static double calcMinuteDiff(String startTime, String endTime, {double fallback = 5.0}) {
    if (startTime.trim().isEmpty || endTime.trim().isEmpty) return fallback;
    final matchStart = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(startTime);
    final matchEnd = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(endTime);
    if (matchStart == null || matchEnd == null) return fallback;

    final h1 = int.parse(matchStart.group(1)!);
    final m1 = int.parse(matchStart.group(2)!);
    final h2 = int.parse(matchEnd.group(1)!);
    final m2 = int.parse(matchEnd.group(2)!);

    int startMin = h1 * 60 + m1;
    int endMin = h2 * 60 + m2;
    if (endMin < startMin) endMin += 24 * 60;
    final diff = (endMin - startMin).toDouble();
    return diff > 0 ? diff : fallback;
  }

  /// Format menit ke teks durasi jam:menit:detik (contoh: 8.467 menit -> "0:08:28")
  static String formatMinutesToDuration(double minutes) {
    int totalSec = (minutes * 60).round();
    int h = totalSec ~/ 3600;
    int m = (totalSec % 3600) ~/ 60;
    int s = totalSec % 60;
    return '${h.toString().padLeft(1, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Format angka desimal menggunakan koma standar Indonesia.
  /// Contoh: 1.65 -> "1,650"
  static String formatDecimal(double value, {int fractionDigits = 3}) {
    if (value == 0.0) return '0,000';
    return value.toStringAsFixed(fractionDigits).replaceAll('.', ',');
  }

  static String _extractStr(dynamic obj, String key) {
    if (obj == null) return '';
    if (obj is Map) {
      final val = obj[key];
      if (val == null) return '';
      try {
        final dynamic t = (val as dynamic).text;
        if (t is String) return t.trim();
      } catch (_) {}
      return val.toString().trim();
    }
    return '';
  }

  /// Menggabungkan data Suhu Lapangan, Suhu AMP, dan Tonase Aspal menjadi lembar Data Perjalanan DT
  static List<Map<String, dynamic>> computeDataPerjalananRows({
    required List<dynamic> lapanganList,
    required List<dynamic> ampList,
    required List<dynamic> tonaseList,
    double jarakKm = 35.5,
  }) {
    final Map<String, List<Map<String, String>>> lapanganByPlate = {};
    for (var m in lapanganList) {
      final rawPlate = _extractStr(m, 'nomorKendaraan');
      if (rawPlate.isEmpty) continue;
      final cleanPlate = normalize(rawPlate);
      lapanganByPlate.putIfAbsent(cleanPlate, () => []).add({
        'jamDatang': _extractStr(m, 'jamDatang'),
        'suhu': _extractStr(m, 'suhu'),
        'jamMulaiTuang': _extractStr(m, 'jamMulaiTuang'),
        'jamSelesaiTuang': _extractStr(m, 'jamSelesaiTuang'),
        'jamPulang': _extractStr(m, 'jamPulang'),
      });
    }

    final Map<String, List<Map<String, String>>> ampByPlate = {};
    for (var m in ampList) {
      final rawPlate = _extractStr(m, 'nomorKendaraan');
      if (rawPlate.isEmpty) continue;
      final cleanPlate = normalize(rawPlate);
      ampByPlate.putIfAbsent(cleanPlate, () => []).add({
        'jamPergi': _extractStr(m, 'jamPergi'),
        'suhuAmp': _extractStr(m, 'suhuAmp'),
        'jamPulang': _extractStr(m, 'jamPulang'),
      });
    }

    final Map<String, List<Map<String, String>>> tonaseByPlate = {};
    for (var m in tonaseList) {
      final rawPlate = _extractStr(m, 'nomorKendaraan');
      if (rawPlate.isEmpty) continue;
      final cleanPlate = normalize(rawPlate);
      tonaseByPlate.putIfAbsent(cleanPlate, () => []).add({
        'tonaseTiket': _extractStr(m, 'tonaseTiket'),
      });
    }

    final List<Map<String, dynamic>> result = [];
    final Set<String> allPlatesInOrder = {};

    for (var m in ampList) {
      final p = normalize(_extractStr(m, 'nomorKendaraan'));
      if (p.isNotEmpty) allPlatesInOrder.add(p);
    }
    for (var m in lapanganList) {
      final p = normalize(_extractStr(m, 'nomorKendaraan'));
      if (p.isNotEmpty) allPlatesInOrder.add(p);
    }
    for (var m in tonaseList) {
      final p = normalize(_extractStr(m, 'nomorKendaraan'));
      if (p.isNotEmpty) allPlatesInOrder.add(p);
    }

    for (var plate in allPlatesInOrder) {
      final countAmp = ampByPlate[plate]?.length ?? 0;
      final countLap = lapanganByPlate[plate]?.length ?? 0;
      final countTon = tonaseByPlate[plate]?.length ?? 0;
      final int maxRit = [countAmp, countLap, countTon].reduce((a, b) => a > b ? a : b);

      for (int ritIdx = 0; ritIdx < maxRit; ritIdx++) {
        final ampData = (ritIdx < countAmp) ? ampByPlate[plate]![ritIdx] : <String, String>{};
        final lapData = (ritIdx < countLap) ? lapanganByPlate[plate]![ritIdx] : <String, String>{};
        final tonData = (ritIdx < countTon) ? tonaseByPlate[plate]![ritIdx] : <String, String>{};

        final jamDariAmp = ampData['jamPergi'] ?? '';
        final jamTibaLokasi = lapData['jamDatang'] ?? '';
        final jamDariLokasi = lapData['jamPulang'] ?? '';
        final jamTibaAmp = ampData['jamPulang'] ?? '';

        final jamMulaiTuang = lapData['jamMulaiTuang'] ?? '';
        final jamSelesaiTuang = lapData['jamSelesaiTuang'] ?? '';

        final suhuAmp = double.tryParse((ampData['suhuAmp'] ?? '').replaceAll(',', '.')) ?? 0.0;
        final suhuLap = double.tryParse((lapData['suhu'] ?? '').replaceAll(',', '.')) ?? 0.0;
        final beratAc = double.tryParse((tonData['tonaseTiket'] ?? '').replaceAll(',', '.')) ?? 0.0;

        final double waktuBerangkatJam = calcHourDiff(jamDariAmp, jamTibaLokasi);
        final double waktuPulangJam = calcHourDiff(jamDariLokasi, jamTibaAmp);
        final double waktuHamparMenit = calcMinuteDiff(jamMulaiTuang, jamSelesaiTuang, fallback: 8.0);
        const double waktuAntrianMenit = 5.0; // 0:05:00 default

        final double totalJam = waktuBerangkatJam +
            (waktuAntrianMenit / 60.0) +
            (waktuHamparMenit / 60.0) +
            waktuPulangJam;

        final double selisihSuhu = (suhuAmp > 0 && suhuLap > 0) ? (suhuAmp - suhuLap) : 0.0;
        final double turunPerJam = (waktuBerangkatJam > 0 && selisihSuhu > 0)
            ? (selisihSuhu / waktuBerangkatJam)
            : 0.0;

        final double kecBerangkat = (waktuBerangkatJam > 0 && jarakKm > 0)
            ? (jarakKm / waktuBerangkatJam)
            : 0.0;
        final double kecPulang = (waktuPulangJam > 0 && jarakKm > 0)
            ? (jarakKm / waktuPulangJam)
            : 0.0;

        final splitPlate = split(plate);

        result.add({
          'plate': plate,
          'platePrefix': splitPlate['prefix'] ?? '',
          'plateNumber': splitPlate['number'] ?? '',
          'plateSuffix': splitPlate['suffix'] ?? '',
          'rit': ritIdx + 1,
          'jamDariAmp': jamDariAmp,
          'jamTibaLokasi': jamTibaLokasi,
          'jamDariLokasi': jamDariLokasi,
          'jamTibaAmp': jamTibaAmp,
          'waktuBerangkatJam': waktuBerangkatJam,
          'waktuAntrian': '0:05:00',
          'waktuHampar': formatMinutesToDuration(waktuHamparMenit),
          'waktuPulangJam': waktuPulangJam,
          'totalJam': totalJam,
          'suhuAmp': suhuAmp,
          'suhuLokasi': suhuLap,
          'selisihSuhu': selisihSuhu,
          'turunPerJam': turunPerJam,
          'kecepatanBerangkat': kecBerangkat,
          'kecepatanPulang': kecPulang,
          'beratAc': beratAc,
        });
      }
    }

    result.sort((a, b) {
      final tA = a['jamDariAmp'] as String;
      final tB = b['jamDariAmp'] as String;
      if (tA.isNotEmpty && tB.isNotEmpty) return tA.compareTo(tB);
      return 0;
    });

    return result;
  }
}
