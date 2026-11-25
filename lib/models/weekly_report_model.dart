import 'package:intl/intl.dart';
import '../utils/rupiah_input_formatter.dart';

class WeeklyTableRow {
  String status;
  int mingguKe;
  String tglMulai;
  String tglSelesai;
  double? rencana;
  double? realisasi;

  double? get deviasi {
    if (rencana != null && realisasi != null) {
      return realisasi! - rencana!;
    }
    return null;
  }

  WeeklyTableRow({
    this.status = 'Kontrak',
    required this.mingguKe,
    required this.tglMulai,
    required this.tglSelesai,
    this.rencana,
    this.realisasi,
  });

  factory WeeklyTableRow.fromJson(Map<String, dynamic> json) {
    return WeeklyTableRow(
      status: json['status'] ?? 'Kontrak',
      mingguKe: json['mingguKe'] is int ? json['mingguKe'] : int.tryParse(json['mingguKe']?.toString() ?? '1') ?? 1,
      tglMulai: json['tglMulai'] ?? '',
      tglSelesai: json['tglSelesai'] ?? '',
      rencana: json['rencana'] != null ? (json['rencana'] as num).toDouble() : null,
      realisasi: json['realisasi'] != null ? (json['realisasi'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'mingguKe': mingguKe,
      'tglMulai': tglMulai,
      'tglSelesai': tglSelesai,
      'rencana': rencana,
      'realisasi': realisasi,
      'deviasi': deviasi,
    };
  }
}

class WeeklyReportModel {
  final String id;
  String pekerjaan;
  String lokasiProyek;
  String kontraktor;
  int jangkaWaktu; // e.g. 90 (Hari Kalender)
  String nomorKontrak; // e.g. '000.3.3/ 1128 /KONST/BM/IV/2026'
  String tanggalKontrak; // e.g. '20 April 2026'
  String nilaiKontrak; // e.g. 'Rp 3.000.000.000,00'
  double nilaiKontrakNumeric; // 3000000000.0
  String tanggalSpmk; // e.g. '20 April 2026'
  int mingguKe; // e.g. 6
  int totalMinggu; // e.g. 13
  String periodeAwal; // e.g. '24 Mei 2026'
  String periodeAkhir; // e.g. '30 Mei 2026'
  double rencanaPersen; // e.g. 1.433
  double rencanaNominal; // e.g. 42990000.0
  double realisasiPersen; // e.g. 6.930
  double realisasiNominal; // e.g. 207900000.0
  double deviasiPersen; // e.g. 5.497
  double deviasiNominal; // e.g. 164910000.0
  int waktuTerpakai; // e.g. 41 (Hari Kalender)
  int sisaWaktu; // e.g. 49 (Hari Kalender)
  String akhirMasaKontrak; // e.g. '18 Juli 2026'
  List<WeeklyTableRow> tabelMingguan;
  List<Map<String, dynamic>>? boqProgressList;
  String createdAt;

  // Data Tanda Tangan & Pengesahan Digital (3 Pihak)
  List<Map<String, dynamic>>? ttdList;
  String? ttdKontraktorNama;
  String? ttdKontraktorJabatan;
  String? ttdKontraktorSignature;
  String? ttdKontraktorTanggal;

  String? ttdKonsultanNama;
  String? ttdKonsultanJabatan;
  String? ttdKonsultanSignature;
  String? ttdKonsultanTanggal;

  String? ttdPpkNama;
  String? ttdPpkJabatan;
  String? ttdPpkSignature;
  String? ttdPpkTanggal;

  WeeklyReportModel({
    required this.id,
    required this.pekerjaan,
    required this.lokasiProyek,
    required this.kontraktor,
    required this.jangkaWaktu,
    required this.nomorKontrak,
    required this.tanggalKontrak,
    required this.nilaiKontrak,
    required this.nilaiKontrakNumeric,
    required this.tanggalSpmk,
    required this.mingguKe,
    required this.totalMinggu,
    required this.periodeAwal,
    required this.periodeAkhir,
    required this.rencanaPersen,
    required this.rencanaNominal,
    required this.realisasiPersen,
    required this.realisasiNominal,
    required this.deviasiPersen,
    required this.deviasiNominal,
    required this.waktuTerpakai,
    required this.sisaWaktu,
    required this.akhirMasaKontrak,
    required this.tabelMingguan,
    this.boqProgressList,
    String? createdAt,
    this.ttdList,
    this.ttdKontraktorNama,
    this.ttdKontraktorJabatan,
    this.ttdKontraktorSignature,
    this.ttdKontraktorTanggal,
    this.ttdKonsultanNama,
    this.ttdKonsultanJabatan,
    this.ttdKonsultanSignature,
    this.ttdKonsultanTanggal,
    this.ttdPpkNama,
    this.ttdPpkJabatan,
    this.ttdPpkSignature,
    this.ttdPpkTanggal,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  Map<String, dynamic> get ttdKontraktor {
    if (ttdList != null && ttdList!.isNotEmpty) {
      final f = ttdList!.firstWhere(
        (t) =>
            t['pihak'] == 'kontraktor' ||
            (t['jabatan']?.toString().toLowerCase().contains('kontraktor') ?? false),
        orElse: () => ttdList!.first,
      );
      if (f.isNotEmpty) return f;
    }
    return {
      'nama': ttdKontraktorNama ?? '',
      'jabatan': ttdKontraktorJabatan ?? 'Kontraktor Pelaksana',
      'signature': ttdKontraktorSignature,
      'tanggal': ttdKontraktorTanggal ?? '',
    };
  }

  Map<String, dynamic> get ttdKonsultan {
    if (ttdList != null && ttdList!.isNotEmpty) {
      final f = ttdList!.firstWhere(
        (t) =>
            t['pihak'] == 'konsultan' ||
            (t['jabatan']?.toString().toLowerCase().contains('konsultan') ?? false),
        orElse: () => ttdList!.length > 1 ? ttdList![1] : {},
      );
      if (f.isNotEmpty) return f;
    }
    return {
      'nama': ttdKonsultanNama ?? '',
      'jabatan': ttdKonsultanJabatan ?? 'Konsultan Supervisi',
      'signature': ttdKonsultanSignature,
      'tanggal': ttdKonsultanTanggal ?? '',
    };
  }

  Map<String, dynamic> get ttdPpk {
    if (ttdList != null && ttdList!.isNotEmpty) {
      final f = ttdList!.firstWhere(
        (t) =>
            t['pihak'] == 'ppk' ||
            (t['jabatan']?.toString().toLowerCase().contains('ppk') ?? false),
        orElse: () => ttdList!.length > 2 ? ttdList![2] : {},
      );
      if (f.isNotEmpty) return f;
    }
    return {
      'nama': ttdPpkNama ?? '',
      'jabatan': ttdPpkJabatan ?? 'Pejabat Pembuat Komitmen (PPK)',
      'signature': ttdPpkSignature,
      'tanggal': ttdPpkTanggal ?? '',
    };
  }

  factory WeeklyReportModel.fromJson(Map<String, dynamic> json) {
    return WeeklyReportModel(
      id: json['id'] ?? '',
      pekerjaan: json['pekerjaan'] ?? '',
      lokasiProyek: json['lokasiProyek'] ?? '',
      kontraktor: json['kontraktor'] ?? '',
      jangkaWaktu: json['jangkaWaktu'] is int ? json['jangkaWaktu'] : int.tryParse(json['jangkaWaktu']?.toString() ?? '90') ?? 90,
      nomorKontrak: json['nomorKontrak'] ?? '',
      tanggalKontrak: json['tanggalKontrak'] ?? '',
      nilaiKontrak: json['nilaiKontrak'] ?? '',
      nilaiKontrakNumeric: (json['nilaiKontrakNumeric'] as num?)?.toDouble() ?? parseRupiah(json['nilaiKontrak'] ?? '0'),
      tanggalSpmk: json['tanggalSpmk'] ?? '',
      mingguKe: json['mingguKe'] is int ? json['mingguKe'] : int.tryParse(json['mingguKe']?.toString() ?? '1') ?? 1,
      totalMinggu: json['totalMinggu'] is int ? json['totalMinggu'] : int.tryParse(json['totalMinggu']?.toString() ?? '13') ?? 13,
      periodeAwal: json['periodeAwal'] ?? '',
      periodeAkhir: json['periodeAkhir'] ?? '',
      rencanaPersen: (json['rencanaPersen'] as num?)?.toDouble() ?? 0.0,
      rencanaNominal: (json['rencanaNominal'] as num?)?.toDouble() ?? 0.0,
      realisasiPersen: (json['realisasiPersen'] as num?)?.toDouble() ?? 0.0,
      realisasiNominal: (json['realisasiNominal'] as num?)?.toDouble() ?? 0.0,
      deviasiPersen: (json['deviasiPersen'] as num?)?.toDouble() ?? 0.0,
      deviasiNominal: (json['deviasiNominal'] as num?)?.toDouble() ?? 0.0,
      waktuTerpakai: json['waktuTerpakai'] is int ? json['waktuTerpakai'] : int.tryParse(json['waktuTerpakai']?.toString() ?? '0') ?? 0,
      sisaWaktu: json['sisaWaktu'] is int ? json['sisaWaktu'] : int.tryParse(json['sisaWaktu']?.toString() ?? '0') ?? 0,
      akhirMasaKontrak: json['akhirMasaKontrak'] ?? '',
      tabelMingguan: (json['tabelMingguan'] as List<dynamic>?)
              ?.map((item) => WeeklyTableRow.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      boqProgressList: json['boqProgressList'] != null
          ? List<Map<String, dynamic>>.from(
              (json['boqProgressList'] as List).map((e) => Map<String, dynamic>.from(e)))
          : null,
      createdAt: json['createdAt'],
      ttdList: json['ttdList'] != null
          ? List<Map<String, dynamic>>.from(
              (json['ttdList'] as List).map((e) => Map<String, dynamic>.from(e)))
          : null,
      ttdKontraktorNama: json['ttdKontraktorNama']?.toString(),
      ttdKontraktorJabatan: json['ttdKontraktorJabatan']?.toString(),
      ttdKontraktorSignature: json['ttdKontraktorSignature']?.toString(),
      ttdKontraktorTanggal: json['ttdKontraktorTanggal']?.toString(),
      ttdKonsultanNama: json['ttdKonsultanNama']?.toString(),
      ttdKonsultanJabatan: json['ttdKonsultanJabatan']?.toString(),
      ttdKonsultanSignature: json['ttdKonsultanSignature']?.toString(),
      ttdKonsultanTanggal: json['ttdKonsultanTanggal']?.toString(),
      ttdPpkNama: json['ttdPpkNama']?.toString(),
      ttdPpkJabatan: json['ttdPpkJabatan']?.toString(),
      ttdPpkSignature: json['ttdPpkSignature']?.toString(),
      ttdPpkTanggal: json['ttdPpkTanggal']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pekerjaan': pekerjaan,
      'lokasiProyek': lokasiProyek,
      'kontraktor': kontraktor,
      'jangkaWaktu': jangkaWaktu,
      'nomorKontrak': nomorKontrak,
      'tanggalKontrak': tanggalKontrak,
      'nilaiKontrak': nilaiKontrak,
      'nilaiKontrakNumeric': nilaiKontrakNumeric,
      'tanggalSpmk': tanggalSpmk,
      'mingguKe': mingguKe,
      'totalMinggu': totalMinggu,
      'periodeAwal': periodeAwal,
      'periodeAkhir': periodeAkhir,
      'rencanaPersen': rencanaPersen,
      'rencanaNominal': rencanaNominal,
      'realisasiPersen': realisasiPersen,
      'realisasiNominal': realisasiNominal,
      'deviasiPersen': deviasiPersen,
      'deviasiNominal': deviasiNominal,
      'waktuTerpakai': waktuTerpakai,
      'sisaWaktu': sisaWaktu,
      'akhirMasaKontrak': akhirMasaKontrak,
      'tabelMingguan': tabelMingguan.map((e) => e.toJson()).toList(),
      'boqProgressList': boqProgressList,
      'createdAt': createdAt,
      'ttdList': ttdList,
      'ttdKontraktorNama': ttdKontraktorNama,
      'ttdKontraktorJabatan': ttdKontraktorJabatan,
      'ttdKontraktorSignature': ttdKontraktorSignature,
      'ttdKontraktorTanggal': ttdKontraktorTanggal,
      'ttdKonsultanNama': ttdKonsultanNama,
      'ttdKonsultanJabatan': ttdKonsultanJabatan,
      'ttdKonsultanSignature': ttdKonsultanSignature,
      'ttdKonsultanTanggal': ttdKonsultanTanggal,
      'ttdPpkNama': ttdPpkNama,
      'ttdPpkJabatan': ttdPpkJabatan,
      'ttdPpkSignature': ttdPpkSignature,
      'ttdPpkTanggal': ttdPpkTanggal,
    };
  }

  // Helper formatting and parsing utilities
  static const List<String> namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static double parseRupiah(String text) {
    return RupiahUtil.parseToDouble(text);
  }

  static String formatRupiah(double value, {bool withRp = true}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: withRp ? 'Rp ' : '',
      decimalDigits: 2,
    );
    return formatter.format(value).trim();
  }

  static String formatPercent(double? value, {int decimalDigits = 3, bool showSign = false, bool appendUnit = true}) {
    if (value == null) return '-';
    final sign = (showSign && value > 0) ? '+' : '';
    final str = value.toStringAsFixed(decimalDigits).replaceAll('.', ',');
    return appendUnit ? '$sign$str %' : '$sign$str';
  }

  static DateTime? parseIndonesianDate(String text) {
    if (text.isEmpty) return null;
    try {
      String clean = text.trim();
      // Bersihkan awalan hari jika ada koma, misal "Kamis, 23 April 2026"
      if (clean.contains(',')) {
        final commaIdx = clean.indexOf(',');
        final prefix = clean.substring(0, commaIdx).trim().toLowerCase();
        const daysPrefix = ['senin', 'selasa', 'rabu', 'kamis', 'jumat', 'sabtu', 'minggu'];
        if (daysPrefix.contains(prefix)) {
          clean = clean.substring(commaIdx + 1).trim();
        }
      }
      // Bersihkan awalan kata "Tanggal" jika ada
      if (clean.toLowerCase().startsWith('tanggal ')) {
        clean = clean.substring(8).trim();
      } else if (clean.toLowerCase().startsWith('tgl. ')) {
        clean = clean.substring(5).trim();
      } else if (clean.toLowerCase().startsWith('tgl ')) {
        clean = clean.substring(4).trim();
      }

      // Check yyyy-mm-dd
      if (clean.contains('-') && clean.length >= 10 && clean.indexOf('-') == 4) {
        return DateTime.parse(clean.substring(0, 10));
      }

      // Check dd-mm-yyyy atau yyyy-mm-dd
      if (clean.contains('-')) {
        final parts = clean.split('-');
        if (parts.length == 3) {
          final p0 = int.tryParse(parts[0]);
          final p1 = int.tryParse(parts[1]);
          final p2 = int.tryParse(parts[2]);
          if (p0 != null && p1 != null && p2 != null) {
            if (parts[0].length == 4) {
              return DateTime(p0, p1, p2);
            } else {
              return DateTime(p2, p1, p0);
            }
          }
        }
      }

      // Check dd/MM/yyyy
      if (clean.contains('/')) {
        final parts = clean.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            return DateTime(year, month, day);
          }
        }
      }

      // Check "20 April 2026"
      final parts = clean.split(RegExp(r'\s+'));
      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);
        final monthName = parts[1].toLowerCase();
        int? month;
        if (monthName == 'nopember') {
          month = 11;
        } else {
          for (int i = 0; i < namaBulan.length; i++) {
            if (namaBulan[i].toLowerCase() == monthName) {
              month = i + 1;
              break;
            }
          }
        }
        final year = int.tryParse(parts[2]);
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    } catch (_) {}
    return null;
  }

  static String formatIndonesianDate(DateTime dt) {
    return '${dt.day} ${namaBulan[dt.month - 1]} ${dt.year}';
  }

  static String formatDateSlash(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  /// Create sample instance exactly corresponding to the user's uploaded document
  static WeeklyReportModel sampleDocument() {
    final table = [
      WeeklyTableRow(status: 'Kontrak', mingguKe: 1, tglMulai: '20/04/2026', tglSelesai: '25/04/2026', rencana: 0.000, realisasi: 0.000),
      WeeklyTableRow(status: 'Kontrak', mingguKe: 2, tglMulai: '26/04/2026', tglSelesai: '02/05/2026', rencana: 0.010, realisasi: 0.000),
      WeeklyTableRow(status: 'Kontrak', mingguKe: 3, tglMulai: '03/05/2026', tglSelesai: '09/05/2026', rencana: 0.084, realisasi: 0.010),
      WeeklyTableRow(status: 'Kontrak', mingguKe: 4, tglMulai: '10/05/2026', tglSelesai: '16/05/2026', rencana: 0.159, realisasi: 0.212),
      WeeklyTableRow(status: 'Kontrak', mingguKe: 5, tglMulai: '17/05/2026', tglSelesai: '23/05/2026', rencana: 0.630, realisasi: 4.923),
      WeeklyTableRow(status: 'Kontrak', mingguKe: 6, tglMulai: '24/05/2026', tglSelesai: '30/05/2026', rencana: 1.433, realisasi: 6.930),
      WeeklyTableRow(status: '', mingguKe: 7, tglMulai: '31/05/2026', tglSelesai: '06/06/2026', rencana: 5.106, realisasi: null),
      WeeklyTableRow(status: '', mingguKe: 8, tglMulai: '07/06/2026', tglSelesai: '13/06/2026', rencana: 8.816, realisasi: null),
      WeeklyTableRow(status: '', mingguKe: 9, tglMulai: '14/06/2026', tglSelesai: '20/06/2026', rencana: 12.526, realisasi: null),
      WeeklyTableRow(status: '', mingguKe: 10, tglMulai: '21/06/2026', tglSelesai: '27/06/2026', rencana: 15.804, realisasi: null),
      WeeklyTableRow(status: '', mingguKe: 11, tglMulai: '28/06/2026', tglSelesai: '04/07/2026', rencana: 45.782, realisasi: null),
      WeeklyTableRow(status: '', mingguKe: 12, tglMulai: '05/07/2026', tglSelesai: '11/07/2026', rencana: 72.891, realisasi: null),
      WeeklyTableRow(status: '', mingguKe: 13, tglMulai: '12/07/2026', tglSelesai: '18/07/2026', rencana: 100.000, realisasi: null),
    ];

    return WeeklyReportModel(
      id: 'weekly-sample-week6',
      pekerjaan: 'PEMELIHARAAN BERKALA JALAN LETJEND MT. HARYONO',
      lokasiProyek: 'KEC. PURBALINGGA',
      kontraktor: 'PT. ANDHIKA BANGUNAN PERKASA',
      jangkaWaktu: 90,
      nomorKontrak: '000.3.3/ 1128 /KONST/BM/IV/2026',
      tanggalKontrak: '20 April 2026',
      nilaiKontrak: 'Rp 3.000.000.000,00',
      nilaiKontrakNumeric: 3000000000.0,
      tanggalSpmk: '20 April 2026',
      mingguKe: 6,
      totalMinggu: 13,
      periodeAwal: '24 Mei 2026',
      periodeAkhir: '30 Mei 2026',
      rencanaPersen: 1.433,
      rencanaNominal: 42990000.0,
      realisasiPersen: 6.930,
      realisasiNominal: 207900000.0,
      deviasiPersen: 5.497,
      deviasiNominal: 164910000.0,
      waktuTerpakai: 41,
      sisaWaktu: 49,
      akhirMasaKontrak: '18 Juli 2026',
      tabelMingguan: table,
    );
  }
}
