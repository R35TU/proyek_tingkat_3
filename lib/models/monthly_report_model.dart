import 'dart:math';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';

class MonthlyBoQItem {
  final String no;
  final String noMataPembayaran;
  final String uraian;
  final String satuan;
  final double volumeCCO;
  final double bobotCCO;

  final double volumeBulanLalu;
  final double bobotBulanLalu;

  final double volumeBulanIni;
  final double bobotBulanIni;

  final double volumeSdBulanIni;
  final double bobotSdBulanIni;

  final double sisaVolume;
  final double sisaBobot;
  final String keterangan;

  MonthlyBoQItem({
    required this.no,
    required this.noMataPembayaran,
    required this.uraian,
    required this.satuan,
    required this.volumeCCO,
    required this.bobotCCO,
    required this.volumeBulanLalu,
    required this.bobotBulanLalu,
    required this.volumeBulanIni,
    required this.bobotBulanIni,
    required this.volumeSdBulanIni,
    required this.bobotSdBulanIni,
    required this.sisaVolume,
    required this.sisaBobot,
    this.keterangan = '',
  });
}

class MonthlyBoQDivision {
  final String kode;
  final String nama;
  final List<MonthlyBoQItem> items;

  MonthlyBoQDivision({
    required this.kode,
    required this.nama,
    required this.items,
  });

  double get subtotalBobotCCO => items.fold(0.0, (s, it) => s + it.bobotCCO);
  double get subtotalBobotBulanLalu => items.fold(0.0, (s, it) => s + it.bobotBulanLalu);
  double get subtotalBobotBulanIni => items.fold(0.0, (s, it) => s + it.bobotBulanIni);
  double get subtotalBobotSdBulanIni => items.fold(0.0, (s, it) => s + it.bobotSdBulanIni);
  double get subtotalBobotSisa => items.fold(0.0, (s, it) => s + it.sisaBobot);
}

class MonthlyReportModel {
  final int bulanKe;
  final String bulanRomawi;
  final String namaBulan;
  final String periodeFormatted;
  final int mingguMulai;
  final int mingguSelesai;
  final List<int> mingguTersedia;
  final String status; // 'Selesai', 'Sedang Berjalan', 'Belum Ada Data'
  final String statusDetail;

  final List<MonthlyBoQDivision> divisions;
  final double totalBobotCCO;
  final double totalBobotBulanLalu;
  final double totalBobotBulanIni;
  final double totalBobotSdBulanIni;
  final double totalBobotSisa;

  final double rencanaFisikPersen;
  final double realisasiKumulatifPersen;
  final double deviasiPersen;

  // Metadata proyek
  final String namaKegiatan;
  final String lokasi;
  final String sumberDana;
  final String pelaksanaKontraktor;
  final String noKontrak;
  final String konsultanPengawas;
  final String noKontrakPengawas;

  // Data Tanda Tangan & Pengesahan Digital (3 Pihak)
  final List<Map<String, dynamic>>? ttdList;
  final String? ttdKontraktorNama;
  final String? ttdKontraktorJabatan;
  final String? ttdKontraktorSignature;
  final String? ttdKontraktorTanggal;

  final String? ttdKonsultanNama;
  final String? ttdKonsultanJabatan;
  final String? ttdKonsultanSignature;
  final String? ttdKonsultanTanggal;

  final String? ttdPpkNama;
  final String? ttdPpkJabatan;
  final String? ttdPpkSignature;
  final String? ttdPpkTanggal;

  MonthlyReportModel({
    required this.bulanKe,
    required this.bulanRomawi,
    required this.namaBulan,
    required this.periodeFormatted,
    required this.mingguMulai,
    required this.mingguSelesai,
    required this.mingguTersedia,
    required this.status,
    required this.statusDetail,
    required this.divisions,
    required this.totalBobotCCO,
    required this.totalBobotBulanLalu,
    required this.totalBobotBulanIni,
    required this.totalBobotSdBulanIni,
    required this.totalBobotSisa,
    required this.rencanaFisikPersen,
    required this.realisasiKumulatifPersen,
    required this.deviasiPersen,
    required this.namaKegiatan,
    required this.lokasi,
    required this.sumberDana,
    required this.pelaksanaKontraktor,
    required this.noKontrak,
    required this.konsultanPengawas,
    required this.noKontrakPengawas,
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
  });

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

  MonthlyReportModel copyWithSignatures({
    List<Map<String, dynamic>>? ttdList,
    String? ttdKontraktorNama,
    String? ttdKontraktorJabatan,
    String? ttdKontraktorSignature,
    String? ttdKontraktorTanggal,
    String? ttdKonsultanNama,
    String? ttdKonsultanJabatan,
    String? ttdKonsultanSignature,
    String? ttdKonsultanTanggal,
    String? ttdPpkNama,
    String? ttdPpkJabatan,
    String? ttdPpkSignature,
    String? ttdPpkTanggal,
  }) {
    return MonthlyReportModel(
      bulanKe: bulanKe,
      bulanRomawi: bulanRomawi,
      namaBulan: namaBulan,
      periodeFormatted: periodeFormatted,
      mingguMulai: mingguMulai,
      mingguSelesai: mingguSelesai,
      mingguTersedia: mingguTersedia,
      status: status,
      statusDetail: statusDetail,
      divisions: divisions,
      totalBobotCCO: totalBobotCCO,
      totalBobotBulanLalu: totalBobotBulanLalu,
      totalBobotBulanIni: totalBobotBulanIni,
      totalBobotSdBulanIni: totalBobotSdBulanIni,
      totalBobotSisa: totalBobotSisa,
      rencanaFisikPersen: rencanaFisikPersen,
      realisasiKumulatifPersen: realisasiKumulatifPersen,
      deviasiPersen: deviasiPersen,
      namaKegiatan: namaKegiatan,
      lokasi: lokasi,
      sumberDana: sumberDana,
      pelaksanaKontraktor: pelaksanaKontraktor,
      noKontrak: noKontrak,
      konsultanPengawas: konsultanPengawas,
      noKontrakPengawas: noKontrakPengawas,
      ttdList: ttdList ?? this.ttdList,
      ttdKontraktorNama: ttdKontraktorNama ?? this.ttdKontraktorNama,
      ttdKontraktorJabatan: ttdKontraktorJabatan ?? this.ttdKontraktorJabatan,
      ttdKontraktorSignature: ttdKontraktorSignature ?? this.ttdKontraktorSignature,
      ttdKontraktorTanggal: ttdKontraktorTanggal ?? this.ttdKontraktorTanggal,
      ttdKonsultanNama: ttdKonsultanNama ?? this.ttdKonsultanNama,
      ttdKonsultanJabatan: ttdKonsultanJabatan ?? this.ttdKonsultanJabatan,
      ttdKonsultanSignature: ttdKonsultanSignature ?? this.ttdKonsultanSignature,
      ttdKonsultanTanggal: ttdKonsultanTanggal ?? this.ttdKonsultanTanggal,
      ttdPpkNama: ttdPpkNama ?? this.ttdPpkNama,
      ttdPpkJabatan: ttdPpkJabatan ?? this.ttdPpkJabatan,
      ttdPpkSignature: ttdPpkSignature ?? this.ttdPpkSignature,
      ttdPpkTanggal: ttdPpkTanggal ?? this.ttdPpkTanggal,
    );
  }

  static String toRoman(int number) {
    switch (number) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      case 4:
        return 'IV';
      case 5:
        return 'V';
      case 6:
        return 'VI';
      case 7:
        return 'VII';
      case 8:
        return 'VIII';
      case 9:
        return 'IX';
      case 10:
        return 'X';
      default:
        return number.toString();
    }
  }

  static List<Map<String, dynamic>> _flattenBoqItems(List? boqProgressList) {
    if (boqProgressList == null || boqProgressList.isEmpty) return [];
    final List<Map<String, dynamic>> result = [];
    for (final entry in boqProgressList) {
      if (entry is Map) {
        if (entry['items'] is List) {
          for (final it in (entry['items'] as List)) {
            if (it is Map) result.add(Map<String, dynamic>.from(it));
          }
        } else {
          result.add(Map<String, dynamic>.from(entry));
        }
      }
    }
    return result;
  }

  static double _getSdVolume(Map<String, dynamic>? item) {
    if (item == null) return 0.0;
    final val = item['sdMingguIniVolume'] ??
        item['volumeSdMingguIni'] ??
        item['volumeKumulatif'] ??
        item['volume'];
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '0') ?? 0.0;
  }

  static Map<String, dynamic>? _findMatchingItem(
    List<Map<String, dynamic>> items,
    String noMata,
    String uraian,
  ) {
    final cleanNoMata = noMata.trim();
    final cleanUraian = uraian.toLowerCase().trim();
    for (final it in items) {
      final itemNoMata = (it['noMataPembayaran'] ?? '').toString().trim();
      final itemUraian = (it['uraian'] ?? it['nama'] ?? '').toString().toLowerCase().trim();
      if (cleanNoMata.isNotEmpty && itemNoMata == cleanNoMata) return it;
      if (cleanUraian.isNotEmpty && (itemUraian == cleanUraian || cleanUraian.contains(itemUraian) || itemUraian.contains(cleanUraian))) return it;
    }
    return null;
  }

  static double _calcVolFromDailyReports(
    List dailyReports,
    String noMata,
    String uraian,
    DateTime? maxDate,
  ) {
    if (dailyReports.isEmpty) return 0.0;
    final cleanNoMata = noMata.trim();
    final cleanUraian = uraian.trim().toLowerCase();
    double total = 0.0;

    for (final rep in dailyReports) {
      if (rep is! Map) continue;
      if (maxDate != null) {
        final repTglStr = rep['tanggal']?.toString() ?? '';
        final repDate = WeeklyReportModel.parseIndonesianDate(repTglStr) ?? DateTime.tryParse(repTglStr);
        if (repDate != null) {
          final repDay = DateTime(repDate.year, repDate.month, repDate.day);
          final maxDay = DateTime(maxDate.year, maxDate.month, maxDate.day);
          if (repDay.isAfter(maxDay)) continue;
        }
      }

      final pList = (rep['pekerjaanList'] as List?) ?? [];
      for (final p in pList) {
        if (p is! Map) continue;
        final pNoMata = p['noMataPembayaran']?.toString().trim() ?? '';
        final pUraian = (p['uraian'] ?? p['jenis'])?.toString().trim().toLowerCase() ?? '';
        final matchNoMata = cleanNoMata.isNotEmpty && pNoMata == cleanNoMata;
        final matchUraian = cleanUraian.isNotEmpty && (pUraian == cleanUraian || cleanUraian.contains(pUraian) || pUraian.contains(cleanUraian));

        if (matchNoMata || matchUraian) {
          final vStr = (p['volume'] ?? '').toString();
          final vNum = double.tryParse(vStr.split(' ').first.replaceAll(',', '.')) ?? 0.0;
          total += vNum;
        }
      }
    }

    return total;
  }

  /// Menghasilkan daftar Laporan Bulanan secara otomatis (tiap blok 4 minggu)
  /// berdasarkan data ContractModel dan Kegiatan.
  static List<MonthlyReportModel> generateFromWeeklyReports({
    required ContractModel contract,
    required dynamic kegiatan, // Map<String, dynamic> or KegiatanModel
  }) {
    final Map<String, dynamic> kegMap = (kegiatan is KegiatanModel)
        ? kegiatan.toJson()
        : Map<String, dynamic>.from(kegiatan as Map);

    final kegModel = (kegiatan is KegiatanModel)
        ? kegiatan
        : KegiatanModel.fromJson(kegMap, fallbackContract: contract);

    final List dailyReports = (kegMap['laporans'] as List?) ?? [];

    // Ambil list divisi aktif (Addendum CCO terakhir jika ada, atau Kontrak Awal)
    final List<Map<String, dynamic>> activeDivisiList = kegModel.activeRkkDivisiList;

    // Ambil seluruh laporan mingguan
    final List rawMingguan = (kegMap['laporanMingguan'] as List?) ?? [];
    final List<WeeklyReportModel> weeklyReports = rawMingguan
        .map((w) => (w is WeeklyReportModel)
            ? w
            : WeeklyReportModel.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();

    weeklyReports.sort((a, b) => a.mingguKe.compareTo(b.mingguKe));

    // Tentukan total minggu kontrak kegiatan
    int totalWeeks = 13;
    if (kegMap['minggu'] != null) {
      final parsed = int.tryParse(kegMap['minggu'].toString());
      if (parsed != null && parsed > 0) totalWeeks = parsed;
    } else if (contract.hariKalender > 0) {
      totalWeeks = (contract.hariKalender / 7.0).ceil();
    }

    // Pastikan totalWeeks minimal mengakomodasi minggu terakhir yang ada
    if (weeklyReports.isNotEmpty && weeklyReports.last.mingguKe > totalWeeks) {
      totalWeeks = weeklyReports.last.mingguKe;
    }

    // Hitung berapa bulan (setiap 4 minggu adalah 1 bulan)
    final int totalMonths = (totalWeeks / 4.0).ceil();
    final List<MonthlyReportModel> monthlyReports = [];

    // Metadata kontrak
    final namaKegiatan = kegModel.namaKegiatan.isNotEmpty
        ? kegModel.namaKegiatan
        : contract.namaKontrak;
    final lokasi = kegModel.lokasi.isNotEmpty
        ? kegModel.lokasi
        : 'Kab. Purbalingga';
    final sumberDana = kegModel.sumberDana.isNotEmpty
        ? kegModel.sumberDana
        : contract.sumberDana;
    final pelaksanaKontraktor = kegModel.kontraktor.isNotEmpty
        ? kegModel.kontraktor
        : 'CV. DIVAN INSAN CEMERLANG';
    final noKontrak = kegModel.noSuratPesanan.isNotEmpty
        ? kegModel.noSuratPesanan
        : contract.nomorSpk;
    final konsultanPengawas = kegModel.konsultanPengawas.isNotEmpty
        ? kegModel.konsultanPengawas
        : 'CV. TATA SAKA CONSULTANT';
    final noKontrakPengawas = kegModel.noSpkKonsultan.isNotEmpty
        ? kegModel.noSpkKonsultan
        : contract.nomorSpmk;

    for (int monthIdx = 1; monthIdx <= totalMonths; monthIdx++) {
      final int startWeek = (monthIdx - 1) * 4 + 1;
      final int endWeek = min(monthIdx * 4, totalWeeks);

      // Cari laporan mingguan yang masuk dalam rentang startWeek..endWeek
      final weeksInMonth = weeklyReports
          .where((w) => w.mingguKe >= startWeek && w.mingguKe <= endWeek)
          .toList();
      final List<int> mingguTersedia = weeksInMonth.map((w) => w.mingguKe).toList();

      // Cari laporan mingguan sebelum bulan ini (s.d. startWeek - 1)
      final weeksBefore = weeklyReports.where((w) => w.mingguKe < startWeek).toList();
      final WeeklyReportModel? latestBefore =
          weeksBefore.isNotEmpty ? weeksBefore.last : null;

      // Status bulan
      String status;
      String statusDetail;
      if (weeksInMonth.isEmpty) {
        status = 'Belum Ada Data';
        statusDetail = 'Rencana (M-$startWeek s.d. M-$endWeek)';
      } else if (weeksInMonth.length == (endWeek - startWeek + 1)) {
        status = 'Selesai';
        statusDetail = 'Lengkap (M-$startWeek s.d. M-$endWeek)';
      } else {
        final minW = mingguTersedia.reduce(min);
        final maxW = mingguTersedia.reduce(max);
        status = 'Sedang Berjalan';
        statusDetail = (minW == maxW)
            ? 'Sedang Berjalan (M-$minW)'
            : 'Sedang Berjalan (M-$minW s.d. M-$maxW)';
      }

      // Periode Tanggal
      String periodeFormatted;
      if (weeksInMonth.isNotEmpty) {
        final firstWeek = weeksInMonth.first;
        final lastWeek = weeksInMonth.last;
        periodeFormatted = '${firstWeek.periodeAwal} - ${lastWeek.periodeAkhir}';
      } else {
        periodeFormatted = 'Minggu $startWeek s.d. Minggu $endWeek';
      }

      // Laporan mingguan referensi s/d akhir bulan berjalan
      final WeeklyReportModel? currentLatestWeek =
          weeksInMonth.isNotEmpty ? weeksInMonth.last : null;

      // Rencana, Realisasi, Deviasi
      double rencanaFisik = 0.0;
      double realisasiKumulatif = 0.0;
      double deviasi = 0.0;

      if (currentLatestWeek != null) {
        rencanaFisik = currentLatestWeek.rencanaPersen;
        realisasiKumulatif = currentLatestWeek.realisasiPersen;
        deviasi = currentLatestWeek.deviasiPersen;
      } else if (latestBefore != null) {
        rencanaFisik = latestBefore.rencanaPersen;
        realisasiKumulatif = latestBefore.realisasiPersen;
        deviasi = latestBefore.deviasiPersen;
      }

      // Extract flat items from Weekly boqProgressList
      final prevItems = _flattenBoqItems(latestBefore?.boqProgressList);
      final currItems = _flattenBoqItems(currentLatestWeek?.boqProgressList);

      // Hitung rincian tabel per divisi dan item BoQ
      final List<MonthlyBoQDivision> divisions = [];
      double totalBobotCCO = 0.0;
      double totalBobotBulanLalu = 0.0;
      double totalBobotBulanIni = 0.0;
      double totalBobotSdBulanIni = 0.0;
      double totalBobotSisa = 0.0;

      for (int divIndex = 0; divIndex < activeDivisiList.length; divIndex++) {
        final div = activeDivisiList[divIndex];
        final String kode = (div['nomorRomawi'] ?? div['kode'] ?? (divIndex + 1).toString()).toString();
        final String namaDivisi = (div['namaDivisi'] ?? div['nama'] ?? 'DIVISI').toString();
        final List rawItems = (div['items'] as List?) ?? [];

        final List<MonthlyBoQItem> boqItems = [];

        for (int itIndex = 0; itIndex < rawItems.length; itIndex++) {
          final it = rawItems[itIndex] as Map;
          final String itemNo = (it['no'] ?? (itIndex + 1).toString()).toString();
          final String noMataPembayaran = (it['noMataPembayaran'] ?? '').toString();
          final String uraian = (it['uraian'] ?? it['nama'] ?? '').toString();
          final String satuan = (it['satuan'] ?? '').toString();
          final double volCCO = (it['volume'] as num?)?.toDouble() ?? 0.0;
          final double bbtCCO = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;

          // 1. Hitung akumulasi volume s.d. Bulan Lalu (minggu sebelum bulan ini)
          double volBulanLalu = 0.0;
          if (prevItems.isNotEmpty) {
            final prevMatch = _findMatchingItem(prevItems, noMataPembayaran, uraian);
            volBulanLalu = _getSdVolume(prevMatch);
          } else if (latestBefore != null) {
            final endDtBefore = WeeklyReportModel.parseIndonesianDate(latestBefore.periodeAkhir);
            volBulanLalu = _calcVolFromDailyReports(dailyReports, noMataPembayaran, uraian, endDtBefore);
          }

          // 2. Hitung akumulasi volume s.d. Bulan Ini (minggu terakhir yang tersedia di bulan ini)
          double volSdBulanIni = volBulanLalu;
          if (currItems.isNotEmpty) {
            final currMatch = _findMatchingItem(currItems, noMataPembayaran, uraian);
            volSdBulanIni = _getSdVolume(currMatch);
          } else if (currentLatestWeek != null) {
            final endDtCurrent = WeeklyReportModel.parseIndonesianDate(currentLatestWeek.periodeAkhir);
            volSdBulanIni = _calcVolFromDailyReports(dailyReports, noMataPembayaran, uraian, endDtCurrent);
          }

          // 3. Volume Bulan Ini = S/D Bulan Ini - Bulan Lalu
          final double volBulanIni = max(0.0, volSdBulanIni - volBulanLalu);

          // 4. Hitung Bobot %
          final double bbtBulanLalu = (volCCO > 0)
              ? (volBulanLalu / volCCO) * bbtCCO
              : 0.0;
          final double bbtBulanIni = (volCCO > 0)
              ? (volBulanIni / volCCO) * bbtCCO
              : 0.0;
          final double bbtSdBulanIni = (volCCO > 0)
              ? (volSdBulanIni / volCCO) * bbtCCO
              : 0.0;

          // 5. Sisa Pekerjaan
          final double sisaVolume = max(0.0, volCCO - volSdBulanIni);
          final double sisaBobot = max(0.0, bbtCCO - bbtSdBulanIni);

          boqItems.add(
            MonthlyBoQItem(
              no: itemNo,
              noMataPembayaran: noMataPembayaran,
              uraian: uraian,
              satuan: satuan,
              volumeCCO: volCCO,
              bobotCCO: bbtCCO,
              volumeBulanLalu: volBulanLalu,
              bobotBulanLalu: bbtBulanLalu,
              volumeBulanIni: volBulanIni,
              bobotBulanIni: bbtBulanIni,
              volumeSdBulanIni: volSdBulanIni,
              bobotSdBulanIni: bbtSdBulanIni,
              sisaVolume: sisaVolume,
              sisaBobot: sisaBobot,
            ),
          );

          totalBobotCCO += bbtCCO;
          totalBobotBulanLalu += bbtBulanLalu;
          totalBobotBulanIni += bbtBulanIni;
          totalBobotSdBulanIni += bbtSdBulanIni;
          totalBobotSisa += sisaBobot;
        }

        divisions.add(
          MonthlyBoQDivision(
            kode: kode,
            nama: namaDivisi,
            items: boqItems,
          ),
        );
      }

      // Tanda tangan tersimpan untuk bulan ini
      final rawBulananList = (kegMap['laporanBulanan'] as List?) ?? [];
      final savedBulanan = rawBulananList.cast<dynamic>().firstWhere(
            (b) => b is Map && (b['bulanKe'] == monthIdx || b['bulanKe']?.toString() == '$monthIdx'),
            orElse: () => null,
          );

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

      if (savedBulanan != null) {
        final Map<String, dynamic> bMap = Map<String, dynamic>.from(savedBulanan as Map);
        if (bMap['ttdList'] != null) {
          ttdList = List<Map<String, dynamic>>.from(
              (bMap['ttdList'] as List).map((e) => Map<String, dynamic>.from(e)));
        }
        ttdKontraktorNama = bMap['ttdKontraktorNama']?.toString();
        ttdKontraktorJabatan = bMap['ttdKontraktorJabatan']?.toString();
        ttdKontraktorSignature = bMap['ttdKontraktorSignature']?.toString();
        ttdKontraktorTanggal = bMap['ttdKontraktorTanggal']?.toString();

        ttdKonsultanNama = bMap['ttdKonsultanNama']?.toString();
        ttdKonsultanJabatan = bMap['ttdKonsultanJabatan']?.toString();
        ttdKonsultanSignature = bMap['ttdKonsultanSignature']?.toString();
        ttdKonsultanTanggal = bMap['ttdKonsultanTanggal']?.toString();

        ttdPpkNama = bMap['ttdPpkNama']?.toString();
        ttdPpkJabatan = bMap['ttdPpkJabatan']?.toString();
        ttdPpkSignature = bMap['ttdPpkSignature']?.toString();
        ttdPpkTanggal = bMap['ttdPpkTanggal']?.toString();
      } else {
        ttdKontraktorNama = pelaksanaKontraktor;
        ttdKontraktorJabatan = 'Kontraktor Pelaksana';
        ttdKonsultanNama = contract.siteEngineer;
        ttdKonsultanJabatan = 'Konsultan Supervisi\nCV. TATA SAKA CONSULTANT';
        ttdPpkNama = kegModel.penggunaAnggaran.isNotEmpty
            ? kegModel.penggunaAnggaran
            : (kegMap['penggunaAnggaran']?.toString() ?? '');
        ttdPpkJabatan = 'Pejabat Pembuat Komitmen (PPK)\nDPU-PR Kab. Purbalingga';
        ttdPpkTanggal = periodeFormatted.split('-').last.trim();
      }

      monthlyReports.add(
        MonthlyReportModel(
          bulanKe: monthIdx,
          bulanRomawi: toRoman(monthIdx),
          namaBulan: (startWeek == endWeek)
              ? 'Minggu $startWeek'
              : 'Minggu $startWeek - $endWeek',
          periodeFormatted: periodeFormatted,
          mingguMulai: startWeek,
          mingguSelesai: endWeek,
          mingguTersedia: mingguTersedia,
          status: status,
          statusDetail: statusDetail,
          divisions: divisions,
          totalBobotCCO: totalBobotCCO,
          totalBobotBulanLalu: totalBobotBulanLalu,
          totalBobotBulanIni: totalBobotBulanIni,
          totalBobotSdBulanIni: totalBobotSdBulanIni,
          totalBobotSisa: totalBobotSisa,
          rencanaFisikPersen: rencanaFisik,
          realisasiKumulatifPersen: realisasiKumulatif,
          deviasiPersen: deviasi,
          namaKegiatan: namaKegiatan,
          lokasi: lokasi,
          sumberDana: sumberDana,
          pelaksanaKontraktor: pelaksanaKontraktor,
          noKontrak: noKontrak,
          konsultanPengawas: konsultanPengawas,
          noKontrakPengawas: noKontrakPengawas,
          ttdList: ttdList,
          ttdKontraktorNama: ttdKontraktorNama,
          ttdKontraktorJabatan: ttdKontraktorJabatan,
          ttdKontraktorSignature: ttdKontraktorSignature,
          ttdKontraktorTanggal: ttdKontraktorTanggal,
          ttdKonsultanNama: ttdKonsultanNama,
          ttdKonsultanJabatan: ttdKonsultanJabatan,
          ttdKonsultanSignature: ttdKonsultanSignature,
          ttdKonsultanTanggal: ttdKonsultanTanggal,
          ttdPpkNama: ttdPpkNama,
          ttdPpkJabatan: ttdPpkJabatan,
          ttdPpkSignature: ttdPpkSignature,
          ttdPpkTanggal: ttdPpkTanggal,
        ),
      );
    }

    return monthlyReports;
  }
}
