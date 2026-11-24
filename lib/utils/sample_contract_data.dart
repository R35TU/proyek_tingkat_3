import 'package:tata_saka_app/models/contract_model.dart';

/// File Tunggal Data Bawaan (Demo Data MT Haryono)
///
/// Menyediakan 1 dataset lengkap proyek riil standar DPU-PR Kab. Purbalingga
/// dengan kondisi "Proyek Berjalan 1 Bulan" (~4 Minggu Pelaksanaan).
///
/// Dataset ini mencakup:
/// 1. Kontrak Induk Pengawasan & Struktur Personel Konsultan/PPK.
/// 2. RAB Kontrak Awal (Format 7 Kolom Lengkap sesuai acuan fisik DPU-PR).
/// 3. Addendum 01 / CCO (Perubahan volume rekayasa lapangan & tambah-kurang seimbang).
/// 4. Laporan Mingguan Minggu 1 s.d. 4 (Lengkap dengan Lembar BoQ 14 Kolom).
/// 5. Laporan Harian (Buku Harian, Rekap Pengecoran Beton, & Rekapitulasi DT Aspal).
class SampleContractData {
  static ContractModel getDemoContract() {
    return ContractModel(
      id: 'kontrak-mt-haryono-demo',
      jenisKegiatan: 'Pengawasan Teknis',
      namaKontrak: 'PEMELIHARAAN BERKALA JL. MT HARYONO',
      nomorSpk: '000.3.2/1691.1/WAS-21/SPK-BM/1.03.10.2.01.0056/2026',
      tglMulaiSpk: '20 April 2026',
      nomorSpmk: '000.3.2/1691.1/WAS-21/SPMK-BM/1.03.10.2.01.0056/2026',
      tglMulaiSpmk: '20 April 2026',
      tglSelesaiSpmk: '18 Juli 2026',
      hariKalender: 90,
      nilaiKontrak: 'Rp 288.350.000,00',
      instansiDinas: ['DPU-PR Kab. Purbalingga'],
      sumberDana: 'APBD Kab. Purbalingga',
      deskripsi:
          'Pengawasan Teknis Pemeliharaan Berkala Jalan Paket 2 (Ruas Letjen MT Haryono - Letnan Sudani). Kondisi berjalan 1 bulan (Minggu 1 s.d. 4) dengan Addendum 01 CCO aktif.',
      progressFisik: 0.4078, // 40.78% realisasi akhir bulan ke-1
      strukturOrganisasi: {
        'siteEngineer': 'SENDAYU GALIH K., ST',
        'inspektors': ['MUBALLIGH, ST., M.Sc.', 'BILAL, A.Md'],
        'administrasi': 'HANGGORO AJI',
      },
      folders: [],
      kegiatans: [
        _buildRuasJalanA(),
        _buildRuasJalanB(),
        _buildRuasJalanC(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. KEGIATAN 1: RUAS JALAN A (LETJEN MT HARYONO - LETNAN SUDANI)
  // ═══════════════════════════════════════════════════════════════════════════
  static Map<String, dynamic> _buildRuasJalanA() {
    final rkkAwal = _buildRabKontrakAwal();
    final addendum01 = _buildAddendum01Cco();

    return {
      'namaKegiatan': 'Ruas Jalan A',
      'lokasi': 'Ruas Letjen MT Haryono - Letnan Sudani, Kab. Purbalingga',
      'sumberDana': 'APBD Kab. Purbalingga',
      'konsultanPengawas': 'CV. TATA SAKA CONSULTANT',
      'noSpkKonsultan': '000.3.2/1691.1/WAS-21/SPK-BM/1.03.10.2.01.0056/2026',
      'tglSpkKonsultan': '20 April 2026',
      'noSpmkKonsultan': '000.3.2/1691.1/WAS-21/SPMK-BM/1.03.10.2.01.0056/2026',
      'tglSpmkKonsultan': '20 April 2026',
      'awalPelaksanaan': '20 April 2026',
      'akhirPelaksanaan': '18 Juli 2026',
      'masaPelaksanaan': '90 (Sembilan Puluh) hari kalender',
      'waktuBerjalan': '4 (Empat) Minggu',
      'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
      'noSuratPesanan': '000.3.2/1914.1/KONST-BM/SPK-BM/1.03.10.2.01.0056/2026',
      'tglSuratPesanan': '20 April 2026',
      'noSpmkKontraktor': '000.3.2/1914.1/KONST-BM/SPMK-BM/1.03.10.2.01.0056/2026',
      'tglSpmkKontraktor': '20 April 2026',
      'nilaiKontrak': 'Rp 288.350.000,00',
      'jangkaWaktu': '90 (Sembilan Puluh) hari kalender',

      // Struktur Organisasi Kegiatan
      'penggunaAnggaran': 'DRAJAT UJI WAKHYONO, S.T., M.T.',
      'stafTeknis1': 'MUBALLIGH, ST., M.Sc.',
      'stafTeknis2': 'BILAL, A.Md',
      'siteEngineerKegiatan': 'SENDAYU GALIH K., ST',
      'direkturKonsultan': 'NURKHOLIS WIJANTO',
      'direkturPenyedia': 'IKSAN',
      'direkturKontraktor': 'IKSAN',
      'pelaksanaLapangan': 'GALIH WAHYU UTAMA',
      'petugasK3': 'IQBAL ZAINUL ARIFIN',

      // Data RKK & Addendum Snapshot
      'rkkKontrakAwal': rkkAwal,
      'rkkDivisiList': addendum01['rkkDivisiList'], // Versi aktif mengacu Addendum 01
      'addendums': [addendum01],

      // Folder Administrasi
      'folders': [],

      // Buku Harian (Laporan Harian)
      'laporans': _buildDailyReportsList(),

      // Laporan Mingguan Minggu 1 s.d. 5 (Bulan 1 selesai & awal Bulan 2)
      'laporanMingguan': _buildFourWeeklyReportsList(),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1B. KEGIATAN 2: RUAS JALAN B (STA 1+250 - STA 2+500)
  // ═══════════════════════════════════════════════════════════════════════════
  static Map<String, dynamic> _buildRuasJalanB() {
    final rkk = _buildRabRuasB();
    return {
      'namaKegiatan': 'Ruas Jalan B',
      'lokasi': 'STA 1+250 - STA 2+500',
      'sumberDana': 'APBD Kab. Purbalingga',
      'konsultanPengawas': 'CV. TATA SAKA CONSULTANT',
      'noSpkKonsultan': '000.3.2/1691.1/WAS-21/SPK-BM/1.03.10.2.01.0056/2026',
      'tglSpkKonsultan': '20 April 2026',
      'noSpmkKonsultan': '000.3.2/1691.1/WAS-21/SPMK-BM/1.03.10.2.01.0056/2026',
      'tglSpmkKonsultan': '20 April 2026',
      'awalPelaksanaan': '20 April 2026',
      'akhirPelaksanaan': '18 Juli 2026',
      'masaPelaksanaan': '90 (Sembilan Puluh) hari kalender',
      'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
      'noSuratPesanan': '000.3.2/1914.2/KONST-BM/SPK-BM/1.03.10.2.01.0056/2026',
      'tglSuratPesanan': '20 April 2026',
      'noSpmkKontraktor': '000.3.2/1914.2/KONST-BM/SPMK-BM/1.03.10.2.01.0056/2026',
      'tglSpmkKontraktor': '20 April 2026',
      'nilaiKontrak': 'Rp 100.000.000,00',
      'jangkaWaktu': '90 (Sembilan Puluh) hari kalender',
      'penggunaAnggaran': 'DRAJAT UJI WAKHYONO, S.T., M.T.',
      'stafTeknis1': 'MUBALLIGH, ST., M.Sc.',
      'stafTeknis2': 'BILAL, A.Md',
      'siteEngineerKegiatan': 'SENDAYU GALIH K., ST',
      'direkturPenyedia': 'IKSAN',
      'direkturKontraktor': 'IKSAN',
      'pelaksanaLapangan': 'GALIH WAHYU UTAMA',
      'petugasK3': 'IQBAL ZAINUL ARIFIN',
      'rkkKontrakAwal': rkk,
      'rkkDivisiList': rkk,
      'addendums': [],
      'folders': [],
      'laporanMingguan': [
        _buildSimpleWeeklyReport(
          mingguKe: 1,
          periodeAwal: '20 April 2026',
          periodeAkhir: '26 April 2026',
          rencana: 5.80,
          realisasi: 6.10,
          kegiatanNama: 'Ruas Jalan B',
          kontraktor: 'CV. DIVAN INSAN CEMERLANG',
        ),
      ],
      'laporans': [
        _buildSingleDailyReport(
          id: 'rep-b-20260424',
          tanggal: '2026-04-24',
          tanggalFormatted: 'Jumat, 24 April 2026',
          pekerjaan: [
            {
              'no': '1',
              'noMataPembayaran': '2.3.(24)',
              'jenis': 'Saluran berbentuk U Tipe DS 2',
              'volume': '6.00 m1',
              'satuan': 'm1',
              'lokasi': 'STA 1+350 Crossing',
              'materials': [
                {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '6 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 1+350'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-02', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana', 'cacah': '1', 'lokasi': 'STA 1+350'},
                {'no': '1.2', 'role': 'Pekerja Pasang Precast', 'cacah': '4', 'lokasi': 'STA 1+350'},
              ],
            },
          ],
          cuaca: 'Cerah',
          kejadian: 'Normal',
          catatan: 'Pemasangan elevasi tepat.',
        ),
      ],
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1C. KEGIATAN 3: RUAS JALAN C (STA 2+500 - STA 3+800)
  // ═══════════════════════════════════════════════════════════════════════════
  static Map<String, dynamic> _buildRuasJalanC() {
    final rkk = _buildRabRuasC();
    return {
      'namaKegiatan': 'Ruas Jalan C',
      'lokasi': 'STA 2+500 - STA 3+800',
      'sumberDana': 'APBD Kab. Purbalingga',
      'konsultanPengawas': 'CV. TATA SAKA CONSULTANT',
      'noSpkKonsultan': '000.3.2/1691.1/WAS-21/SPK-BM/1.03.10.2.01.0056/2026',
      'tglSpkKonsultan': '20 April 2026',
      'noSpmkKonsultan': '000.3.2/1691.1/WAS-21/SPMK-BM/1.03.10.2.01.0056/2026',
      'tglSpmkKonsultan': '20 April 2026',
      'awalPelaksanaan': '20 April 2026',
      'akhirPelaksanaan': '18 Juli 2026',
      'masaPelaksanaan': '90 (Sembilan Puluh) hari kalender',
      'kontraktor': 'CV. LANGGENG',
      'noSuratPesanan': '000.3.2/1914.3/KONST-BM/SPK-BM/1.03.10.2.01.0056/2026',
      'tglSuratPesanan': '20 April 2026',
      'noSpmkKontraktor': '000.3.2/1914.3/KONST-BM/SPMK-BM/1.03.10.2.01.0056/2026',
      'tglSpmkKontraktor': '20 April 2026',
      'nilaiKontrak': 'Rp 80.000.000,00',
      'jangkaWaktu': '90 (Sembilan Puluh) hari kalender',
      'penggunaAnggaran': 'DRAJAT UJI WAKHYONO, S.T., M.T.',
      'stafTeknis1': 'MUBALLIGH, ST., M.Sc.',
      'stafTeknis2': 'BILAL, A.Md',
      'siteEngineerKegiatan': 'SENDAYU GALIH K., ST',
      'direkturPenyedia': 'BAMBANG',
      'direkturKontraktor': 'BAMBANG',
      'pelaksanaLapangan': 'WIRANTO',
      'petugasK3': 'HARIS',
      'rkkKontrakAwal': rkk,
      'rkkDivisiList': rkk,
      'addendums': [],
      'folders': [],
      'laporanMingguan': [
        _buildSimpleWeeklyReport(
          mingguKe: 1,
          periodeAwal: '20 April 2026',
          periodeAkhir: '26 April 2026',
          rencana: 4.90,
          realisasi: 5.20,
          kegiatanNama: 'Ruas Jalan C',
          kontraktor: 'CV. LANGGENG',
        ),
      ],
      'laporans': [
        _buildSingleDailyReport(
          id: 'rep-c-20260423',
          tanggal: '2026-04-23',
          tanggalFormatted: 'Kamis, 23 April 2026',
          pekerjaan: [
            {
              'no': '1',
              'noMataPembayaran': '1.2',
              'jenis': 'Mobilisasi Alat & Penerapan SMKK (Rambu K3)',
              'volume': '1.00 Ls',
              'satuan': 'Ls',
              'lokasi': 'STA 2+500',
              'materials': [],
              'peralatans': [],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana', 'cacah': '1', 'lokasi': 'STA 2+500'},
              ],
            },
          ],
          cuaca: 'Cerah Berawan',
          kejadian: 'Normal',
          catatan: 'Pemasangan rambu K3 di titik awal pekerjaan.',
        ),
      ],
    };
  }

  static List<Map<String, dynamic>> _buildRabRuasB() {
    return [
      {
        'nomorRomawi': 'I',
        'namaDivisi': 'DIVISI 1 UMUM',
        'items': [
          {
            'no': '1',
            'noMataPembayaran': '1.2',
            'uraian': 'Mobilisasi Alat & Personil',
            'satuan': 'Ls',
            'hargaSatuan': 10000000.0,
            'volume': 1.0,
            'totalHarga': 10000000.0,
            'nilaiBobot': 10.000,
          },
        ],
      },
      {
        'nomorRomawi': 'II',
        'namaDivisi': 'DIVISI 2. DRAINASE',
        'items': [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'uraian': 'Saluran berbentuk U Tipe DS 2',
            'satuan': 'm1',
            'hargaSatuan': 661011.25,
            'volume': 100.0,
            'totalHarga': 66101125.0,
            'nilaiBobot': 66.101,
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
            'hargaSatuan': 25958.0,
            'volume': 920.67,
            'totalHarga': 23898875.0,
            'nilaiBobot': 23.899,
          },
        ],
      },
    ];
  }

  static List<Map<String, dynamic>> _buildRabRuasC() {
    return [
      {
        'nomorRomawi': 'I',
        'namaDivisi': 'DIVISI 1 UMUM',
        'items': [
          {
            'no': '1',
            'noMataPembayaran': '1.2',
            'uraian': 'Mobilisasi Alat & Personil',
            'satuan': 'Ls',
            'hargaSatuan': 8000000.0,
            'volume': 1.0,
            'totalHarga': 8000000.0,
            'nilaiBobot': 10.000,
          },
        ],
      },
      {
        'nomorRomawi': 'II',
        'namaDivisi': 'DIVISI 2. DRAINASE',
        'items': [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'uraian': 'Saluran berbentuk U Tipe DS 2',
            'satuan': 'm1',
            'hargaSatuan': 661011.25,
            'volume': 80.0,
            'totalHarga': 52880900.0,
            'nilaiBobot': 66.101,
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
            'hargaSatuan': 25958.0,
            'volume': 736.54,
            'totalHarga': 19119100.0,
            'nilaiBobot': 23.899,
          },
        ],
      },
    ];
  }

  static Map<String, dynamic> _buildSimpleWeeklyReport({
    required int mingguKe,
    required String periodeAwal,
    required String periodeAkhir,
    required double rencana,
    required double realisasi,
    required String kegiatanNama,
    required String kontraktor,
  }) {
    final deviasi = realisasi - rencana;
    return {
      'id': 'weekly-$kegiatanNama-$mingguKe',
      'mingguKe': mingguKe,
      'periodeAwal': periodeAwal,
      'periodeAkhir': periodeAkhir,
      'pekerjaan': 'PEMELIHARAAN BERKALA JL. MT HARYONO ($kegiatanNama)',
      'lokasiProyek': 'Kab. Purbalingga',
      'nomorKontrak': '000.3.2/1691.1/WAS-21/SPK-BM/1.03.10.2.01.0056/2026',
      'tanggalKontrak': '20 April 2026',
      'kontraktor': kontraktor,
      'tabelMingguan': [
        {
          'status': 'Normal',
          'mingguKe': 1,
          'tglMulai': '20/04/2026',
          'tglSelesai': '26/04/2026',
          'rencana': rencana,
          'realisasi': realisasi,
        },
      ],
      'rencanaKumulatif': rencana,
      'realisasiKumulatif': realisasi,
      'deviasiKumulatif': deviasi,
      'statusDeviasi': deviasi >= 0 ? 'Maju' : 'Kritis',
      'evaluasiProgress': deviasi >= 0
          ? 'Realisasi pekerjaan fisik melampaui jadwal rencana dengan deviasi positif +${deviasi.toStringAsFixed(2)}%.'
          : 'Realisasi pekerjaan mengalami deviasi negatif.',
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. RINCIAN KUANTITAS KONTRAK (RAB KONTRAK AWAL - 7 KOLOM RESMI)
  // Sesuai Dokumen Fisik: Total Rp 288.350.326,07 (Dibulatkan Rp 288.350.000,00)
  // ═══════════════════════════════════════════════════════════════════════════
  static List<Map<String, dynamic>> _buildRabKontrakAwal() {
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
          },
          {
            'no': '4',
            'noMataPembayaran': 'Taksir',
            'uraian': 'Bongkaran',
            'satuan': 'Ls',
            'hargaSatuan': 1352000.0,
            'volume': 1.00,
            'totalHarga': 1352000.0,
            'nilaiBobot': 0.469,
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
          },
          {
            'no': '2',
            'noMataPembayaran': '2.3.(24)',
            'uraian': 'Saluran berbentuk U Tipe DS 2',
            'satuan': 'm1',
            'hargaSatuan': 661011.25,
            'volume': 121.00,
            'totalHarga': 79982361.25,
            'nilaiBobot': 27.738,
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
            'hargaSatuan': 25958.0,
            'volume': 118.79,
            'totalHarga': 3083550.82,
            'nilaiBobot': 1.069,
          },
          {
            'no': '2',
            'noMataPembayaran': '6.7.(1)',
            'uraian': 'Lapis Penetrasi Macadam',
            'satuan': 'm3',
            'hargaSatuan': 2516272.0,
            'volume': 29.17,
            'totalHarga': 73401969.21,
            'nilaiBobot': 25.456,
          },
          {
            'no': '3',
            'noMataPembayaran': 'SNI 6749-2008(S)',
            'uraian': 'LATASIR KELAS B (1,5 cm)',
            'satuan': 'm2',
            'hargaSatuan': 102310.0,
            'volume': 944.00,
            'totalHarga': 96580640.0,
            'nilaiBobot': 33.494,
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
            'volume': 1.13,
            'totalHarga': 1862767.20,
            'nilaiBobot': 0.646,
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
          },
          {
            'no': '3',
            'noMataPembayaran': '3.9.8.3',
            'uraian': 'Pasangan Keramik 40 x 40 cm ( Bekas Bongkaran )',
            'satuan': 'm2',
            'hargaSatuan': 167594.80,
            'volume': 4.50,
            'totalHarga': 754176.60,
            'nilaiBobot': 0.262,
          },
        ],
      },
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. DATA ADDENDUM 01 (CONTRACT CHANGE ORDER / CCO)
  // Perubahan volume rekayasa lapangan sesuai foto fisik resmi:
  // - Bongkaran: 1.00 -> 0.00 (Kurang Rp 1.352.000,00)
  // - Saluran U: 121.00 -> 115.00 (Kurang Rp 3.966.067,50)
  // - Keramik: 4.50 -> 0.00 (Kurang Rp 754.176,60)
  // - Beton fc' 15Mpa: 1.13 -> 4.793 (Tambah Rp 6.072.621,06)
  // Total Tambah = Rp 6.072.621,06 | Total Kurang = Rp 6.072.244,10 (Pagu Seimbang)
  // ═══════════════════════════════════════════════════════════════════════════
  static Map<String, dynamic> _buildAddendum01Cco() {
    return {
      'id': 'addendum-mt-haryono-01',
      'nomorAddendum': '01',
      'judul': 'DAFTAR PERHITUNGAN TAMBAH KURANG KE - 01',
      'nomorSpkAddendum': '000.3.2/1914.1/KONST-BM/ADD-01/2026',
      'tanggalAddendum': '15 Agustus 2026',
      'keterangan':
          'Penyesuaian volume pekerjaan hasil rekayasa lapangan (CCO 01). Pengurangan volume bongkaran, saluran U, dan keramik dialihkan untuk penambahan perkuatan struktur beton fc\' 15Mpa.',
      'parentVersion': 'kontrak_awal',
      'totalHarga': 288350701.03,
      'totalBobot': 100.000,
      'rkkDivisiList': [
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
            },
            {
              'no': '4',
              'noMataPembayaran': 'Taksir',
              'uraian': 'Bongkaran',
              'satuan': 'Ls',
              'hargaSatuan': 1352000.0,
              'volume': 0.00, // CCO: 0 (Kurang 1.00)
              'volumeKurang': 1.00,
              'totalHarga': 0.0,
              'totalHargaKurang': 1352000.0,
              'bobotKurang': 0.469,
              'nilaiBobot': 0.000,
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
            },
            {
              'no': '2',
              'noMataPembayaran': '2.3.(24)',
              'uraian': 'Saluran berbentuk U Tipe DS 2',
              'satuan': 'm1',
              'hargaSatuan': 661011.25,
              'volume': 115.00, // CCO: 115.00 (Kurang 6.00)
              'volumeKurang': 6.00,
              'totalHarga': 76016293.75,
              'totalHargaKurang': 3966067.50,
              'bobotKurang': 1.375,
              'nilaiBobot': 26.362,
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
              'hargaSatuan': 25958.0,
              'volume': 118.79,
              'totalHarga': 3083550.82,
              'nilaiBobot': 1.069,
            },
            {
              'no': '2',
              'noMataPembayaran': '6.7.(1)',
              'uraian': 'Lapis Penetrasi Macadam',
              'satuan': 'm3',
              'hargaSatuan': 2516272.0,
              'volume': 29.17,
              'totalHarga': 73401969.21,
              'nilaiBobot': 25.456,
            },
            {
              'no': '3',
              'noMataPembayaran': 'SNI 6749-2008(S)',
              'uraian': 'LATASIR KELAS B (1,5 cm)',
              'satuan': 'm2',
              'hargaSatuan': 102310.0,
              'volume': 944.00,
              'totalHarga': 96580640.0,
              'nilaiBobot': 33.494,
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
              'volume': 4.793, // CCO: 4.793 (Tambah 3.67)
              'volumeTambah': 3.67,
              'totalHarga': 7935388.25,
              'totalHargaTambah': 6072621.06,
              'bobotTambah': 2.106,
              'nilaiBobot': 2.752,
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
            },
            {
              'no': '3',
              'noMataPembayaran': '3.9.8.3',
              'uraian': 'Pasangan Keramik 40 x 40 cm ( Bekas Bongkaran )',
              'satuan': 'm2',
              'hargaSatuan': 167594.80,
              'volume': 0.00, // CCO: 0.00 (Kurang 4.50)
              'volumeKurang': 4.50,
              'totalHarga': 0.0,
              'totalHargaKurang': 754176.60,
              'bobotKurang': 0.262,
              'nilaiBobot': 0.000,
            },
          ],
        },
      ],
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. LAPORAN MINGGUAN (MINGGU 1 S.D. 4 LENGKAP DENGAN LEMBAR BoQ 14 KOLOM)
  // Merepresentasikan proyek telah berjalan 1 bulan kalender (April - Mei 2026)
  // ═══════════════════════════════════════════════════════════════════════════
  static List<Map<String, dynamic>> _buildFourWeeklyReportsList() {
    return [
      _buildSingleWeeklyReport(
        mingguKe: 1,
        periodeAwal: '20 April 2026',
        periodeAkhir: '26 April 2026',
        waktuTerpakai: 7,
        rencanaPersen: 5.500,
        realisasiPersen: 6.121,
        // Alokasi per item pada BoQ Minggu 1
        mingguIniVolMap: {
          '1.2': 0.70, // Mobilisasi 70%
          '1.8.(1)': 0.50, // SMK3 50%
          '1.19': 0.50, // SMKK 50%
          '2.3.(24)': 8.00, // Saluran U 8 m1
        },
        mingguLaluVolMap: {},
      ),
      _buildSingleWeeklyReport(
        mingguKe: 2,
        periodeAwal: '27 April 2026',
        periodeAkhir: '03 Mei 2026',
        waktuTerpakai: 14,
        rencanaPersen: 17.500,
        realisasiPersen: 19.370,
        // Alokasi per item pada BoQ Minggu 2
        mingguIniVolMap: {
          '1.2': 0.30, // Sisa mobilisasi 30%
          '2.3.(12)': 4.80, // Box Culvert selesai 100%
          '2.3.(24)': 35.00, // Saluran U 35 m1
          '1.8.(1)': 0.15,
        },
        mingguLaluVolMap: {
          '1.2': 0.70,
          '1.8.(1)': 0.50,
          '1.19': 0.50,
          '2.3.(24)': 8.00,
        },
      ),
      _buildSingleWeeklyReport(
        mingguKe: 3,
        periodeAwal: '04 Mei 2026',
        periodeAkhir: '10 Mei 2026',
        waktuTerpakai: 21,
        rencanaPersen: 29.800,
        realisasiPersen: 31.649,
        // Alokasi per item pada BoQ Minggu 3
        mingguIniVolMap: {
          '2.3.(24)': 45.00, // Saluran U tambah 45 m1
          '7.1(8)': 2.00, // Beton fc' 15Mpa inlet 2 m3
          '7.3(1)': 50.00, // Baja tulangan 50 kg
          '1.8.(1)': 0.15,
        },
        mingguLaluVolMap: {
          '1.2': 1.00,
          '1.8.(1)': 0.65,
          '1.19': 0.50,
          '2.3.(12)': 4.80,
          '2.3.(24)': 43.00,
        },
      ),
      _buildSingleWeeklyReport(
        mingguKe: 4,
        periodeAwal: '11 Mei 2026',
        periodeAkhir: '17 Mei 2026',
        waktuTerpakai: 28,
        rencanaPersen: 38.500,
        realisasiPersen: 40.776,
        // Alokasi per item pada BoQ Minggu 4 (Akhir Bulan 1)
        mingguIniVolMap: {
          '2.3.(24)': 27.00, // Sisa saluran U selesai (total 115 m1)
          '7.1(8)': 2.793, // Sisa beton fc' 15Mpa (total 4.793 m3)
          '7.3(1)': 43.52, // Sisa baja tulangan (total 93.52 kg)
          '6.1 (1)(a)': 118.79, // Lapis resap pengikat selesai
          '1.8.(1)': 0.20,
          '1.19': 0.50,
        },
        mingguLaluVolMap: {
          '1.2': 1.00,
          '1.8.(1)': 0.80,
          '1.19': 0.50,
          '2.3.(12)': 4.80,
          '2.3.(24)': 88.00,
          '7.1(8)': 2.00,
          '7.3(1)': 50.00,
        },
      ),
      _buildSingleWeeklyReport(
        mingguKe: 5,
        periodeAwal: '18 Mei 2026',
        periodeAkhir: '24 Mei 2026',
        waktuTerpakai: 35,
        rencanaPersen: 50.000,
        realisasiPersen: 53.865,
        // Alokasi per item pada BoQ Minggu 5 (Awal Bulan 2)
        mingguIniVolMap: {
          '6.7.(1)': 15.00, // Lapis Penetrasi Macadam 15 m3
        },
        mingguLaluVolMap: {
          '1.2': 1.00,
          '1.8.(1)': 1.00,
          '1.19': 1.00,
          '2.3.(12)': 4.80,
          '2.3.(24)': 115.00,
          '6.1 (1)(a)': 118.79,
          '7.1(8)': 4.793,
          '7.3(1)': 93.52,
        },
      ),
    ];
  }

  static Map<String, dynamic> _buildSingleWeeklyReport({
    required int mingguKe,
    required String periodeAwal,
    required String periodeAkhir,
    required int waktuTerpakai,
    required double rencanaPersen,
    required double realisasiPersen,
    required Map<String, double> mingguIniVolMap,
    required Map<String, double> mingguLaluVolMap,
  }) {
    final deviasiPersen = realisasiPersen - rencanaPersen;
    const double pagu = 288350000.0;
    final renNom = (rencanaPersen / 100.0) * pagu;
    final realNom = (realisasiPersen / 100.0) * pagu;
    final devNom = realNom - renNom;

    // Susun Kurva S Jadwal 13 Minggu
    final List<Map<String, dynamic>> tabelMingguan = [
      {'status': 'Normal', 'mingguKe': 1, 'tglMulai': '20/04/2026', 'tglSelesai': '26/04/2026', 'rencana': 5.500, 'realisasi': 6.121},
      {'status': 'Normal', 'mingguKe': 2, 'tglMulai': '27/04/2026', 'tglSelesai': '03/05/2026', 'rencana': 17.500, 'realisasi': 19.370},
      {'status': 'Normal', 'mingguKe': 3, 'tglMulai': '04/05/2026', 'tglSelesai': '10/05/2026', 'rencana': 29.800, 'realisasi': 31.649},
      {'status': 'Normal', 'mingguKe': 4, 'tglMulai': '11/05/2026', 'tglSelesai': '17/05/2026', 'rencana': 38.500, 'realisasi': 40.776},
      {
        'status': mingguKe >= 5 ? 'Normal' : 'Rencana',
        'mingguKe': 5,
        'tglMulai': '18/05/2026',
        'tglSelesai': '24/05/2026',
        'rencana': 50.000,
        'realisasi': mingguKe >= 5 ? 53.865 : null,
      },
      {'status': 'Rencana', 'mingguKe': 6, 'tglMulai': '25/05/2026', 'tglSelesai': '31/05/2026', 'rencana': 62.000, 'realisasi': null},
      {'status': 'Rencana', 'mingguKe': 7, 'tglMulai': '01/06/2026', 'tglSelesai': '07/06/2026', 'rencana': 72.000, 'realisasi': null},
      {'status': 'Rencana', 'mingguKe': 8, 'tglMulai': '08/06/2026', 'tglSelesai': '14/06/2026', 'rencana': 81.000, 'realisasi': null},
      {'status': 'Rencana', 'mingguKe': 9, 'tglMulai': '15/06/2026', 'tglSelesai': '21/06/2026', 'rencana': 88.000, 'realisasi': null},
      {'status': 'Rencana', 'mingguKe': 10, 'tglMulai': '22/06/2026', 'tglSelesai': '28/06/2026', 'rencana': 93.000, 'realisasi': null},
      {'status': 'Rencana', 'mingguKe': 11, 'tglMulai': '29/06/2026', 'tglSelesai': '05/07/2026', 'rencana': 96.500, 'realisasi': null},
      {'status': 'Rencana', 'mingguKe': 12, 'tglMulai': '06/07/2026', 'tglSelesai': '12/07/2026', 'rencana': 98.500, 'realisasi': null},
      {'status': 'Rencana', 'mingguKe': 13, 'tglMulai': '13/07/2026', 'tglSelesai': '18/07/2026', 'rencana': 100.000, 'realisasi': null},
    ];

    // Susun Lembar BoQ 14 Kolom Lengkap
    final boqProgressList = _buildBoqProgressSheet(
      mingguIniVolMap: mingguIniVolMap,
      mingguLaluVolMap: mingguLaluVolMap,
    );

    return {
      'id': 'weekly-mt-haryono-$mingguKe',
      'mingguKe': mingguKe,
      'totalMinggu': 13,
      'periodeAwal': periodeAwal,
      'periodeAkhir': periodeAkhir,
      'pekerjaan': 'Pemeliharaan Berkala Jalan Paket 2 (Ruas Letjen MT Haryono)',
      'lokasiProyek': 'Kab. Purbalingga',
      'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
      'nomorKontrak': '000.3.2/1914.1/KONST-BM/SPK-BM/1.03.10.2.01.0056/2026',
      'tanggalKontrak': '20 April 2026',
      'nilaiKontrak': 'Rp 288.350.000,00',
      'nilaiKontrakNumeric': pagu,
      'tanggalSpmk': '20 April 2026',
      'akhirMasaKontrak': '18 Juli 2026',
      'jangkaWaktu': 90,
      'waktuTerpakai': waktuTerpakai,
      'sisaWaktu': 90 - waktuTerpakai,
      'rencanaPersen': rencanaPersen,
      'rencanaNominal': renNom,
      'realisasiPersen': realisasiPersen,
      'realisasiNominal': realNom,
      'deviasiPersen': deviasiPersen,
      'deviasiNominal': devNom,
      'tabelMingguan': tabelMingguan,
      'boqProgressList': boqProgressList,
      'statusDeviasi': deviasiPersen >= 0 ? 'Maju' : 'Kritis',
      'evaluasiProgress':
          'Realisasi pekerjaan fisik Minggu ke-$mingguKe mencapai ${realisasiPersen.toStringAsFixed(3)}% dari rencana ${rencanaPersen.toStringAsFixed(3)}% (Deviasi: ${deviasiPersen >= 0 ? '+' : ''}${deviasiPersen.toStringAsFixed(3)}%).',
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER: BUILD LEMBAR BoQ 14 KOLOM (KEMAJUAN FISIK PEKERJAAN MINGGUAN)
  // ═══════════════════════════════════════════════════════════════════════════
  static List<Map<String, dynamic>> _buildBoqProgressSheet({
    required Map<String, double> mingguIniVolMap,
    required Map<String, double> mingguLaluVolMap,
  }) {
    // Acuan volume & harga satuan diambil dari Addendum 01
    final rawAddendum = _buildAddendum01Cco();
    final rawDivisi = rawAddendum['rkkDivisiList'] as List<Map<String, dynamic>>;

    return rawDivisi.map((div) {
      final items = (div['items'] as List<Map<String, dynamic>>);
      final computedItems = items.map((it) {
        final noMata = it['noMataPembayaran']?.toString() ?? '';
        final volKontrak = (it['volume'] as num?)?.toDouble() ?? 0.0;
        final bbtKontrak = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;

        final mlVol = mingguLaluVolMap[noMata] ?? 0.0;
        final mlBbt = volKontrak > 0 ? (mlVol / volKontrak) * bbtKontrak : 0.0;

        final miVol = mingguIniVolMap[noMata] ?? 0.0;
        final miBbt = volKontrak > 0 ? (miVol / volKontrak) * bbtKontrak : 0.0;

        final sdVol = mlVol + miVol;
        final sdBbt = mlBbt + miBbt;

        final ssVol = (volKontrak - sdVol).clamp(0.0, double.infinity);
        final ssBbt = (bbtKontrak - sdBbt).clamp(0.0, double.infinity);

        return {
          ...it,
          'mingguLaluVolume': mlVol,
          'mingguLaluBobot': mlBbt,
          'mingguIniVolume': miVol,
          'mingguIniBobot': miBbt,
          'sdMingguIniVolume': sdVol,
          'sdMingguIniBobot': sdBbt,
          'sisaVolume': ssVol,
          'sisaBobot': ssBbt,
        };
      }).toList();

      return {
        'nomorRomawi': div['nomorRomawi'],
        'namaDivisi': div['namaDivisi'],
        'items': computedItems,
      };
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. BUKU HARIAN / LAPORAN OPNAME HARIAN LENGKAP (MINGGU 1 S.D. 5)
  // Selaras 100% secara matematis dengan progres & volume lembar BoQ Mingguan
  // ═══════════════════════════════════════════════════════════════════════════
  static List<Map<String, dynamic>> _buildDailyReportsList() {
    return [
      // ────────── MINGGU 1 (20 April - 26 April 2026) ──────────
      _buildSingleDailyReport(
        id: 'rep-mt-20260420',
        tanggal: '2026-04-20',
        tanggalFormatted: 'Senin, 20 April 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '1.2',
            'jenis': 'Mobilisasi',
            'volume': '0.40 Ls',
            'satuan': 'Ls',
            'lokasi': 'Base Camp & Lokasi Proyek MT Haryono',
            'materials': [],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Dump Truck 4 m3', 'cacahAktif': '2 Unit', 'jumlah': '2 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'DT-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Pelaksana Lapangan', 'cacah': '1', 'lokasi': 'Base Camp'},
              {'no': '1.2', 'role': 'Operator Alat Berat', 'cacah': '2', 'lokasi': 'Base Camp'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.25 Ls',
            'satuan': 'Ls',
            'lokasi': 'Ruas Jalan Letjen MT Haryono',
            'materials': [
              {'no': '2.1', 'jenis': 'Rambu Peringatan Proyek', 'volume': '6 Unit', 'lokasiAwal': 'Gudang', 'lokasiTujuan': 'STA 0+000'},
              {'no': '2.2', 'jenis': 'Traffic Cone & Rompi K3', 'volume': '12 Set', 'lokasiAwal': 'Gudang', 'lokasiTujuan': 'STA 0+000'},
            ],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 0+000'},
            ],
          },
          {
            'no': '3',
            'noMataPembayaran': '1.19',
            'jenis': 'Biaya Penerapan SMKK',
            'volume': '0.25 Ls',
            'satuan': 'Ls',
            'lokasi': 'Direksi Keet & Lapangan',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '3.1', 'role': 'Ahli K3 / Petugas SMKK', 'cacah': '1', 'lokasi': 'Direksi Keet'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Sosialisasi awal kepada warga dan pemasangan rambu K3.',
        catatan: 'Mobilisasi alat berat excavator dan dump truck tiba di lokasi dengan aman.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260422',
        tanggal: '2026-04-22',
        tanggalFormatted: 'Rabu, 22 April 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '1.2',
            'jenis': 'Mobilisasi',
            'volume': '0.30 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+000 - STA 0+458',
            'materials': [],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Stamper Kuda', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'ST-01', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Waterpass & Theodolite', 'cacahAktif': '1 Set', 'jumlah': '1 Set', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'WP-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Surveyor', 'cacah': '2', 'lokasi': 'STA 0+000'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.25 Ls',
            'satuan': 'Ls',
            'lokasi': 'Ruas Jalan Letjen MT Haryono',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 0+000'},
            ],
          },
          {
            'no': '3',
            'noMataPembayaran': '1.19',
            'jenis': 'Biaya Penerapan SMKK',
            'volume': '0.25 Ls',
            'satuan': 'Ls',
            'lokasi': 'Direksi Keet',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '3.1', 'role': 'Petugas SMKK', 'cacah': '1', 'lokasi': 'Direksi Keet'},
            ],
          },
        ],
        cuaca: 'Cerah Berawan',
        kejadian: 'Uitzet dan pengukuran elevasi trase drainase.',
        catatan: 'Patok BM dicek bersama konsultan pengawas dan dinas.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260424',
        tanggal: '2026-04-24',
        tanggalFormatted: 'Jumat, 24 April 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '4.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+000 - STA 0+004 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '4 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+000'},
              {'no': '1.2', 'jenis': 'Pasir Urug', 'volume': '0.80 m³', 'lokasiAwal': 'Quarry', 'lokasiTujuan': 'STA 0+000'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '2', 'lokasi': 'STA 0+000'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '4', 'lokasi': 'STA 0+000'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Galian tanah dan pemasangan awal U-Ditch DS 2.',
        catatan: 'Elevasi dasar saluran diperiksa waterpass sebelum setting precast.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260425',
        tanggal: '2026-04-25',
        tanggalFormatted: 'Sabtu, 25 April 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '4.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+004 - STA 0+008 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '4 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+004'},
              {'no': '1.2', 'jenis': 'Pasir Urug', 'volume': '0.80 m³', 'lokasiAwal': 'Quarry', 'lokasiTujuan': 'STA 0+004'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Stamper Kuda', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'ST-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '2', 'lokasi': 'STA 0+004'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '4', 'lokasi': 'STA 0+004'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Pemasangan U-Ditch sepanjang 4 m1 selesai tepat waktu.',
        catatan: 'Sambungan antar precast di-grouting semen kedap air.',
      ),

      // ────────── MINGGU 2 (27 April - 03 Mei 2026) ──────────
      _buildSingleDailyReport(
        id: 'rep-mt-20260427',
        tanggal: '2026-04-27',
        tanggalFormatted: 'Senin, 27 April 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '10.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+008 - STA 0+018 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '10 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+008'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+008'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '5', 'lokasi': 'STA 0+008'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.05 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+008',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 0+008'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Galian dan pemasangan saluran U berjalan optimal.',
        catatan: 'Arus lalu lintas lancar dengan buka-tutup jalur oleh flagman.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260428',
        tanggal: '2026-04-28',
        tanggalFormatted: 'Selasa, 28 April 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '12.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+018 - STA 0+030 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '12 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+018'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+018'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '5', 'lokasi': 'STA 0+018'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.2',
            'jenis': 'Mobilisasi',
            'volume': '0.30 Ls',
            'satuan': 'Ls',
            'lokasi': 'Base Camp & Ruas Jalan',
            'materials': [],
            'peralatans': [
              {'no': '2.1', 'jenis': 'Tandem Roller 6-8 Ton', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TR-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '2.1', 'role': 'Operator Tandem', 'cacah': '1', 'lokasi': 'Base Camp'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Mobilisasi seluruh alat berat utama dinyatakan rampung 100%.',
        catatan: 'Inspeksi kondisi alat berat oleh Site Engineer konsultan pengawas.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260430',
        tanggal: '2026-04-30',
        tanggalFormatted: 'Kamis, 30 April 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(12)',
            'jenis': 'Gorong-Gorong Kotak Beton Bertulang Ukuran dalam 50cmx50cm',
            'volume': '4.80 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+150 (Crossing Melintang Jalan)',
            'materials': [
              {'no': '1.1', 'jenis': 'Box Culvert 50x50 Precast', 'volume': '4.80 m1 (4 Unit)', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+150'},
              {'no': '1.2', 'jenis': 'Lantai Kerja Beton & Pasir', 'volume': '1.20 m³', 'lokasiAwal': 'Quarry', 'lokasiTujuan': 'STA 0+150'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Stamper Kuda', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'ST-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Pelaksana Lapangan', 'cacah': '1', 'lokasi': 'STA 0+150'},
              {'no': '1.2', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+150'},
              {'no': '1.3', 'role': 'Pekerja', 'cacah': '6', 'lokasi': 'STA 0+150'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.05 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+150 Crossing',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3 & Flagman', 'cacah': '2', 'lokasi': 'STA 0+150'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Pembongkaran aspal crossing dan pemasangan Box Culvert 50x50 selesai dalam 1 hari.',
        catatan: 'Pekerjaan crossing jalan selesai pukul 16:30, langsung diurug dan dipadatkan agar dapat dilalui kendaraan malam hari.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260502',
        tanggal: '2026-05-02',
        tanggalFormatted: 'Sabtu, 02 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '13.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+030 - STA 0+043 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '13 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+030'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+030'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '5', 'lokasi': 'STA 0+030'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.05 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+030',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 0+030'},
            ],
          },
        ],
        cuaca: 'Cerah Berawan',
        kejadian: 'Pemasangan saluran U minggu ke-2 tuntas 35 m1 (kumulatif 43 m1).',
        catatan: 'Opname bersama konsultan pengawas untuk evaluasi progres fisik minggu ke-2.',
      ),

      // ────────── MINGGU 3 (04 Mei - 10 Mei 2026) ──────────
      _buildSingleDailyReport(
        id: 'rep-mt-20260504',
        tanggal: '2026-05-04',
        tanggalFormatted: 'Senin, 04 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '15.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+043 - STA 0+058 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '15 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+043'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+043'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '5', 'lokasi': 'STA 0+043'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.05 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+043',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 0+043'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Galian tanah dan pemasangan saluran U berjalan lancar.',
        catatan: 'Material galian langsung dimuat ke dump truck untuk dibuang ke disposal area.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260506',
        tanggal: '2026-05-06',
        tanggalFormatted: 'Rabu, 06 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '15.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+058 - STA 0+073 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '15 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+058'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+058'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '5', 'lokasi': 'STA 0+058'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '7.3(1)',
            'jenis': 'Baja Tulangan Polos-BjTP 280',
            'volume': '25.00 kg',
            'satuan': 'kg',
            'lokasi': 'STA 0+250 (Inlet Drainase)',
            'materials': [
              {'no': '2.1', 'jenis': 'Besi Beton Polos d=10mm', 'volume': '25.00 kg', 'lokasiAwal': 'Gudang', 'lokasiTujuan': 'STA 0+250'},
            ],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Tukang Besi', 'cacah': '2', 'lokasi': 'STA 0+250'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Fabrikasi dan perakitan pembesian inlet drainase.',
        catatan: 'Jarak sengkang dan selimut beton diperiksa sesuai gambar kerja.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260508',
        tanggal: '2026-05-08',
        tanggalFormatted: 'Jumat, 08 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '15.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+073 - STA 0+088 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '15 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+073'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+073'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '5', 'lokasi': 'STA 0+073'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '7.3(1)',
            'jenis': 'Baja Tulangan Polos-BjTP 280',
            'volume': '25.00 kg',
            'satuan': 'kg',
            'lokasi': 'STA 0+250 (Dinding Sayap Inlet)',
            'materials': [
              {'no': '2.1', 'jenis': 'Besi Beton Polos d=10mm', 'volume': '25.00 kg', 'lokasiAwal': 'Gudang', 'lokasiTujuan': 'STA 0+250'},
            ],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Tukang Besi', 'cacah': '2', 'lokasi': 'STA 0+250'},
            ],
          },
          {
            'no': '3',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.05 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+073',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '3.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 0+073'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Pemasangan bekisting inlet selesai, persiapan pengecoran besok.',
        catatan: 'Kekakuan bekisting dan kebersihan area cor dicek oleh inspektor.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260509',
        tanggal: '2026-05-09',
        tanggalFormatted: 'Sabtu, 09 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '7.1(8)',
            'jenis': 'Beton fc\' 15Mpa',
            'volume': '2.00 m3',
            'satuan': 'm3',
            'lokasi': 'STA 0+250 (Inlet Drainase & Dinding Sayap)',
            'materials': [
              {'no': '1.1', 'jenis': 'Ready Mix Beton fc\' 15 MPa', 'volume': '2.00 m³', 'lokasiAwal': 'Batching Plant Kalimanah', 'lokasiTujuan': 'STA 0+250'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Truck Mixer 5 m3', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TM-02', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Concrete Vibrator', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'CV-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Cor & Vibrator', 'cacah': '2', 'lokasi': 'STA 0+250'},
              {'no': '1.2', 'role': 'Pekerja Pengecoran', 'cacah': '4', 'lokasi': 'STA 0+250'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.05 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+250',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 0+250'},
            ],
          },
        ],
        cuaca: 'Cerah Berawan',
        kejadian: 'Pengecoran inlet drainase STA 0+250 volume 2.00 m3 terlaksana dengan baik.',
        catatan: 'Slump test tercatat 10±2 cm, dibuat 3 buah silinder beton uji tekan 28 hari.',
        hasRekapBeton: true,
      ),

      // ────────── MINGGU 4 (11 Mei - 17 Mei 2026) ──────────
      _buildSingleDailyReport(
        id: 'rep-mt-20260511',
        tanggal: '2026-05-11',
        tanggalFormatted: 'Senin, 11 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '14.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+088 - STA 0+102 (Sisi Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '14 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+088'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+088'},
              {'no': '1.2', 'role': 'Pekerja', 'cacah': '5', 'lokasi': 'STA 0+088'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.10 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+088',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 0+088'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Pemasangan saluran U lanjutan STA 0+088 berjalan lancar.',
        catatan: 'Pengawasan perletakan pasir landasan tebal 10 cm dipadatkan.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260512',
        tanggal: '2026-05-12',
        tanggalFormatted: 'Selasa, 12 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '2.3.(24)',
            'jenis': 'Saluran berbentuk U Tipe DS 2',
            'volume': '13.00 m1',
            'satuan': 'm1',
            'lokasi': 'STA 0+102 - STA 0+115 (Ujung Saluran Kiri)',
            'materials': [
              {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '13 Unit', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+102'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Excavator Mini PC-50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Tukang Pasang Precast', 'cacah': '3', 'lokasi': 'STA 0+102'},
              {'no': '1.2', 'role': 'Pekerja Galian', 'cacah': '5', 'lokasi': 'STA 0+102'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '7.1(8)',
            'jenis': 'Beton fc\' 15Mpa',
            'volume': '2.793 m3',
            'satuan': 'm3',
            'lokasi': 'STA 0+450 (Inlet & Dinding Sayap Drainase)',
            'materials': [
              {'no': '2.1', 'jenis': 'Beton Ready Mix fc\' 15 MPa', 'volume': '2.793 m³', 'lokasiAwal': 'Batching Plant Kalimanah', 'lokasiTujuan': 'STA 0+450'},
              {'no': '2.2', 'jenis': 'Baja Tulangan BjTP 280', 'volume': '43.52 kg', 'lokasiAwal': 'Gudang Proyek', 'lokasiTujuan': 'STA 0+450'},
            ],
            'peralatans': [
              {'no': '2.1', 'jenis': 'Truck Mixer 5 m3', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TM-03', 'rusak': '-'},
              {'no': '2.2', 'jenis': 'Concrete Vibrator', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'CV-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '2.1', 'role': 'Tukang Cor & Vibrator', 'cacah': '2', 'lokasi': 'STA 0+450'},
              {'no': '2.2', 'role': 'Pekerja Pengecoran', 'cacah': '4', 'lokasi': 'STA 0+450'},
            ],
          },
          {
            'no': '3',
            'noMataPembayaran': '7.3(1)',
            'jenis': 'Baja Tulangan Polos-BjTP 280',
            'volume': '43.52 kg',
            'satuan': 'kg',
            'lokasi': 'STA 0+450',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '3.1', 'role': 'Tukang Besi', 'cacah': '2', 'lokasi': 'STA 0+450'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Seluruh pekerjaan saluran U (total 115 m1) dan struktur beton (total 4.793 m3) telah selesai 100% sesuai target Addendum CCO.',
        catatan:
            'Kemiringan elevasi dasar saluran diperiksa waterpass, slump test beton fc\' 15Mpa tercatat 10±2 cm, benda uji silinder diambil 3 buah.',
        hasRekapBeton: true,
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260514',
        tanggal: '2026-05-14',
        tanggalFormatted: 'Kamis, 14 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '1.19',
            'jenis': 'Biaya Penerapan SMKK',
            'volume': '0.50 Ls',
            'satuan': 'Ls',
            'lokasi': 'Ruas Jalan Letjen MT Haryono',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '1.1', 'role': 'Petugas SMKK', 'cacah': '1', 'lokasi': 'Ruas Jalan'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.10 Ls',
            'satuan': 'Ls',
            'lokasi': 'Ruas Jalan Letjen MT Haryono',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'Ruas Jalan'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Pembersihan permukaan aspal lama menggunakan air compressor sebagai persiapan prime coat besok.',
        catatan: 'Permukaan badan jalan bersih dari debu, kotoran, dan genangan air.',
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260515',
        tanggal: '2026-05-15',
        tanggalFormatted: 'Jumat, 15 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '6.1 (1)(a)',
            'jenis': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
            'volume': '118.79 liter',
            'satuan': 'liter',
            'lokasi': 'STA 0+000 - STA 0+250',
            'materials': [
              {'no': '1.1', 'jenis': 'Aspal Cair Emulsi CSS-1', 'volume': '120 liter', 'lokasiAwal': 'AMP Kalimanah', 'lokasiTujuan': 'STA 0+000'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Asphalt Sprayer Manual', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'AS-01', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Air Compressor', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'AC-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Operator Sprayer', 'cacah': '1', 'lokasi': 'STA 0+000'},
              {'no': '1.2', 'role': 'Pekerja Pembersih Debu', 'cacah': '3', 'lokasi': 'STA 0+000'},
            ],
          },
          {
            'no': '2',
            'noMataPembayaran': '1.8.(1)',
            'jenis': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'volume': '0.10 Ls',
            'satuan': 'Ls',
            'lokasi': 'STA 0+000 - STA 0+250',
            'materials': [],
            'peralatans': [],
            'personils': [
              {'no': '2.1', 'role': 'Petugas K3 & Flagman', 'cacah': '2', 'lokasi': 'STA 0+000'},
            ],
          },
        ],
        cuaca: 'Cerah Berawan',
        kejadian: 'Penyemprotan prime coat (Lapis Resap Pengikat) selesai 118.79 liter tepat waktu sebelum tengah hari.',
        catatan:
            'Permukaan eksisting dibersihkan menggunakan kompresor udara dari debu dan kotoran. Penyemprotan merata dengan temperatur emulsi 45°C.',
        hasRekapAspal: true,
      ),

      // ────────── MINGGU 5 (18 Mei - 24 Mei 2026) ──────────
      _buildSingleDailyReport(
        id: 'rep-mt-20260518',
        tanggal: '2026-05-18',
        tanggalFormatted: 'Senin, 18 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '6.7.(1)',
            'jenis': 'Lapis Penetrasi Macadam',
            'volume': '5.00 m3',
            'satuan': 'm3',
            'lokasi': 'STA 0+000 - STA 0+080',
            'materials': [
              {'no': '1.1', 'jenis': 'Agregat Pokok Batu Pecah 5/7', 'volume': '5.00 m³', 'lokasiAwal': 'Quarry Kalimanah', 'lokasiTujuan': 'STA 0+000'},
              {'no': '1.2', 'jenis': 'Aspal Panas Pen 60/70', 'volume': '350 kg', 'lokasiAwal': 'Gudang Aspal', 'lokasiTujuan': 'STA 0+000'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Tandem Roller 6-8 Ton', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TR-01', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Asphalt Sprayer', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'AS-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Operator Tandem Roller', 'cacah': '1', 'lokasi': 'STA 0+000'},
              {'no': '1.2', 'role': 'Pekerja Hampar Agregat', 'cacah': '6', 'lokasi': 'STA 0+000'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Penghamparan agregat pokok lapen STA 0+000 s/d 0+080 dan pemadatan awal.',
        catatan: 'Ketebalan gembur agregat diperiksa berkala sebelum disemprot aspal panas suhu 145°C.',
        hasRekapAspal: true,
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260520',
        tanggal: '2026-05-20',
        tanggalFormatted: 'Rabu, 20 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '6.7.(1)',
            'jenis': 'Lapis Penetrasi Macadam',
            'volume': '5.00 m3',
            'satuan': 'm3',
            'lokasi': 'STA 0+080 - STA 0+160',
            'materials': [
              {'no': '1.1', 'jenis': 'Agregat Pokok Batu Pecah 5/7', 'volume': '5.00 m³', 'lokasiAwal': 'Quarry Kalimanah', 'lokasiTujuan': 'STA 0+080'},
              {'no': '1.2', 'jenis': 'Aspal Panas Pen 60/70', 'volume': '350 kg', 'lokasiAwal': 'Gudang Aspal', 'lokasiTujuan': 'STA 0+080'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Tandem Roller 6-8 Ton', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TR-01', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Asphalt Sprayer', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'AS-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Operator Tandem Roller', 'cacah': '1', 'lokasi': 'STA 0+080'},
              {'no': '1.2', 'role': 'Pekerja Hampar Agregat', 'cacah': '6', 'lokasi': 'STA 0+080'},
            ],
          },
        ],
        cuaca: 'Cerah',
        kejadian: 'Penghamparan agregat pokok lanjutan STA 0+080 s/d 0+160 dan penyemprotan aspal.',
        catatan: 'Pemadatan interlocking agregat tercapai dengan 6 lintasan tandem roller.',
        hasRekapAspal: true,
      ),
      _buildSingleDailyReport(
        id: 'rep-mt-20260522',
        tanggal: '2026-05-22',
        tanggalFormatted: 'Jumat, 22 Mei 2026',
        pekerjaan: [
          {
            'no': '1',
            'noMataPembayaran': '6.7.(1)',
            'jenis': 'Lapis Penetrasi Macadam',
            'volume': '5.00 m3',
            'satuan': 'm3',
            'lokasi': 'STA 0+160 - STA 0+240',
            'materials': [
              {'no': '1.1', 'jenis': 'Agregat Pokok Batu Pecah 5/7 & Pengunci 2/3', 'volume': '5.00 m³', 'lokasiAwal': 'Quarry Kalimanah', 'lokasiTujuan': 'STA 0+160'},
              {'no': '1.2', 'jenis': 'Aspal Panas Pen 60/70', 'volume': '350 kg', 'lokasiAwal': 'Gudang Aspal', 'lokasiTujuan': 'STA 0+160'},
            ],
            'peralatans': [
              {'no': '1.1', 'jenis': 'Tandem Roller 6-8 Ton', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TR-01', 'rusak': '-'},
              {'no': '1.2', 'jenis': 'Asphalt Sprayer', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'AS-01', 'rusak': '-'},
            ],
            'personils': [
              {'no': '1.1', 'role': 'Operator Tandem Roller', 'cacah': '1', 'lokasi': 'STA 0+160'},
              {'no': '1.2', 'role': 'Pekerja Hampar Agregat', 'cacah': '6', 'lokasi': 'STA 0+160'},
            ],
          },
        ],
        cuaca: 'Cerah Berawan',
        kejadian: 'Penghamparan agregat pengunci dan pemadatan akhir lapen minggu ke-5 selesai total 15 m3.',
        catatan: 'Permukaan lapen rata dan padat, siap untuk pekerjaan lapis permukaan Latasir Kelas B.',
        hasRekapAspal: true,
      ),
    ];
  }

  static Map<String, dynamic> _buildSingleDailyReport({
    required String id,
    required String tanggal,
    required String tanggalFormatted,
    required List<Map<String, dynamic>> pekerjaan,
    required String cuaca,
    required String kejadian,
    required String catatan,
    bool hasRekapAspal = false,
    bool hasRekapBeton = false,
  }) {
    final List<Map<String, dynamic>> flatMaterials = [];
    final List<Map<String, dynamic>> flatPeralatan = [];
    final List<Map<String, dynamic>> flatPersonil = [];

    for (var p in pekerjaan) {
      final mats = p['materials'] as List? ?? [];
      for (var m in mats) {
        flatMaterials.add(Map<String, dynamic>.from(m));
      }
      final alats = p['peralatans'] as List? ?? [];
      for (var a in alats) {
        flatPeralatan.add(Map<String, dynamic>.from(a));
      }
      final pers = p['personils'] as List? ?? [];
      for (var pr in pers) {
        flatPersonil.add(Map<String, dynamic>.from(pr));
      }
    }

    return {
      'id': id,
      'tanggal': tanggal,
      'tanggalFormatted': tanggalFormatted,
      'namaKontrak': 'PEMELIHARAAN BERKALA JL. MT HARYONO',
      'namaKegiatan': 'Pemeliharaan Berkala Jalan Paket 2 (Ruas Letjen MT Haryono)',
      'lokasi': 'Ruas Letjen MT Haryono - Letnan Sudani',
      'lokasiSta': 'STA 0+000 - STA 0+458',
      'sumberDana': 'APBD Kab. Purbalingga',
      'kontraktor': 'CV. DIVAN INSAN CEMERLANG',

      // Data Rincian Buku Harian Standar PU
      'pekerjaanList': pekerjaan,
      'materialList': flatMaterials,
      'peralatanList': flatPeralatan,
      'personilList': flatPersonil,
      'cuacaKejadianList': [
        {
          'no': '1',
          'cuaca': cuaca,
          'jenisKejadian': kejadian,
          'jam': '08:00 - 16:30',
          'lokasi': 'STA 0+000 - STA 0+458',
          'tanggungJawab': 'Kontraktor Pelaksana',
          'akibat': 'Pekerjaan berjalan lancar sesuai schedule',
        },
      ],
      'instruksiList': [
        {
          'no': '1',
          'pihak': 'Konsultan Pengawas (CV. TATA SAKA CONSULTANT)',
          'uraian': 'Lakukan perawatan (curing) beton dengan penyiraman berkala dan lindungi prime coat dari lalu lintas umum.',
        },
      ],
      'instruksiKonsultan': 'Pekerjaan disetujui, pertahankan kerapian dan keselamatan kerja (SMK3).',
      'instruksiSaran': {
        'kontraktorUraian': 'Pekerjaan hari ini selesai sesuai target harian.',
        'dinasUraian': '',
        'konsultanUraian': 'Metode kerja disetujui, pastikan sambungan saluran kedap air.',
      },

      // Tanda Tangan Pengawas
      'ttdNama': 'MUBALLIGH, ST., M.Sc.',
      'ttdJabatan': 'Inspektor Lapangan',
      'ttdSignature': '',
      'ttdPengawasList': [
        {
          'nama': 'MUBALLIGH, ST., M.Sc.',
          'jabatan': 'Inspektor Lapangan',
          'signature': '',
        },
        {
          'nama': 'SENDAYU GALIH K., ST',
          'jabatan': 'Site Engineer',
          'signature': '',
        },
      ],
      'catatanPengawas': catatan,
      'temuan': pekerjaan.map((p) => '${p['jenis']} (${p['volume']})').join(', '),

      // Rekapitulasi Beton (Truck Mixer)
      'hasRekapBeton': hasRekapBeton,
      'hasRekapitulasiBeton': hasRekapBeton,
      'jenisBeton': hasRekapBeton ? "fc' 15 MPa" : '',
      'penyediaJasaBeton': hasRekapBeton ? 'CV. DIVAN INSAN CEMERLANG' : '',
      'rekapPengecoranBetonList': hasRekapBeton
          ? [
              {
                'no': '1',
                'nomorKendaraan': 'R 9123 AB',
                'batchingPlant': 'PT. VARIA USAHA BETON',
                'jamBerangkat': '09:15:00',
                'jamDatang': '09:45:00',
                'jamBerangkatLap': '10:30:00',
                'jamTibaPlant': '11:00:00',
                'slumpTest': '10 cm',
                'volume': '2.50',
                'volumeKumulatif': '2.50',
              },
            ]
          : [],

      // Rekapitulasi DT Aspal (Lapis Resap Pengikat / Hotmix)
      'hasRekapAspal': hasRekapAspal,
      'hasRekapitulasiAspal': hasRekapAspal,
      'hasRekapPerjalananDt': hasRekapAspal,
      'hasRekapSuhuLapangan': hasRekapAspal,
      'hasRekapSuhuAmp': hasRekapAspal,
      'hasRekapTonaseAspal': hasRekapAspal,
      'jenisMaterialAspal': hasRekapAspal ? 'Lapis Resap Pengikat (Emulsi)' : '',
      'penyediaAmp': hasRekapAspal ? 'PT. PUSPITA JAYA KALIMANAH' : '',
      'jarakTempuh': hasRekapAspal ? '12.5' : '',
      'rekapPengirimanDtList': hasRekapAspal
          ? [
              {
                'no': '1',
                'nomorPolisi': 'R 8076 OE',
                'jamBerangkat': '08:15:00',
                'jamTiba': '08:45:00',
                'waktuTempuh': '0.500',
                'kecepatan': '25.0',
                'jamMulaiHampar': '08:50:00',
                'waktuTunggu': '5',
                'jamSelesaiHampar': '09:30:00',
                'suhuAmp': '155',
                'suhuDatang': '148',
                'suhuHampar': '145',
                'suhuPadat': '135',
                'suhuAkhir': '95',
                'tonase': '8.5',
                'beratNetto': '8.5',
                'keterangan': 'Baik',
              },
            ]
          : [],
    };
  }
}
