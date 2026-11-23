import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';

/// Model data untuk Addendum Kontrak (Contract Change Order / CCO)
class AddendumModel {
  final String id;
  String nomorAddendum; // Contoh: '01', '02'
  String judul; // Contoh: 'Daftar Perhitungan Tambah Kurang Ke - 01'
  String nomorSpkAddendum; // Contoh: '000.3.2/1914.1/ADD-01/2026'
  String tanggalAddendum; // Contoh: '15 Agustus 2026'
  String keterangan; // Contoh: 'Penyesuaian volume hasil rekayasa lapangan (CCO 01)'
  String parentVersion; // 'kontrak_awal' atau id addendum sebelumnya
  List<Map<String, dynamic>> rkkDivisiList;
  DateTime createdAt;

  AddendumModel({
    required this.id,
    required this.nomorAddendum,
    required this.judul,
    this.nomorSpkAddendum = '',
    this.tanggalAddendum = '',
    this.keterangan = '',
    this.parentVersion = 'kontrak_awal',
    required this.rkkDivisiList,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AddendumModel.fromJson(Map<String, dynamic> json) {
    return AddendumModel(
      id: json['id'] ?? 'addendum-${DateTime.now().millisecondsSinceEpoch}',
      nomorAddendum: json['nomorAddendum']?.toString() ?? '01',
      judul: json['judul'] ?? 'Daftar Perhitungan Tambah Kurang',
      nomorSpkAddendum: json['nomorSpkAddendum'] ?? '',
      tanggalAddendum: json['tanggalAddendum'] ?? '',
      keterangan: json['keterangan'] ?? '',
      parentVersion: json['parentVersion'] ?? 'kontrak_awal',
      rkkDivisiList: json['rkkDivisiList'] != null
          ? (json['rkkDivisiList'] as List).map((e) => Map<String, dynamic>.from(e)).toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomorAddendum': nomorAddendum,
      'judul': judul,
      'nomorSpkAddendum': nomorSpkAddendum,
      'tanggalAddendum': tanggalAddendum,
      'keterangan': keterangan,
      'parentVersion': parentVersion,
      'rkkDivisiList': rkkDivisiList,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Menghitung total harga seluruh item pada addendum ini
  double get totalHarga {
    double total = 0.0;
    for (final div in rkkDivisiList) {
      final items = div['items'] as List? ?? [];
      for (final it in items) {
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        final th = (it['totalHarga'] as num?)?.toDouble() ?? (hs * vol);
        total += th;
      }
    }
    return total;
  }

  /// Menghitung total bobot seluruh item pada addendum ini
  double get totalBobot {
    double total = 0.0;
    for (final div in rkkDivisiList) {
      final items = div['items'] as List? ?? [];
      for (final it in items) {
        total += (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return total;
  }
}

/// Hasil komputasi per item pada perhitungan tambah kurang
class TambahKurangItemResult {
  final String no;
  final String noMataPembayaran;
  final String uraian;
  final String satuan;
  final double hargaSatuan;

  // Baseline (Kontrak Awal / Addendum sebelumnya)
  final double baselineVolume;
  final double baselineTotalHarga;
  final double baselineBobot;

  // Addendum (Perubahan Baru / CCO)
  final double addendumVolume;
  final double addendumTotalHarga;
  final double addendumBobot;

  // Pekerjaan Tambah
  final double tambahVolume;
  final double tambahTotalHarga;
  final double tambahBobot;

  // Pekerjaan Kurang
  final double kurangVolume;
  final double kurangTotalHarga;
  final double kurangBobot;

  // Keterangan: 'Tetap', 'Tambah', 'Kurang'
  final String keterangan;

  TambahKurangItemResult({
    required this.no,
    required this.noMataPembayaran,
    required this.uraian,
    required this.satuan,
    required this.hargaSatuan,
    required this.baselineVolume,
    required this.baselineTotalHarga,
    required this.baselineBobot,
    required this.addendumVolume,
    required this.addendumTotalHarga,
    required this.addendumBobot,
    required this.tambahVolume,
    required this.tambahTotalHarga,
    required this.tambahBobot,
    required this.kurangVolume,
    required this.kurangTotalHarga,
    required this.kurangBobot,
    required this.keterangan,
  });
}

/// Hasil komputasi per divisi pada perhitungan tambah kurang
class TambahKurangDivisiResult {
  final String nomorRomawi;
  final String namaDivisi;
  final List<TambahKurangItemResult> items;

  final double subtotalBaselineHarga;
  final double subtotalBaselineBobot;
  final double subtotalAddendumHarga;
  final double subtotalAddendumBobot;
  final double subtotalTambahHarga;
  final double subtotalTambahBobot;
  final double subtotalKurangHarga;
  final double subtotalKurangBobot;

  TambahKurangDivisiResult({
    required this.nomorRomawi,
    required this.namaDivisi,
    required this.items,
    required this.subtotalBaselineHarga,
    required this.subtotalBaselineBobot,
    required this.subtotalAddendumHarga,
    required this.subtotalAddendumBobot,
    required this.subtotalTambahHarga,
    required this.subtotalTambahBobot,
    required this.subtotalKurangHarga,
    required this.subtotalKurangBobot,
  });
}

/// Laporan lengkap perbandingan Tambah Kurang (CCO)
class TambahKurangReportResult {
  final List<TambahKurangDivisiResult> divisiResults;

  final double totalBaselineHarga;
  final double totalBaselineBobot;

  final double totalAddendumHarga;
  final double totalAddendumBobot;

  final double totalTambahHarga;
  final double totalTambahBobot;

  final double totalKurangHarga;
  final double totalKurangBobot;

  final double totalDibulatkan;

  TambahKurangReportResult({
    required this.divisiResults,
    required this.totalBaselineHarga,
    required this.totalBaselineBobot,
    required this.totalAddendumHarga,
    required this.totalAddendumBobot,
    required this.totalTambahHarga,
    required this.totalTambahBobot,
    required this.totalKurangHarga,
    required this.totalKurangBobot,
    required this.totalDibulatkan,
  });
}

/// Algoritma Mesin Perhitungan Tambah Kurang (CCO Calculator Engine)
class TambahKurangCalculator {
  static TambahKurangReportResult calculate({
    required List<Map<String, dynamic>> baselineDivisiList,
    required List<Map<String, dynamic>> addendumDivisiList,
    double? customPaguDibulatkan,
    double? customPaguBobot,
  }) {
    // 1. Hitung total nominal baseline (T0) dan addendum (T1)
    double t0 = 0.0;
    for (final div in baselineDivisiList) {
      final items = (div['items'] as List? ?? []);
      for (final it in items) {
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        final th = (it['totalHarga'] as num?)?.toDouble() ?? (hs * vol);
        t0 += th;
      }
    }
    if (t0 == 0.0) t0 = 1.0; // cegah pembagian nol

    double t1 = 0.0;
    for (final div in addendumDivisiList) {
      final items = (div['items'] as List? ?? []);
      for (final it in items) {
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        final th = (it['totalHarga'] as num?)?.toDouble() ?? (hs * vol);
        t1 += th;
      }
    }
    if (t1 == 0.0) t1 = t0; // fallback jika belum diinput

    // Single source of truth: Pagu pembagi bobot SELALU menggunakan nilai nominal asli baseline (T0).
    // Nilai pembulatan (customPaguDibulatkan) tidak boleh digunakan untuk perhitungan bobot.
    final double paguBobot = (customPaguBobot != null && customPaguBobot > 0)
        ? customPaguBobot
        : (t0 > 0 ? t0 : 1.0);

    // 2. Buat map lookup untuk baseline items: key = noMataPembayaran || uraian
    final Map<String, Map<String, dynamic>> baselineItemMap = {};
    for (final div in baselineDivisiList) {
      final items = (div['items'] as List? ?? []);
      for (final it in items) {
        final noMata = (it['noMataPembayaran'] ?? '').toString().trim();
        final uraian = (it['uraian'] ?? '').toString().trim();
        final key = noMata.isNotEmpty ? noMata : uraian;
        baselineItemMap[key] = it;
      }
    }

    final List<TambahKurangDivisiResult> divResults = [];
    double grandBaselineHarga = 0.0;
    double grandBaselineBobot = 0.0;
    double grandAddendumHarga = 0.0;
    double grandAddendumBobot = 0.0;
    double grandTambahHarga = 0.0;
    double grandTambahBobot = 0.0;
    double grandKurangHarga = 0.0;
    double grandKurangBobot = 0.0;

    for (final div in addendumDivisiList) {
      final items = (div['items'] as List? ?? []);
      final romawi = div['nomorRomawi']?.toString().toUpperCase() ?? '';
      final namaDiv = div['namaDivisi']?.toString() ?? (romawi.isNotEmpty ? 'DIVISI $romawi' : 'DIVISI');

      final List<TambahKurangItemResult> itemResults = [];
      double subBaselineHarga = 0.0;
      double subBaselineBobot = 0.0;
      double subAddendumHarga = 0.0;
      double subAddendumBobot = 0.0;
      double subTambahHarga = 0.0;
      double subTambahBobot = 0.0;
      double subKurangHarga = 0.0;
      double subKurangBobot = 0.0;

      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final noMata = (it['noMataPembayaran'] ?? '').toString().trim();
        final uraian = (it['uraian'] ?? '').toString().trim();
        final satuan = (it['satuan'] ?? '').toString().trim();
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;

        final key = noMata.isNotEmpty ? noMata : uraian;
        final baseIt = baselineItemMap[key];

        final double v0 = baseIt != null
            ? ((baseIt['volume'] ?? baseIt['volumeCCO'] as num?)?.toDouble() ?? 0.0)
            : 0.0;
        final double th0 = baseIt != null
            ? ((baseIt['totalHarga'] as num?)?.toDouble() ?? (hs * v0))
            : (hs * v0);
        final double b0 = baseIt != null && baseIt['nilaiBobot'] != null
            ? (baseIt['nilaiBobot'] as num).toDouble()
            : (paguBobot > 0 ? (th0 / paguBobot) * 100.0 : 0.0);

        final double v1 = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        final double th1 = (it['totalHarga'] as num?)?.toDouble() ?? (hs * v1);
        final double b1 = it['nilaiBobot'] != null
            ? (it['nilaiBobot'] as num).toDouble()
            : (paguBobot > 0 ? (th1 / paguBobot) * 100.0 : 0.0);

        // Selisih volume: delta = v1 - v0
        final double deltaV = v1 - v0;
        double vt = 0.0; // volume tambah
        double tht = 0.0; // total harga tambah
        double bt = 0.0; // bobot tambah
        double vk = 0.0; // volume kurang
        double thk = 0.0; // total harga kurang
        double bk = 0.0; // bobot kurang
        String ket = 'Tetap';

        // Toleransi selisih floating point 0.0001
        if (deltaV > 0.0001) {
          vt = (it['volumeTambah'] as num?)?.toDouble() ?? deltaV;
          tht = (it['totalHargaTambah'] as num?)?.toDouble() ?? (vt * hs);
          bt = (it['bobotTambah'] as num?)?.toDouble() ?? ((tht / paguBobot) * 100.0);
          ket = 'Tambah';
        } else if (deltaV < -0.0001) {
          vk = (it['volumeKurang'] as num?)?.toDouble() ?? deltaV.abs();
          thk = (it['totalHargaKurang'] as num?)?.toDouble() ?? (vk * hs);
          bk = (it['bobotKurang'] as num?)?.toDouble() ?? ((thk / paguBobot) * 100.0);
          ket = 'Kurang';
        } else {
          ket = 'Tetap';
        }

        final itemRes = TambahKurangItemResult(
          no: it['no']?.toString() ?? '${i + 1}',
          noMataPembayaran: noMata,
          uraian: uraian,
          satuan: satuan,
          hargaSatuan: hs,
          baselineVolume: v0,
          baselineTotalHarga: th0,
          baselineBobot: b0,
          addendumVolume: v1,
          addendumTotalHarga: th1,
          addendumBobot: b1,
          tambahVolume: vt,
          tambahTotalHarga: tht,
          tambahBobot: bt,
          kurangVolume: vk,
          kurangTotalHarga: thk,
          kurangBobot: bk,
          keterangan: ket,
        );

        itemResults.add(itemRes);

        subBaselineHarga += th0;
        subBaselineBobot += b0;
        subAddendumHarga += th1;
        subAddendumBobot += b1;
        subTambahHarga += tht;
        subTambahBobot += bt;
        subKurangHarga += thk;
        subKurangBobot += bk;
      }

      divResults.add(TambahKurangDivisiResult(
        nomorRomawi: romawi,
        namaDivisi: namaDiv,
        items: itemResults,
        subtotalBaselineHarga: subBaselineHarga,
        subtotalBaselineBobot: subBaselineBobot,
        subtotalAddendumHarga: subAddendumHarga,
        subtotalAddendumBobot: subAddendumBobot,
        subtotalTambahHarga: subTambahHarga,
        subtotalTambahBobot: subTambahBobot,
        subtotalKurangHarga: subKurangHarga,
        subtotalKurangBobot: subKurangBobot,
      ));

      grandBaselineHarga += subBaselineHarga;
      grandBaselineBobot += subBaselineBobot;
      grandAddendumHarga += subAddendumHarga;
      grandAddendumBobot += subAddendumBobot;
      grandTambahHarga += subTambahHarga;
      grandTambahBobot += subTambahBobot;
      grandKurangHarga += subKurangHarga;
      grandKurangBobot += subKurangBobot;
    }

    // Pembulatan resmi nilai kontrak sesuai dokumen sah Dinas PU (Floor kelipatan Rp 1.000)
    final double rawPagu = (customPaguDibulatkan != null && customPaguDibulatkan > 0)
        ? customPaguDibulatkan
        : grandAddendumHarga;
    final double dibulatkan = RupiahUtil.floorToNearestThousand(rawPagu);

    // Pastikan total bobot Baseline & Addendum menampilkan tepat 100.000% jika mendekati 100%
    final double baselineBobotFinal = (grandBaselineBobot - 100.0).abs() < 0.05
        ? 100.000
        : grandBaselineBobot;
    final double addendumBobotFinal = (grandAddendumBobot - 100.0).abs() < 0.05
        ? 100.000
        : grandAddendumBobot;

    return TambahKurangReportResult(
      divisiResults: divResults,
      totalBaselineHarga: grandBaselineHarga,
      totalBaselineBobot: baselineBobotFinal,
      totalAddendumHarga: grandAddendumHarga,
      totalAddendumBobot: addendumBobotFinal,
      totalTambahHarga: grandTambahHarga,
      totalTambahBobot: grandTambahBobot,
      totalKurangHarga: grandKurangHarga,
      totalKurangBobot: grandKurangBobot,
      totalDibulatkan: dibulatkan,
    );
  }
}
