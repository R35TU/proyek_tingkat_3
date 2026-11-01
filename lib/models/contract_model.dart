class ContractModel {
  final String id;
  final String jenisKegiatan;
  final String namaKontrak;
  
  final String nomorSpk;
  final String tglMulaiSpk;
  
  final String nomorSpmk;
  final String tglMulaiSpmk;
  final String tglSelesaiSpmk;
  final int hariKalender;
  
  final String nilaiKontrak;
  
  final List<String> instansiDinas;
  final String sumberDana;
  final String deskripsi;
  final double progressFisik;
  
  // Folders for administrasi
  List<Map<String, dynamic>> folders;
  
  // Kegiatans langsung di bawah Kontrak
  List<Map<String, dynamic>> kegiatans;

  // Struktur Organisasi Anggota Konsultan (Site Engineer, Inspektor 1-4, Administrasi)
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
    required this.sumberDana,
    required this.deskripsi,
    this.progressFisik = 0.0,
    List<Map<String, dynamic>>? folders,
    List<Map<String, dynamic>>? kegiatans,
    List<Map<String, dynamic>>? pakets,
    this.strukturOrganisasi,
  }) : folders = folders ?? [
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
      nilaiKontrak: json['nilaiKontrak'] ?? '',
      instansiDinas: json['instansiDinas'] != null ? List<String>.from(json['instansiDinas']) : [],
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
      'sumberDana': sumberDana,
      'deskripsi': deskripsi,
      'progressFisik': progressFisik,
      'folders': folders,
      'kegiatans': kegiatans,
      if (strukturOrganisasi != null) 'strukturOrganisasi': strukturOrganisasi,
    };
  }
}
