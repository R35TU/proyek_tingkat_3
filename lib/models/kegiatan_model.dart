import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/utils/indonesian_terbilang.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';

class KegiatanModel {
  String namaKegiatan;
  String lokasi;
  String sumberDana;

  // KONSULTAN PENGAWAS
  String konsultanPengawas;
  String noSpkKonsultan;
  String tglSpkKonsultan;
  String noSpmkKonsultan;
  String tglSpmkKonsultan;
  String awalPelaksanaan;
  String akhirPelaksanaan;
  String masaPelaksanaan;
  String waktuBerjalan;

  // PENYEDIA JASA / KONTRAKTOR PELAKSANA
  String kontraktor;
  String kontraktorUid;
  String noSuratPesanan;
  String tglSuratPesanan;
  String noSpmkKontraktor;
  String tglSpmkKontraktor;
  String nilaiKontrak;
  String jangkaWaktu;

  // STRUKTUR ORGANISASI KEGIATAN
  String penggunaAnggaran;
  String stafTeknis1;
  String stafTeknis2;

  // STRUKTUR ORGANISASI KONSULTAN
  String direkturKonsultan;
  String siteEngineerKegiatan;

  // STRUKTUR ORGANISASI PENYEDIA JASA
  String pelaksanaLapangan;
  String petugasK3;

  // Backward compatibility getters & setters
  String get direkturPenyedia => direkturKonsultan;
  set direkturPenyedia(String v) => direkturKonsultan = v;
  String get direkturKontraktor => direkturKonsultan;
  set direkturKontraktor(String v) => direkturKonsultan = v;

  // Dokumen & Laporan
  List<Map<String, dynamic>> folders;
  List<dynamic> laporans;
  List<dynamic> laporanMingguan;

  // Master Data Rincian Kuantitas & Bobot Pekerjaan (RKK / BoQ Kontrak)
  List<Map<String, dynamic>> rkkDivisiList;
  List<Map<String, dynamic>> rkkKontrakAwal;
  List<Map<String, dynamic>> addendums;

  /// Mengembalikan RKK yang sedang aktif.
  /// Jika sudah ada addendum (CCO), mengembalikan rkkDivisiList dari addendum terakhir.
  /// Jika belum ada addendum, mengembalikan rkkDivisiList (Kontrak Awal).
  List<Map<String, dynamic>> get activeRkkDivisiList {
    if (addendums.isNotEmpty) {
      final latest = addendums.last;
      final divList = latest['rkkDivisiList'] as List?;
      if (divList != null && divList.isNotEmpty) {
        return divList.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return (rkkKontrakAwal.isNotEmpty) ? rkkKontrakAwal : rkkDivisiList;
  }

  bool get hasAddendum => addendums.isNotEmpty;
  int get totalAddendumCount => addendums.length;
  Map<String, dynamic>? get latestAddendum => addendums.isNotEmpty ? addendums.last : null;

  /// Nilai persentase progres fisik kegiatan (0.0 s.d. 100.0%).
  double get currentProgresFisik => ProgressCalculator.calculateKegiatanProgress(toJson());

  KegiatanModel({
    required this.namaKegiatan,
    this.lokasi = '',
    this.sumberDana = '',
    this.konsultanPengawas = 'CV. TATA SAKA CONSULTANT',
    this.noSpkKonsultan = '',
    this.tglSpkKonsultan = '',
    this.noSpmkKonsultan = '',
    this.tglSpmkKonsultan = '',
    this.awalPelaksanaan = '',
    this.akhirPelaksanaan = '',
    this.masaPelaksanaan = '',
    this.waktuBerjalan = '',
    this.kontraktor = '',
    this.kontraktorUid = '',
    this.noSuratPesanan = '',
    this.tglSuratPesanan = '',
    this.noSpmkKontraktor = '',
    this.tglSpmkKontraktor = '',
    this.nilaiKontrak = '',
    this.jangkaWaktu = '',
    this.penggunaAnggaran = '',
    this.stafTeknis1 = '',
    this.stafTeknis2 = '',
    this.siteEngineerKegiatan = '',
    this.direkturKonsultan = '',
    String? direkturPenyedia,
    String? direkturKontraktor,
    this.pelaksanaLapangan = '',
    this.petugasK3 = '',
    List<Map<String, dynamic>>? folders,
    List<dynamic>? laporans,
    List<dynamic>? laporanMingguan,
    List<Map<String, dynamic>>? rkkDivisiList,
    List<Map<String, dynamic>>? rkkKontrakAwal,
    List<Map<String, dynamic>>? addendums,
  })  : folders = folders ?? [
          {'name': 'Laporan Harian', 'isExpanded': false, 'documents': []},
          {'name': 'Laporan Mingguan', 'isExpanded': false, 'documents': []},
          {'name': 'Foto Progres', 'isExpanded': false, 'documents': []},
        ],
        laporans = laporans ?? [],
        laporanMingguan = laporanMingguan ?? [],
        rkkDivisiList = rkkDivisiList ?? [],
        rkkKontrakAwal = rkkKontrakAwal ?? (rkkDivisiList != null ? List<Map<String, dynamic>>.from(rkkDivisiList) : []),
        addendums = addendums ?? [] {
    if (direkturKonsultan.isEmpty && (direkturPenyedia != null || direkturKontraktor != null)) {
      direkturKonsultan = direkturPenyedia ?? direkturKontraktor ?? '';
    }
  }

  /// Menghitung Waktu yang Telah Berjalan secara dinamis berdasarkan Awal Pelaksanaan vs Hari ini
  static String calculateWaktuBerjalan(String awalPelaksanaanStr) {
    final awalDt = WeeklyReportModel.parseIndonesianDate(awalPelaksanaanStr);
    if (awalDt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(awalDt.year, awalDt.month, awalDt.day);

    if (today.isBefore(start)) {
      return '0 (Nol) Minggu';
    }

    final diffDays = today.difference(start).inDays + 1;
    final weeks = (diffDays / 7).ceil();
    return IndonesianTerbilang.formatMinggu(weeks);
  }

  /// Format gabungan resmi: "000.3.2/.../2026 Tanggal 26 Mei 2026"
  String get spkKonsultanFull {
    final no = noSpkKonsultan.trim();
    final tgl = tglSpkKonsultan.trim();
    if (no.isEmpty && tgl.isEmpty) return '-';
    if (tgl.isEmpty) return no;
    if (no.isEmpty) return 'Tanggal $tgl';
    return '$no Tanggal $tgl';
  }

  /// Format gabungan resmi SPMK Konsultan: "000.3.2/.../2026 Tanggal 18 Juni 2026"
  String get spmkKonsultanFull {
    final no = noSpmkKonsultan.trim();
    final tgl = tglSpmkKonsultan.trim();
    if (no.isEmpty && tgl.isEmpty) return '-';
    if (tgl.isEmpty) return no;
    if (no.isEmpty) return 'Tanggal $tgl';
    return '$no Tanggal $tgl';
  }

  /// Format gabungan resmi Surat Pesanan Kontraktor: "EP-01... Tanggal 18 Juni 2026"
  String get suratPesananFull {
    final no = noSuratPesanan.trim();
    final tgl = tglSuratPesanan.trim();
    if (no.isEmpty && tgl.isEmpty) return '-';
    if (tgl.isEmpty) return no;
    final tglClean = tgl.toLowerCase().startsWith('tanggal ') ? tgl.substring(8).trim() : tgl;
    if (no.isEmpty) return 'Tanggal $tglClean';
    return '$no Tanggal $tglClean';
  }

  /// Format gabungan resmi SPMK Kontraktor: "000.3.3 / ... Tanggal 18 Juni 2026"
  String get spmkKontraktorFull {
    final no = noSpmkKontraktor.trim();
    final tgl = tglSpmkKontraktor.trim();
    if (no.isEmpty && tgl.isEmpty) return '-';
    if (tgl.isEmpty) return no;
    final tglClean = tgl.toLowerCase().startsWith('tanggal ') ? tgl.substring(8).trim() : tgl;
    if (no.isEmpty) return 'Tanggal $tglClean';
    return '$no Tanggal $tglClean';
  }

  /// Format gabungan staf teknis: "MUBALLIGH, ST.,M.Sc. & BILAL A.Md"
  String get stafTeknisDisplay {
    final s1 = stafTeknis1.trim();
    final s2 = stafTeknis2.trim();
    if (s1.isNotEmpty && s2.isNotEmpty) {
      return '$s1 & $s2';
    } else if (s1.isNotEmpty) {
      return s1;
    } else {
      return s2;
    }
  }

  String get stafTeknisLabel {
    final s1 = stafTeknis1.trim();
    final s2 = stafTeknis2.trim();
    if (s1.isNotEmpty && s2.isNotEmpty) {
      return 'Staf Teknis 1 & 2';
    } else if (s1.isNotEmpty) {
      return 'Staf Teknis 1';
    } else if (s2.isNotEmpty) {
      return 'Staf Teknis 2';
    }
    return 'Staf Teknis';
  }

  factory KegiatanModel.fromJson(Map<String, dynamic> json, {ContractModel? fallbackContract}) {
    final namaKegiatan = json['namaKegiatan'] ?? '';
    final lokasi = json['lokasi'] ?? '';
    final sumberDana = (json['sumberDana'] != null && json['sumberDana'].toString().isNotEmpty)
        ? json['sumberDana'].toString()
        : (fallbackContract?.sumberDana ?? '');

    final konsultanPengawas = (json['konsultanPengawas'] != null && json['konsultanPengawas'].toString().isNotEmpty)
        ? json['konsultanPengawas'].toString()
        : 'CV. TATA SAKA CONSULTANT';

    final noSpkKonsultan = (json['noSpkKonsultan'] != null && json['noSpkKonsultan'].toString().isNotEmpty)
        ? json['noSpkKonsultan'].toString()
        : (fallbackContract?.nomorSpk ?? '');

    final tglSpkKonsultan = (json['tglSpkKonsultan'] != null && json['tglSpkKonsultan'].toString().isNotEmpty)
        ? json['tglSpkKonsultan'].toString()
        : (fallbackContract?.tglMulaiSpk ?? '');

    final noSpmkKonsultan = (json['noSpmkKonsultan'] != null && json['noSpmkKonsultan'].toString().isNotEmpty)
        ? json['noSpmkKonsultan'].toString()
        : (fallbackContract?.nomorSpmk ?? '');

    final tglSpmkKonsultan = (json['tglSpmkKonsultan'] != null && json['tglSpmkKonsultan'].toString().isNotEmpty)
        ? json['tglSpmkKonsultan'].toString()
        : (fallbackContract?.tglMulaiSpmk ?? '');

    final awalPelaksanaan = (json['awalPelaksanaan'] != null && json['awalPelaksanaan'].toString().isNotEmpty)
        ? json['awalPelaksanaan'].toString()
        : (fallbackContract?.tglMulaiSpmk ?? '');

    final akhirPelaksanaan = (json['akhirPelaksanaan'] != null && json['akhirPelaksanaan'].toString().isNotEmpty)
        ? json['akhirPelaksanaan'].toString()
        : (fallbackContract?.tglSelesaiSpmk ?? '');

    final masaPelaksanaan = (json['masaPelaksanaan'] != null && json['masaPelaksanaan'].toString().isNotEmpty)
        ? json['masaPelaksanaan'].toString()
        : (fallbackContract != null && fallbackContract.hariKalender > 0
            ? IndonesianTerbilang.formatHariKalender(fallbackContract.hariKalender)
            : '');

    final waktuBerjalan = (json['waktuBerjalan'] != null && json['waktuBerjalan'].toString().isNotEmpty)
        ? json['waktuBerjalan'].toString()
        : calculateWaktuBerjalan(awalPelaksanaan);

    final kontraktor = json['kontraktor'] ?? '';
    final kontraktorUid = json['kontraktorUid'] ?? '';
    final noSuratPesanan = json['noSuratPesanan'] ?? '';
    final tglSuratPesanan = (json['tglSuratPesanan'] != null && json['tglSuratPesanan'].toString().isNotEmpty)
        ? json['tglSuratPesanan'].toString()
        : (fallbackContract?.tglMulaiSpk ?? '');
    final noSpmkKontraktor = json['noSpmkKontraktor'] ?? '';
    final tglSpmkKontraktor = (json['tglSpmkKontraktor'] != null && json['tglSpmkKontraktor'].toString().isNotEmpty)
        ? json['tglSpmkKontraktor'].toString()
        : (fallbackContract?.tglMulaiSpmk ?? '');
    final nilaiKontrak = json['nilaiKontrak'] ?? '';

    final jangkaWaktu = (json['jangkaWaktu'] != null && json['jangkaWaktu'].toString().isNotEmpty)
        ? json['jangkaWaktu'].toString()
        : (fallbackContract != null && fallbackContract.hariKalender > 0
            ? IndonesianTerbilang.formatHariKalender(fallbackContract.hariKalender)
            : '');

    // Struktur Organisasi Kegiatan
    final penggunaAnggaran = json['penggunaAnggaran'] ??
        json['strukturOrganisasiKegiatan']?['penggunaAnggaran'] ??
        '';
    final stafTeknis1 = json['stafTeknis1'] ??
        json['stafTeknis'] ??
        json['strukturOrganisasiKegiatan']?['stafTeknis1'] ??
        json['strukturOrganisasiKegiatan']?['stafTeknis'] ??
        '';
    final stafTeknis2 = json['stafTeknis2'] ??
        json['strukturOrganisasiKegiatan']?['stafTeknis2'] ??
        '';
    final siteEngineerKegiatan = json['siteEngineerKegiatan'] ??
        json['siteEngineer'] ??
        json['strukturOrganisasiKegiatan']?['siteEngineer'] ??
        json['strukturOrganisasiKonsultan']?['siteEngineer'] ??
        (fallbackContract?.siteEngineer ?? '');
    final direkturKonsultan = (json['direkturKonsultan'] != null && json['direkturKonsultan'].toString().isNotEmpty)
        ? json['direkturKonsultan'].toString()
        : (json['direkturPenyedia'] ??
            json['direkturKontraktor'] ??
            json['direktur'] ??
            json['strukturOrganisasiKegiatan']?['direkturPenyedia'] ??
            json['strukturOrganisasiKonsultan']?['direkturKonsultan'] ??
            json['strukturPenyediaJasa']?['direktur'] ??
            '').toString();

    // Struktur Organisasi Penyedia Jasa
    final pelaksanaLapangan = json['pelaksanaLapangan'] ??
        json['strukturPenyediaJasa']?['pelaksanaLapangan'] ??
        '';
    final petugasK3 = json['petugasK3'] ??
        json['ahliK3'] ??
        json['strukturPenyediaJasa']?['petugasK3'] ??
        '';

    return KegiatanModel(
      namaKegiatan: namaKegiatan,
      lokasi: lokasi,
      sumberDana: sumberDana,
      konsultanPengawas: konsultanPengawas,
      noSpkKonsultan: noSpkKonsultan,
      tglSpkKonsultan: tglSpkKonsultan,
      noSpmkKonsultan: noSpmkKonsultan,
      tglSpmkKonsultan: tglSpmkKonsultan,
      awalPelaksanaan: awalPelaksanaan,
      akhirPelaksanaan: akhirPelaksanaan,
      masaPelaksanaan: masaPelaksanaan,
      waktuBerjalan: waktuBerjalan,
      kontraktor: kontraktor,
      kontraktorUid: kontraktorUid,
      noSuratPesanan: noSuratPesanan,
      tglSuratPesanan: tglSuratPesanan,
      noSpmkKontraktor: noSpmkKontraktor,
      tglSpmkKontraktor: tglSpmkKontraktor,
      nilaiKontrak: nilaiKontrak,
      jangkaWaktu: jangkaWaktu,
      penggunaAnggaran: penggunaAnggaran,
      stafTeknis1: stafTeknis1,
      stafTeknis2: stafTeknis2,
      siteEngineerKegiatan: siteEngineerKegiatan,
      direkturKonsultan: direkturKonsultan,
      pelaksanaLapangan: pelaksanaLapangan,
      petugasK3: petugasK3,
      folders: json['folders'] != null ? List<Map<String, dynamic>>.from(json['folders']) : null,
      laporans: json['laporans'] != null ? List<dynamic>.from(json['laporans']) : null,
      laporanMingguan: json['laporanMingguan'] != null ? List<dynamic>.from(json['laporanMingguan']) : null,
      rkkDivisiList: json['rkkDivisiList'] != null
          ? List<Map<String, dynamic>>.from(
              (json['rkkDivisiList'] as List).map((e) => Map<String, dynamic>.from(e)))
          : null,
      rkkKontrakAwal: json['rkkKontrakAwal'] != null
          ? List<Map<String, dynamic>>.from(
              (json['rkkKontrakAwal'] as List).map((e) => Map<String, dynamic>.from(e)))
          : null,
      addendums: json['addendums'] != null
          ? List<Map<String, dynamic>>.from(
              (json['addendums'] as List).map((e) => Map<String, dynamic>.from(e)))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'namaKegiatan': namaKegiatan,
      'lokasi': lokasi,
      'sumberDana': sumberDana,
      'konsultanPengawas': konsultanPengawas,
      'noSpkKonsultan': noSpkKonsultan,
      'tglSpkKonsultan': tglSpkKonsultan,
      'noSpmkKonsultan': noSpmkKonsultan,
      'tglSpmkKonsultan': tglSpmkKonsultan,
      'awalPelaksanaan': awalPelaksanaan,
      'akhirPelaksanaan': akhirPelaksanaan,
      'masaPelaksanaan': masaPelaksanaan,
      'waktuBerjalan': waktuBerjalan,
      'kontraktor': kontraktor,
      'kontraktorUid': kontraktorUid,
      'noSuratPesanan': noSuratPesanan,
      'tglSuratPesanan': tglSuratPesanan,
      'noSpmkKontraktor': noSpmkKontraktor,
      'tglSpmkKontraktor': tglSpmkKontraktor,
      'nilaiKontrak': nilaiKontrak,
      'jangkaWaktu': jangkaWaktu,
      'penggunaAnggaran': penggunaAnggaran,
      'stafTeknis1': stafTeknis1,
      'stafTeknis2': stafTeknis2,
      'siteEngineerKegiatan': siteEngineerKegiatan,
      'direkturKonsultan': direkturKonsultan,
      'direkturPenyedia': direkturKonsultan,
      'direkturKontraktor': direkturKonsultan,
      'pelaksanaLapangan': pelaksanaLapangan,
      'petugasK3': petugasK3,
      'strukturOrganisasiKegiatan': {
        'penggunaAnggaran': penggunaAnggaran,
        'stafTeknis1': stafTeknis1,
        'stafTeknis2': stafTeknis2,
      },
      'strukturOrganisasiKonsultan': {
        'direkturKonsultan': direkturKonsultan,
        'siteEngineer': siteEngineerKegiatan,
      },
      'strukturPenyediaJasa': {
        'pelaksanaLapangan': pelaksanaLapangan,
        'petugasK3': petugasK3,
      },
      'folders': folders,
      'laporans': laporans,
      'laporanMingguan': laporanMingguan,
      'rkkDivisiList': rkkDivisiList,
      'rkkKontrakAwal': rkkKontrakAwal.isNotEmpty ? rkkKontrakAwal : rkkDivisiList,
      'addendums': addendums,
    };
  }

  /// Template Standar RKK (Rincian Kuantitas & Bobot Pekerjaan) Resmi PU Bina Marga
  /// Berdasarkan acuan fisik dokumen Laporan Mingguan Kab. Purbalingga (Format RAB 7 Kolom)
  static List<Map<String, dynamic>> defaultSampleRkk() {
    return [
      {
        'nomorRomawi': 'I',
        'namaDivisi': 'DIVISI 1 UMUM',
        'items': [
          {
            'no': '1',
            'noMataPembayaran': '1.2',
            'uraian': 'Mobilisasi',
            'satuan': 'Ls',
            'hargaSatuan': 12900000.0,
            'volume': 1.00,
            'totalHarga': 12900000.0,
            'nilaiBobot': 4.474,
            'volumeCCO': 1.00,
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'uraian': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'satuan': 'Ls',
            'hargaSatuan': 5150000.0,
            'volume': 1.00,
            'totalHarga': 5150000.0,
            'nilaiBobot': 1.786,
            'volumeCCO': 1.00,
          },
          {
            'no': '3',
            'noMataPembayaran': '1.19',
            'uraian': 'Biaya Penerapan SMKK',
            'satuan': 'Ls',
            'hargaSatuan': 1478500.0,
            'volume': 1.00,
            'totalHarga': 1478500.0,
            'nilaiBobot': 0.513,
            'volumeCCO': 1.00,
          },
          {
            'no': '4',
            'noMataPembayaran': 'Taksir',
            'uraian': 'Bongkaran',
            'satuan': 'Ls',
            'hargaSatuan': 1352000.0,
            'volume': 0.0,
            'totalHarga': 0.0,
            'nilaiBobot': 0.0,
            'volumeCCO': 0.0,
          },
        ],
      },
      {
        'nomorRomawi': 'II',
        'namaDivisi': 'DIVISI 2. DRAINASE',
        'items': [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(12)',
            'uraian': 'Gorong-Gorong Kotak Beton Bertulang Ukuran dalam 50cmx50cm',
            'satuan': 'm1',
            'hargaSatuan': 2139059.32,
            'volume': 4.80,
            'totalHarga': 10267484.74,
            'nilaiBobot': 3.561,
            'volumeCCO': 4.80,
          },
          {
            'no': '2',
            'noMataPembayaran': '2.3.(24)',
            'uraian': 'Saluran berbentuk U Tipe DS 2',
            'satuan': 'm1',
            'hargaSatuan': 661011.25,
            'volume': 115.00,
            'totalHarga': 76016293.75,
            'nilaiBobot': 26.362,
            'volumeCCO': 115.00,
          },
        ],
      },
      {
        'nomorRomawi': 'VI',
        'namaDivisi': 'DIVISI 6. PERKERASAN ASPAL',
        'items': [
          {
            'no': '1',
            'noMataPembayaran': '6.1 (1)(a)',
            'uraian': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
            'satuan': 'liter',
            'hargaSatuan': 25958.00,
            'volume': 118.79,
            'totalHarga': 3083550.82,
            'nilaiBobot': 1.069,
            'volumeCCO': 118.79,
          },
          {
            'no': '2',
            'noMataPembayaran': '6.7.(1)',
            'uraian': 'Lapis Penetrasi Macadam',
            'satuan': 'm3',
            'hargaSatuan': 2516272.00,
            'volume': 29.17,
            'totalHarga': 73401969.21,
            'nilaiBobot': 25.456,
            'volumeCCO': 29.17,
          },
          {
            'no': '3',
            'noMataPembayaran': 'SNI 6749-2008(S)',
            'uraian': 'LATASIR KELAS B (1,5 cm)',
            'satuan': 'm2',
            'hargaSatuan': 102310.00,
            'volume': 944.00,
            'totalHarga': 96580640.0,
            'nilaiBobot': 33.494,
            'volumeCCO': 944.00,
          },
        ],
      },
      {
        'nomorRomawi': 'VII',
        'namaDivisi': 'DIVISI 7 STRUKTUR',
        'items': [
          {
            'no': '1',
            'noMataPembayaran': '7.1(8)',
            'uraian': 'Beton fc\' 15Mpa',
            'satuan': 'm3',
            'hargaSatuan': 1655793.06,
            'volume': 4.79,
            'totalHarga': 7935388.25,
            'nilaiBobot': 2.752,
            'volumeCCO': 4.79,
          },
          {
            'no': '2',
            'noMataPembayaran': '7.3(1)',
            'uraian': 'Baja Tulangan Polos-BjTP 280',
            'satuan': 'kg',
            'hargaSatuan': 16433.49,
            'volume': 93.52,
            'totalHarga': 1536876.26,
            'nilaiBobot': 0.533,
            'volumeCCO': 93.52,
          },
          {
            'no': '3',
            'noMataPembayaran': '3.9.8.3',
            'uraian': 'Pasangan Keramik 40 x 40 cm (Bekas Bongkaran)',
            'satuan': 'm2',
            'hargaSatuan': 167594.80,
            'volume': 0.0,
            'totalHarga': 0.0,
            'nilaiBobot': 0.0,
            'volumeCCO': 0.0,
          },
        ],
      },
    ];
  }
}
