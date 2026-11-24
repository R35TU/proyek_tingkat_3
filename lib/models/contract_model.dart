import 'package:tata_saka_app/utils/progress_calculator.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';

class ContractModel {
  String id;
  final String jenisKegiatan;
  final String namaKontrak;
  
  final String nomorSpk;
  final String tglMulaiSpk;
  
  final String nomorSpmk;
  final String tglMulaiSpmk;
  final String tglSelesaiSpmk;
  final int hariKalender;
  
  final String nilaiKontrak;

  /// Nilai numerik kontrak (double) dengan presisi desimal penuh.
  double get nilaiKontrakNumeric => RupiahUtil.parseToDouble(nilaiKontrak);
  
  final List<String> instansiDinas;
  final String dinasUid;
  final String sumberDana;
  final String deskripsi;
  final double _storedProgressFisik;

  /// Nilai rasio progres fisik (0.0 sampai 1.0) untuk progress indicators.
  /// Dihitung secara dinamis dari rata-rata seluruh kegiatan di bawah kontrak.
  /// Jika belum ada kegiatan, menggunakan nilai fallback _storedProgressFisik.
  double get progressFisik => ProgressCalculator.calculateContractProgressRatio(
        kegiatans,
        fallbackProgress: _storedProgressFisik,
      );

  /// Nilai persentase progres fisik (0.0 s.d. 100.0%).
  double get progressPercent => ProgressCalculator.calculateContractProgressPercent(
        kegiatans,
        fallbackProgress: _storedProgressFisik,
      );
  
  // Folders for administrasi
  List<Map<String, dynamic>> folders;
  
  // Kegiatans langsung di bawah Kontrak
  List<Map<String, dynamic>> kegiatans;

  // Struktur Organisasi Personel Konsultan (Site Engineer, Inspektor 1-4, Administrasi)
  Map<String, dynamic>? strukturOrganisasi;

  String get siteEngineer => strukturOrganisasi?['siteEngineer']?.toString() ?? '';
  List<String> get inspektors {
    final raw = strukturOrganisasi?['inspektors'];
    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }
  String get administrasi => strukturOrganisasi?['administrasi']?.toString() ?? '';
  bool get hasStrukturOrganisasi =>
      siteEngineer.isNotEmpty || inspektors.isNotEmpty || administrasi.isNotEmpty;

  // Backward compatibility getter for any legacy usages
  List<Map<String, dynamic>> get pakets => [
    {'name': 'Kegiatan', 'isExpanded': true, 'kegiatans': kegiatans}
  ];

  String get status => progressFisik >= 1.0 ? 'Selesai' : 'Aktif';

  /// Memeriksa apakah kontrak ini milik akun Dinas yang sedang login.
  /// Memprioritaskan pencocokan `dinasUid` (UID akun Firebase).
  /// Fallback ke pencocokan nama instansi/dinas jika `dinasUid` belum terisi (kontrak lama).
  bool isOwnedByDinas({
    required String dinasUserUid,
    String companyOrAgency = '',
    String userFullName = '',
  }) {
    final cleanUid = dinasUserUid.trim();
    // 1. Prioritas Utama: Pencocokan UID unik akun dinas
    if (dinasUid.trim().isNotEmpty) {
      return cleanUid.isNotEmpty && dinasUid.trim() == cleanUid;
    }

    // 2. Fallback untuk data lama tanpa dinasUid
    if (instansiDinas.isNotEmpty) {
      final agency = companyOrAgency.trim().toLowerCase();
      final fullName = userFullName.trim().toLowerCase();

      return instansiDinas.any((d) {
        final dinasName = d.trim().toLowerCase();
        if (dinasName.isEmpty) return false;

        final matchAgency = agency.isNotEmpty &&
            agency != 'tata saka' &&
            (dinasName.contains(agency) || agency.contains(dinasName));
        final matchFullName = fullName.isNotEmpty &&
            fullName != 'tata saka' &&
            (dinasName.contains(fullName) || fullName.contains(dinasName));

        return matchAgency || matchFullName;
      });
    }

    return false;
  }

  ContractModel({
    required this.id,
    required this.jenisKegiatan,
    required this.namaKontrak,
    required this.nomorSpk,
    required this.tglMulaiSpk,
    required this.nomorSpmk,
    required this.tglMulaiSpmk,
    required this.tglSelesaiSpmk,
    required this.hariKalender,
    required this.nilaiKontrak,
    required this.instansiDinas,
    this.dinasUid = '',
    required this.sumberDana,
    required this.deskripsi,
    double progressFisik = 0.0,
    List<Map<String, dynamic>>? folders,
    List<Map<String, dynamic>>? kegiatans,
    List<Map<String, dynamic>>? pakets,
    this.strukturOrganisasi,
  }) : _storedProgressFisik = progressFisik,
  folders = folders ?? [
    {'name': 'SPK', 'isExpanded': false, 'documents': []},
    {'name': 'SPMK', 'isExpanded': false, 'documents': []},
    {'name': 'Adendum Konsultan', 'isExpanded': false, 'documents': []},
  ],
  kegiatans = kegiatans ?? (
    pakets != null
      ? pakets.expand((p) => (p['kegiatans'] as List<dynamic>? ?? []).map((k) => Map<String, dynamic>.from(k))).toList()
      : []
  );

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> loadedKegiatans = [];
    if (json['kegiatans'] != null) {
      loadedKegiatans = List<Map<String, dynamic>>.from(
        json['kegiatans'].map((e) => Map<String, dynamic>.from(e)),
      );
    } else if (json['pakets'] != null) {
      for (var p in json['pakets']) {
        if (p['kegiatans'] != null) {
          for (var k in p['kegiatans']) {
            loadedKegiatans.add(Map<String, dynamic>.from(k));
          }
        }
      }
    }

    return ContractModel(
      id: json['id'] ?? '',
      jenisKegiatan: json['jenisKegiatan'] ?? '',
      namaKontrak: json['namaKontrak'] ?? '',
      nomorSpk: json['nomorSpk'] ?? '',
      tglMulaiSpk: json['tglMulaiSpk'] ?? '',
      nomorSpmk: json['nomorSpmk'] ?? '',
      tglMulaiSpmk: json['tglMulaiSpmk'] ?? '',
      tglSelesaiSpmk: json['tglSelesaiSpmk'] ?? '',
      hariKalender: json['hariKalender'] ?? 0,
      nilaiKontrak: json['nilaiKontrak'] != null
          ? (json['nilaiKontrak'] is num
              ? RupiahUtil.formatWithRp(json['nilaiKontrak'] as num, allowDecimals: true)
              : json['nilaiKontrak'].toString())
          : '',
      instansiDinas: json['instansiDinas'] != null ? List<String>.from(json['instansiDinas']) : [],
      dinasUid: json['dinasUid'] ?? '',
      sumberDana: json['sumberDana'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      progressFisik: (json['progressFisik'] ?? 0.0).toDouble(),
      folders: json['folders'] != null 
          ? List<Map<String, dynamic>>.from(json['folders'].map((e) => Map<String, dynamic>.from(e))) 
          : null,
      kegiatans: loadedKegiatans,
      strukturOrganisasi: json['strukturOrganisasi'] != null && json['strukturOrganisasi'] is Map
          ? Map<String, dynamic>.from(json['strukturOrganisasi'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jenisKegiatan': jenisKegiatan,
      'namaKontrak': namaKontrak,
      'nomorSpk': nomorSpk,
      'tglMulaiSpk': tglMulaiSpk,
      'nomorSpmk': nomorSpmk,
      'tglMulaiSpmk': tglMulaiSpmk,
      'tglSelesaiSpmk': tglSelesaiSpmk,
      'hariKalender': hariKalender,
      'nilaiKontrak': nilaiKontrak,
      'instansiDinas': instansiDinas,
      'dinasUid': dinasUid,
      'sumberDana': sumberDana,
      'deskripsi': deskripsi,
      'progressFisik': progressFisik,
      'folders': folders,
      'kegiatans': kegiatans,
      if (strukturOrganisasi != null) 'strukturOrganisasi': strukturOrganisasi,
    };
  }
}
