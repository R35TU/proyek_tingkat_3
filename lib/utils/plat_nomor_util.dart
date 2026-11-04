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

  /// Menstandarkan format jam menjadi HH:mm:ss 24-jam.
  /// Menyelaraskan berbagai variasi input seperti "15.30", "15", "8:5", "15:30:25", "15:30 WIB".
  static String normalizeTime(String raw) {
    if (raw.trim().isEmpty) return '';
    final clean = raw
        .trim()
        .toLowerCase()
        .replaceAll('wib', '')
        .replaceAll('wita', '')
        .replaceAll('wit', '')
        .trim();

    // Format HH:mm:ss atau HH.mm.ss (misal: 15:30:45, 08.45.20)
    final matchWithSeconds = RegExp(r'^(\d{1,2})[:.](\d{1,2})[:.](\d{1,2})$').firstMatch(clean);
    if (matchWithSeconds != null) {
      final h = int.parse(matchWithSeconds.group(1)!).clamp(0, 23);
      final m = int.parse(matchWithSeconds.group(2)!).clamp(0, 59);
      final s = int.parse(matchWithSeconds.group(3)!).clamp(0, 59);
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    // Format HH:mm atau HH.mm (misal: 15:30, 8:5, 15.30) -> format ke HH:mm:00
    final matchFull = RegExp(r'^(\d{1,2})[:.](\d{1,2})$').firstMatch(clean);
    if (matchFull != null) {
      final h = int.parse(matchFull.group(1)!).clamp(0, 23);
      final m = int.parse(matchFull.group(2)!).clamp(0, 59);
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
    }

    // Format jam saja tanpa menit (misal: "15" -> "15:00:00", "8" -> "08:00:00")
    final matchHour = RegExp(r'^(\d{1,2})$').firstMatch(clean);
    if (matchHour != null) {
      final h = int.parse(matchHour.group(1)!).clamp(0, 23);
      return '${h.toString().padLeft(2, '0')}:00:00';
    }

    return raw.trim();
  }

  /// Menghitung selisih waktu antara dua jam (HH:mm:ss) dalam satuan desimal jam.
  /// Contoh: 07:14:00 ke 08:44:00 = 90 menit / 60 = 1.500 jam.
  static double calcHourDiff(String startTime, String endTime) {
    final cleanStart = normalizeTime(startTime);
    final cleanEnd = normalizeTime(endTime);
    if (cleanStart.isEmpty || cleanEnd.isEmpty) return 0.0;
    final matchStart = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})').firstMatch(cleanStart);
    final matchEnd = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})').firstMatch(cleanEnd);
    if (matchStart == null || matchEnd == null) return 0.0;

    final h1 = int.parse(matchStart.group(1)!);
    final m1 = int.parse(matchStart.group(2)!);
    final s1 = int.parse(matchStart.group(3)!);

    final h2 = int.parse(matchEnd.group(1)!);
    final m2 = int.parse(matchEnd.group(2)!);
    final s2 = int.parse(matchEnd.group(3)!);

    int startSec = h1 * 3600 + m1 * 60 + s1;
    int endSec = h2 * 3600 + m2 * 60 + s2;
    if (endSec < startSec) {
      endSec += 24 * 3600; // Melewati tengah malam
    }
    return (endSec - startSec) / 3600.0;
  }

  /// Menghitung selisih waktu dalam satuan menit (dengan nilai fallback jika kosong).
  static double calcMinuteDiff(String startTime, String endTime, {double fallback = 5.0}) {
    final cleanStart = normalizeTime(startTime);
    final cleanEnd = normalizeTime(endTime);
    if (cleanStart.isEmpty || cleanEnd.isEmpty) return fallback;
    final matchStart = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})').firstMatch(cleanStart);
    final matchEnd = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})').firstMatch(cleanEnd);
    if (matchStart == null || matchEnd == null) return fallback;

    final h1 = int.parse(matchStart.group(1)!);
    final m1 = int.parse(matchStart.group(2)!);
    final s1 = int.parse(matchStart.group(3)!);

    final h2 = int.parse(matchEnd.group(1)!);
    final m2 = int.parse(matchEnd.group(2)!);
    final s2 = int.parse(matchEnd.group(3)!);

    int startSec = h1 * 3600 + m1 * 60 + s1;
    int endSec = h2 * 3600 + m2 * 60 + s2;
    if (endSec < startSec) endSec += 24 * 3600;
    final diff = (endSec - startSec) / 60.0;
    return diff > 0 ? diff : fallback;
  }

  /// Mengurai nilai waktu antrian/menit menjadi desimal menit.
  /// Mendukung format:
  /// - Angka menit: "5", "10", "12.5", "12,5"
  /// - Format teks: "5 menit", "10 mnt", "15 mins"
  /// - Format jam:menit[:detik]: "0:05:00", "00:10", "0:12:30"
  static double parseMinutes(String raw, {double fallback = 5.0}) {
    final clean = raw.trim().toLowerCase();
    if (clean.isEmpty) return fallback;

    // Cek format HH:mm:ss atau HH:mm
    final timeMatch = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$').firstMatch(clean);
    if (timeMatch != null) {
      final h = int.parse(timeMatch.group(1)!);
      final m = int.parse(timeMatch.group(2)!);
      final s = timeMatch.group(3) != null ? int.parse(timeMatch.group(3)!) : 0;
      return (h * 60) + m + (s / 60.0);
    }

    // Ekstrak angka desimal atau integer
    final numMatch = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(clean);
    if (numMatch != null) {
      final val = double.tryParse(numMatch.group(1)!.replaceAll(',', '.'));
      if (val != null && val >= 0) {
        return val;
      }
    }

    return fallback;
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
        'waktuAntrian': _extractStr(m, 'waktuAntrian'),
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
        
        final rawAntrian = lapData['waktuAntrian'] ?? '';
        final double waktuAntrianMenit = parseMinutes(rawAntrian, fallback: 5.0);

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
          'waktuAntrian': formatMinutesToDuration(waktuAntrianMenit),
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
