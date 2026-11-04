import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';

class SampleContractData {
  static ContractModel getDemoContract() {
    return ContractModel(
      id: 'kontrak-mt-haryono-demo',
      jenisKegiatan: 'Pengawasan Teknis',
      namaKontrak: 'PEMELIHARAAN BERKALA JL. MT HARYONO',
      nomorSpk: '000.3.3/1128/KONST/BM/X/2026',
      tglMulaiSpk: '20 Oktober 2026',
      nomorSpmk: '000.3.3/1128/KONST/BM/X/2026',
      tglMulaiSpmk: '20 Oktober 2026',
      tglSelesaiSpmk: '18 Januari 2027',
      hariKalender: 90,
      nilaiKontrak: 'Rp 2.450.000.000,00',
      instansiDinas: ['DPUPR Kab. Purbalingga'],
      sumberDana: 'APBD Kab. Purbalingga',
      deskripsi: 'Pekerjaan Pengawasan Teknis Pemeliharaan Berkala Jl. MT Haryono (3 Ruas Jalan)',
      progressFisik: 0.185,
      strukturOrganisasi: {
        'siteEngineer': 'SENDAYU GALIH K., ST',
        'inspektors': ['MUBALLIGH, ST., M.Sc.', 'BILAL, A.Md'],
        'administrasi': 'HANGGORO AJI',
      },
      folders: [
        {'name': 'SPK', 'isExpanded': false, 'documents': []},
        {'name': 'SPMK', 'isExpanded': false, 'documents': []},
        {'name': 'Adendum Konsultan', 'isExpanded': false, 'documents': []},
      ],
      kegiatans: [
        _buildRuasJalanA(),
        _buildRuasJalanB(),
        _buildRuasJalanC(),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 1. RUAS JALAN A
  // ─────────────────────────────────────────────────────────────
  static Map<String, dynamic> _buildRuasJalanA() {
    final rkk = _buildSampleRkk('Ruas Jalan A');
    return {
      'namaKegiatan': 'Ruas Jalan A',
      'lokasi': 'STA 0+000 - STA 1+250',
      'kontraktor': 'CV. SATYA WIGUNA',
      'penggunaAnggaran': 'DRAJAT UJI WAKHYONO, S.T., M.T.',
      'stafTeknis1': 'MUBALLIGH, ST., M.Sc.',
      'stafTeknis2': 'BILAL, A.Md',
      'siteEngineerKegiatan': 'SENDAYU GALIH K., ST',
      'direkturPenyedia': 'IKSAN',
      'direkturKontraktor': 'IKSAN',
      'pelaksanaLapangan': 'GALIH WAHYU UTAMA',
      'petugasK3': 'IQBAL ZAINUL ARIFIN',
      'rkkDivisiList': rkk,
      'folders': [
        {'name': 'Laporan Harian', 'isExpanded': false, 'documents': []},
        {'name': 'Laporan Mingguan', 'isExpanded': true, 'documents': []},
        {'name': 'Foto Progres', 'isExpanded': false, 'documents': []},
      ],
      'laporanMingguan': [
        _buildWeeklyReport(
          mingguKe: 1,
          periodeAwal: '26 Oktober 2026',
          periodeAkhir: '01 November 2026',
          rencana: 6.50,
          realisasi: 7.20,
          kegiatanNama: 'Ruas Jalan A',
          kontraktor: 'CV. SATYA WIGUNA',
        ),
      ],
      'laporans': [
        _buildDailyReport(
          id: 'rep-a-20261029',
          tanggal: '2026-10-29',
          tanggalFormatted: 'Kamis, 29 Oktober 2026',
          kegiatanNama: 'Ruas Jalan A',
          lokasiSta: 'STA 0+000 - STA 0+350',
          kontraktor: 'CV. SATYA WIGUNA',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Galian Tanah untuk Saluran Drainase',
              'volume': '42.00 m³',
              'lokasi': 'STA 0+000 - STA 0+200',
              'satuan': 'm3',
              'materials': [],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Excavator Mini PC 50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
                {'no': '1.2', 'jenis': 'Dump Truck 5 Ton', 'cacahAktif': '2 Unit', 'jumlah': '2 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'DT-01 & DT-02', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana', 'cacah': '1', 'lokasi': 'STA 0+000'},
                {'no': '1.2', 'role': 'Pekerja Galian', 'cacah': '6', 'lokasi': 'STA 0+000 - 0+200'},
              ],
            },
          ],
          cuaca: 'Cerah Berawan',
          kejadian: 'Normal Berjalan Baik',
          catatan: 'Pekerjaan galian elevasi dasar saluran sesuai gambar rencana (shop drawing).',
        ),
        _buildDailyReport(
          id: 'rep-a-20261030',
          tanggal: '2026-10-30',
          tanggalFormatted: 'Jumat, 30 Oktober 2026',
          kegiatanNama: 'Ruas Jalan A',
          lokasiSta: 'STA 0+000 - STA 0+250',
          kontraktor: 'CV. SATYA WIGUNA',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Pemasangan U-Ditch Precast DS 2 (40x40 cm)',
              'volume': '25.00 m1',
              'lokasi': 'STA 0+000 - STA 0+100',
              'satuan': 'm1',
              'materials': [
                {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '25 Buah', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+000'},
                {'no': '1.2', 'jenis': 'Pasir Urug Dasar', 'volume': '3.50 m³', 'lokasiAwal': 'Quarry', 'lokasiTujuan': 'STA 0+000'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Crane Truck 3 Ton', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'CR-01', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Mandor', 'cacah': '1', 'lokasi': 'STA 0+000'},
                {'no': '1.2', 'role': 'Tukang Pasang', 'cacah': '3', 'lokasi': 'STA 0+000'},
                {'no': '1.3', 'role': 'Pekerja Bantu', 'cacah': '4', 'lokasi': 'STA 0+000'},
              ],
            },
          ],
          cuaca: 'Cerah',
          kejadian: 'Lancar',
          catatan: 'Elevasi kemiringan aliran air dipantau waterpass, saluran mengalir lancar.',
        ),
        _buildDailyReport(
          id: 'rep-a-20261031',
          tanggal: '2026-10-31',
          tanggalFormatted: 'Sabtu, 31 Oktober 2026',
          kegiatanNama: 'Ruas Jalan A',
          lokasiSta: 'STA 0+250 - STA 0+500',
          kontraktor: 'CV. SATYA WIGUNA',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
              'volume': '85.00 liter',
              'lokasi': 'STA 0+100 - STA 0+350',
              'satuan': 'liter',
              'materials': [
                {'no': '1.1', 'jenis': 'Aspal Emulsi Prime Coat', 'volume': '85 liter', 'lokasiAwal': 'Gudang Aspal', 'lokasiTujuan': 'STA 0+100'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Asphalt Distributor Mini', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'AD-01', 'rusak': '-'},
                {'no': '1.2', 'jenis': 'Air Compressor', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'CP-01', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Operator Distributor', 'cacah': '1', 'lokasi': 'STA 0+100'},
                {'no': '1.2', 'role': 'Pekerja Semprot', 'cacah': '3', 'lokasi': 'STA 0+100'},
              ],
            },
          ],
          cuaca: 'Cerah',
          kejadian: 'Penyemprotan prime coat merata',
          catatan: 'Permukaan jalan telah dibersihkan kompresor sebelum disemprot aspal cair.',
        ),
        _buildDailyReport(
          id: 'rep-a-20261101',
          tanggal: '2026-11-01',
          tanggalFormatted: 'Minggu, 01 November 2026',
          kegiatanNama: 'Ruas Jalan A',
          lokasiSta: 'STA 0+100 - STA 0+400',
          kontraktor: 'CV. SATYA WIGUNA',
          hasRekapAspal: true,
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'LATASIR KELAS B (1,5 cm)',
              'volume': '320.00 m2',
              'lokasi': 'STA 0+100 - STA 0+300',
              'satuan': 'm2',
              'materials': [
                {'no': '1.1', 'jenis': 'Campuran Aspal Panas Latasir B', 'volume': '22.50 Ton', 'lokasiAwal': 'AMP Kalimanah', 'lokasiTujuan': 'STA 0+100'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Asphalt Finisher', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'AF-01', 'rusak': '-'},
                {'no': '1.2', 'jenis': 'Tandem Roller', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TR-01', 'rusak': '-'},
                {'no': '1.3', 'jenis': 'Pneumatic Tire Roller (PTR)', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'PTR-01', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana Aspal', 'cacah': '1', 'lokasi': 'STA 0+100'},
                {'no': '1.2', 'role': 'Operator Alat Berat', 'cacah': '3', 'lokasi': 'STA 0+100'},
                {'no': '1.3', 'role': 'Pekerja Hampar', 'cacah': '6', 'lokasi': 'STA 0+100'},
              ],
            },
          ],
          cuaca: 'Cerah',
          kejadian: 'Penghamparan aspal berjalan tertib',
          catatan: 'Suhu hampar terpantau 145°C - 150°C, pemadatan awal langsung menyusul finisher.',
        ),
        _buildDailyReport(
          id: 'rep-a-20261102',
          tanggal: '2026-11-02',
          tanggalFormatted: 'Senin, 02 November 2026',
          kegiatanNama: 'Ruas Jalan A',
          lokasiSta: 'STA 0+300 - STA 0+550',
          kontraktor: 'CV. SATYA WIGUNA',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Saluran berbentuk U Tipe DS 2',
              'volume': '30.00 m1',
              'lokasi': 'STA 0+200 - STA 0+320',
              'satuan': 'm1',
              'materials': [
                {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '30 Buah', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 0+200'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Excavator Mini PC 50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-01', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Mandor', 'cacah': '1', 'lokasi': 'STA 0+200'},
                {'no': '1.2', 'role': 'Tukang Pasang', 'cacah': '4', 'lokasi': 'STA 0+200'},
                {'no': '1.3', 'role': 'Pekerja Bantu', 'cacah': '5', 'lokasi': 'STA 0+200'},
              ],
            },
          ],
          cuaca: 'Cerah Pagi, Siang Berawan',
          kejadian: 'Pekerjaan berjalan normal',
          catatan: 'Penyusunan U-Ditch berlanjut ke STA 0+320, sambungan antar blok di-mortar rapi.',
        ),
      ],
    };
  }

  // ─────────────────────────────────────────────────────────────
  // 2. RUAS JALAN B
  // ─────────────────────────────────────────────────────────────
  static Map<String, dynamic> _buildRuasJalanB() {
    final rkk = _buildSampleRkk('Ruas Jalan B');
    return {
      'namaKegiatan': 'Ruas Jalan B',
      'lokasi': 'STA 1+250 - STA 2+500',
      'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
      'penggunaAnggaran': 'DRAJAT UJI WAKHYONO, S.T., M.T.',
      'stafTeknis1': 'MUBALLIGH, ST., M.Sc.',
      'stafTeknis2': 'BILAL, A.Md',
      'siteEngineerKegiatan': 'SENDAYU GALIH K., ST',
      'direkturPenyedia': 'MISWANTO',
      'direkturKontraktor': 'MISWANTO',
      'pelaksanaLapangan': 'TEGUH TRIYONO',
      'petugasK3': 'HARSONO',
      'rkkDivisiList': rkk,
      'folders': [
        {'name': 'Laporan Harian', 'isExpanded': false, 'documents': []},
        {'name': 'Laporan Mingguan', 'isExpanded': true, 'documents': []},
        {'name': 'Foto Progres', 'isExpanded': false, 'documents': []},
      ],
      'laporanMingguan': [
        _buildWeeklyReport(
          mingguKe: 1,
          periodeAwal: '26 Oktober 2026',
          periodeAkhir: '01 November 2026',
          rencana: 5.80,
          realisasi: 6.10,
          kegiatanNama: 'Ruas Jalan B',
          kontraktor: 'CV. DIVAN INSAN CEMERLANG',
        ),
      ],
      'laporans': [
        _buildDailyReport(
          id: 'rep-b-20261030',
          tanggal: '2026-10-30',
          tanggalFormatted: 'Jumat, 30 Oktober 2026',
          kegiatanNama: 'Ruas Jalan B',
          lokasiSta: 'STA 1+250 - STA 1+600',
          kontraktor: 'CV. DIVAN INSAN CEMERLANG',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Gorong2 Kotak Beton Bertulang Ukuran dalam 50x50cm',
              'volume': '2.40 m1',
              'lokasi': 'STA 1+350 Crossing',
              'satuan': 'm1',
              'materials': [
                {'no': '1.1', 'jenis': 'Box Culvert 50x50 cm', 'volume': '2 Buah', 'lokasiAwal': 'Basecamp', 'lokasiTujuan': 'STA 1+350'},
                {'no': '1.2', 'jenis': 'Beton fc 15Mpa (Lantai Kerja)', 'volume': '0.80 m³', 'lokasiAwal': 'Batching Plant', 'lokasiTujuan': 'STA 1+350'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Excavator PC 75', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-02', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana', 'cacah': '1', 'lokasi': 'STA 1+350'},
                {'no': '1.2', 'role': 'Tukang Beton', 'cacah': '3', 'lokasi': 'STA 1+350'},
                {'no': '1.3', 'role': 'Pekerja', 'cacah': '4', 'lokasi': 'STA 1+350'},
              ],
            },
          ],
          cuaca: 'Cerah',
          kejadian: 'Lancar',
          catatan: 'Pemasangan box culvert crossing jalan terlaksana separuh badan jalan agar lalu lintas tetap mengalir.',
        ),
        _buildDailyReport(
          id: 'rep-b-20261031',
          tanggal: '2026-10-31',
          tanggalFormatted: 'Sabtu, 31 Oktober 2026',
          kegiatanNama: 'Ruas Jalan B',
          lokasiSta: 'STA 1+350 - STA 1+700',
          kontraktor: 'CV. DIVAN INSAN CEMERLANG',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Lapis Penetrasi Macadam',
              'volume': '12.50 m3',
              'lokasi': 'STA 1+300 - STA 1+550',
              'satuan': 'm3',
              'materials': [
                {'no': '1.1', 'jenis': 'Batu Pecah 5/7 & 3/5', 'volume': '15 m³', 'lokasiAwal': 'Quarry', 'lokasiTujuan': 'STA 1+300'},
                {'no': '1.2', 'jenis': 'Aspal Keras Pen 60/70', 'volume': '450 kg', 'lokasiAwal': 'Gudang Aspal', 'lokasiTujuan': 'STA 1+300'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Three Wheel Roller 8 Ton', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TWR-01', 'rusak': '-'},
                {'no': '1.2', 'jenis': 'Asphalt Sprayer Manual', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'AS-01', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Mandor', 'cacah': '1', 'lokasi': 'STA 1+300'},
                {'no': '1.2', 'role': 'Pekerja Hampar Batu', 'cacah': '8', 'lokasi': 'STA 1+300'},
              ],
            },
          ],
          cuaca: 'Cerah Panas',
          kejadian: 'Hamparan agregat padat terkunci baik',
          catatan: 'Penggilasan awal macadam telah memenuhi standar kerataan sebelum disiram aspal panas.',
        ),
        _buildDailyReport(
          id: 'rep-b-20261102',
          tanggal: '2026-11-02',
          tanggalFormatted: 'Senin, 02 November 2026',
          kegiatanNama: 'Ruas Jalan B',
          lokasiSta: 'STA 1+700 - STA 2+100',
          kontraktor: 'CV. DIVAN INSAN CEMERLANG',
          hasRekapBeton: true,
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Beton fc\' 15Mpa',
              'volume': '4.50 m3',
              'lokasi': 'STA 1+700 - STA 1+800 Bahu Jalan',
              'satuan': 'm3',
              'materials': [
                {'no': '1.1', 'jenis': 'Beton Ready Mix fc 15 MPa', 'volume': '4.50 m³', 'lokasiAwal': 'PT. Varia Usaha Beton', 'lokasiTujuan': 'STA 1+700'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Truck Mixer 6 m³', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TM-03', 'rusak': '-'},
                {'no': '1.2', 'jenis': 'Concrete Vibrator', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'CV-01', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana Lapangan', 'cacah': '1', 'lokasi': 'STA 1+700'},
                {'no': '1.2', 'role': 'Tukang Cor', 'cacah': '3', 'lokasi': 'STA 1+700'},
                {'no': '1.3', 'role': 'Pekerja Bantu', 'cacah': '4', 'lokasi': 'STA 1+700'},
              ],
            },
          ],
          cuaca: 'Cerah Berawan',
          kejadian: 'Pengecoran berjalan lancar',
          catatan: 'Uji slump test beton 12 cm memenuhi toleransi spesifikasi teknis.',
        ),
      ],
    };
  }

  // ─────────────────────────────────────────────────────────────
  // 3. RUAS JALAN C
  // ─────────────────────────────────────────────────────────────
  static Map<String, dynamic> _buildRuasJalanC() {
    final rkk = _buildSampleRkk('Ruas Jalan C');
    return {
      'namaKegiatan': 'Ruas Jalan C',
      'lokasi': 'STA 2+500 - STA 3+800',
      'kontraktor': 'CV. LANGGENG',
      'penggunaAnggaran': 'DRAJAT UJI WAKHYONO, S.T., M.T.',
      'stafTeknis1': 'MUBALLIGH, ST., M.Sc.',
      'stafTeknis2': 'BILAL, A.Md',
      'siteEngineerKegiatan': 'SENDAYU GALIH K., ST',
      'direkturPenyedia': 'MARSONGKO',
      'direkturKontraktor': 'MARSONGKO',
      'pelaksanaLapangan': 'MARSONGKO',
      'petugasK3': 'SUHARTO',
      'rkkDivisiList': rkk,
      'folders': [
        {'name': 'Laporan Harian', 'isExpanded': false, 'documents': []},
        {'name': 'Laporan Mingguan', 'isExpanded': true, 'documents': []},
        {'name': 'Foto Progres', 'isExpanded': false, 'documents': []},
      ],
      'laporanMingguan': [
        _buildWeeklyReport(
          mingguKe: 1,
          periodeAwal: '26 Oktober 2026',
          periodeAkhir: '01 November 2026',
          rencana: 4.90,
          realisasi: 5.20,
          kegiatanNama: 'Ruas Jalan C',
          kontraktor: 'CV. LANGGENG',
        ),
      ],
      'laporans': [
        _buildDailyReport(
          id: 'rep-c-20261028',
          tanggal: '2026-10-28',
          tanggalFormatted: 'Rabu, 28 Oktober 2026',
          kegiatanNama: 'Ruas Jalan C',
          lokasiSta: 'STA 2+500 - STA 2+800',
          kontraktor: 'CV. LANGGENG',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Mobilisasi Alat & Penerapan SMKK (Rambu K3)',
              'volume': '1.00 Ls',
              'lokasi': 'STA 2+500',
              'satuan': 'Ls',
              'materials': [
                {'no': '1.1', 'jenis': 'Rambu Pengaman Lalu Lintas & Barricade', 'volume': '10 Set', 'lokasiAwal': 'Gudang CV. Langgeng', 'lokasiTujuan': 'STA 2+500'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Truk Tronton Self Loader', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TR-09', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana', 'cacah': '1', 'lokasi': 'STA 2+500'},
                {'no': '1.2', 'role': 'Petugas K3', 'cacah': '1', 'lokasi': 'STA 2+500'},
                {'no': '1.3', 'role': 'Flagman (Pengatur Lalu Lintas)', 'cacah': '2', 'lokasi': 'STA 2+500'},
              ],
            },
          ],
          cuaca: 'Cerah',
          kejadian: 'Rambu K3 terpasang lengkap di kedua ujung ruas jalan',
          catatan: 'Mobilisasi alat selesai, area kerja diamankan dengan traffic cone dan pita peringatan.',
        ),
        _buildDailyReport(
          id: 'rep-c-20261030',
          tanggal: '2026-10-30',
          tanggalFormatted: 'Jumat, 30 Oktober 2026',
          kegiatanNama: 'Ruas Jalan C',
          lokasiSta: 'STA 2+500 - STA 3+000',
          kontraktor: 'CV. LANGGENG',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Galian Saluran dan Perapian Bahu Jalan',
              'volume': '38.00 m³',
              'lokasi': 'STA 2+600 - STA 2+850',
              'satuan': 'm3',
              'materials': [],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Excavator PC 50', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'EX-05', 'rusak': '-'},
                {'no': '1.2', 'jenis': 'Dump Truck 4 Ton', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'DT-07', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana Lapangan', 'cacah': '1', 'lokasi': 'STA 2+600'},
                {'no': '1.2', 'role': 'Pekerja Galian', 'cacah': '5', 'lokasi': 'STA 2+600'},
              ],
            },
          ],
          cuaca: 'Cerah',
          kejadian: 'Galian tanah berjalan sesuai kemiringan desain',
          catatan: 'Tanah buangan hasil galian langsung diangkut dump truck agar tidak mengotori perkerasan aspal eksisting.',
        ),
        _buildDailyReport(
          id: 'rep-c-20261101',
          tanggal: '2026-11-01',
          tanggalFormatted: 'Minggu, 01 November 2026',
          kegiatanNama: 'Ruas Jalan C',
          lokasiSta: 'STA 2+850 - STA 3+200',
          kontraktor: 'CV. LANGGENG',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Saluran berbentuk U Tipe DS 2',
              'volume': '22.00 m1',
              'lokasi': 'STA 2+650 - STA 2+750',
              'satuan': 'm1',
              'materials': [
                {'no': '1.1', 'jenis': 'U-Ditch Precast DS 2', 'volume': '22 Buah', 'lokasiAwal': 'Pabrik Precast', 'lokasiTujuan': 'STA 2+650'},
                {'no': '1.2', 'jenis': 'Pasir Pasang Dasar', 'volume': '3.00 m³', 'lokasiAwal': 'Quarry', 'lokasiTujuan': 'STA 2+650'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Tripod Takel 3 Ton', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TK-01', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Tukang Pasang', 'cacah': '3', 'lokasi': 'STA 2+650'},
                {'no': '1.2', 'role': 'Pekerja Bantu', 'cacah': '4', 'lokasi': 'STA 2+650'},
              ],
            },
          ],
          cuaca: 'Berawan Sore',
          kejadian: 'Lancar',
          catatan: 'Pemasangan precast rapi, mortar nat kedap air.',
        ),
        _buildDailyReport(
          id: 'rep-c-20261102',
          tanggal: '2026-11-02',
          tanggalFormatted: 'Senin, 02 November 2026',
          kegiatanNama: 'Ruas Jalan C',
          lokasiSta: 'STA 3+000 - STA 3+400',
          kontraktor: 'CV. LANGGENG',
          pekerjaan: [
            {
              'no': '1',
              'jenis': 'Lapis Penetrasi Macadam',
              'volume': '10.50 m3',
              'lokasi': 'STA 2+900 - STA 3+100',
              'satuan': 'm3',
              'materials': [
                {'no': '1.1', 'jenis': 'Agregat Pokok 5/7', 'volume': '12.00 m³', 'lokasiAwal': 'Quarry', 'lokasiTujuan': 'STA 2+900'},
                {'no': '1.2', 'jenis': 'Aspal Bitumen Panas', 'volume': '380 kg', 'lokasiAwal': 'Gudang Aspal', 'lokasiTujuan': 'STA 2+900'},
              ],
              'peralatans': [
                {'no': '1.1', 'jenis': 'Tandem Roller', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit', 'noRusak': '-', 'jenisRusak': '-', 'kode': 'TR-02', 'rusak': '-'},
              ],
              'personils': [
                {'no': '1.1', 'role': 'Pelaksana', 'cacah': '1', 'lokasi': 'STA 2+900'},
                {'no': '1.2', 'role': 'Pekerja Hampar', 'cacah': '6', 'lokasi': 'STA 2+900'},
              ],
            },
          ],
          cuaca: 'Cerah',
          kejadian: 'Pekerjaan berjalan tepat waktu',
          catatan: 'Penggilasan lapis penetrasi rata tanpa gelombang, siap untuk penguncian pasir.',
        ),
      ],
    };
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER: BUILD DAILY REPORT
  // ─────────────────────────────────────────────────────────────
  static Map<String, dynamic> _buildDailyReport({
    required String id,
    required String tanggal,
    required String tanggalFormatted,
    required String kegiatanNama,
    required String lokasiSta,
    required String kontraktor,
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
      'namaKegiatan': kegiatanNama,
      'lokasi': lokasiSta,
      'lokasiSta': lokasiSta,
      'sumberDana': 'APBD Kab. Purbalingga',
      'kontraktor': kontraktor,

      // Format Dokumen Buku Harian Standar
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
          'lokasi': lokasiSta,
          'tanggungJawab': 'Kontraktor Pelaksana',
          'akibat': 'Pekerjaan berjalan sesuai jadwal',
        },
      ],
      'instruksiList': [
        {
          'no': '1',
          'pihak': 'Konsultan Pengawas (CV. TATA SAKA CONSULTANT)',
          'uraian': 'Pastikan selalu melakukan uji kontrol mutu dan dokumentasi foto sebelum dan sesudah pekerjaan.',
        },
      ],
      'instruksiKonsultan': 'Pekerjaan disetujui, pertahankan kerapian dan keselamatan kerja (SMK3).',
      'instruksiSaran': {
        'kontraktorUraian': '',
        'dinasUraian': '',
        'konsultanUraian': 'Pekerjaan disetujui, pertahankan kerapian dan keselamatan kerja (SMK3).',
      },

      // TTD
      'ttdNama': 'MUBALLIGH, ST., M.Sc.',
      'ttdJabatan': 'Inspektor Lapangan',
      'ttdSignature': '',

      'catatanPengawas': catatan,
      'temuan': pekerjaan.map((p) => '${p['jenis']} (${p['volume']})').join(', '),

      // Dokumen Tambahan Opsional
      'hasRekapitulasiAspal': hasRekapAspal,
      'hasRekapPerjalananDt': hasRekapAspal,
      'hasRekapSuhuLapangan': hasRekapAspal,
      'hasRekapSuhuAmp': hasRekapAspal,
      'hasRekapTonaseAspal': hasRekapAspal,
      'jenisMaterialAspal': hasRekapAspal ? 'Latasir Kelas B' : '',
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
                'jamSelesaiHampar': '09:20:00',
                'suhuAmp': '160',
                'suhuDatang': '152',
                'suhuHampar': '148',
                'suhuPadat': '135',
                'suhuAkhir': '95',
                'tonase': '11.5',
                'beratNetto': '11.5',
                'keterangan': 'Baik',
              },
              {
                'no': '2',
                'nomorPolisi': 'R 9234 BT',
                'jamBerangkat': '09:00:00',
                'jamTiba': '09:30:00',
                'waktuTempuh': '0.500',
                'kecepatan': '25.0',
                'jamMulaiHampar': '09:35:00',
                'waktuTunggu': '5',
                'jamSelesaiHampar': '10:05:00',
                'suhuAmp': '162',
                'suhuDatang': '155',
                'suhuHampar': '150',
                'suhuPadat': '138',
                'suhuAkhir': '98',
                'tonase': '11.0',
                'beratNetto': '11.0',
                'keterangan': 'Baik',
              },
            ]
          : [],

      'hasRekapBeton': hasRekapBeton,
      'hasRekapitulasiBeton': hasRekapBeton,
      'jenisBeton': hasRekapBeton ? "Fc' 15 MPa" : '',
      'penyediaJasaBeton': hasRekapBeton ? 'CV. DIVAN INSAN CEMERLANG' : '',
      'rekapPengecoranBetonList': hasRekapBeton
          ? [
              {
                'no': '1',
                'nomorKendaraan': 'R 9123 AB',
                'batchingPlant': 'PT. VARIA USAHA BETON',
                'jamBerangkat': '09:15:00',
                'jamDatang': '09:45:00',
                'slumpTest': '12 cm',
                'volume': '4.5',
                'volumeKumulatif': '4.5',
              },
            ]
          : [],
    };
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER: BUILD RKK MASTER DATA
  // ─────────────────────────────────────────────────────────────
  static List<Map<String, dynamic>> _buildSampleRkk(String namaRuas) {
    return [
      {
        'nomorRomawi': 'I',
        'namaDivisi': 'DIVISI 1 UMUM',
        'items': [
          {
            'no': '1',
            'uraian': 'Mobilisasi Alat & Personil',
            'satuan': 'Ls',
            'volumeCCO': 1.00,
            'nilaiBobot': 4.500,
          },
          {
            'no': '2',
            'uraian': 'Keselamatan dan Kesehatan Kerja (SMK3)',
            'satuan': 'Ls',
            'volumeCCO': 1.00,
            'nilaiBobot': 1.800,
          },
        ],
      },
      {
        'nomorRomawi': 'II',
        'namaDivisi': 'DIVISI 2. DRAINASE',
        'items': [
          {
            'no': '1',
            'uraian': 'Gorong2 Kotak Beton Bertulang Ukuran dalam 50x50cm',
            'satuan': 'm1',
            'volumeCCO': 5.00,
            'nilaiBobot': 4.200,
          },
          {
            'no': '2',
            'uraian': 'Saluran berbentuk U Tipe DS 2',
            'satuan': 'm1',
            'volumeCCO': 120.00,
            'nilaiBobot': 28.500,
          },
        ],
      },
      {
        'nomorRomawi': 'VI',
        'namaDivisi': 'DIVISI 6. PERKERASAN ASPAL',
        'items': [
          {
            'no': '1',
            'uraian': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
            'satuan': 'liter',
            'volumeCCO': 150.00,
            'nilaiBobot': 1.500,
          },
          {
            'no': '2',
            'uraian': 'Lapis Penetrasi Macadam',
            'satuan': 'm3',
            'volumeCCO': 35.00,
            'nilaiBobot': 26.000,
          },
          {
            'no': '3',
            'uraian': 'LATASIR KELAS B (1,5 cm)',
            'satuan': 'm2',
            'volumeCCO': 850.00,
            'nilaiBobot': 33.500,
          },
        ],
      },
    ];
  }

  // ─────────────────────────────────────────────────────────────
  // HELPER: BUILD WEEKLY REPORT
  // ─────────────────────────────────────────────────────────────
  static Map<String, dynamic> _buildWeeklyReport({
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
      'nomorKontrak': '000.3.3/1128/KONST/BM/X/2026',
      'tanggalKontrak': '20 Oktober 2026',
      'kontraktor': kontraktor,
      'tabelMingguan': [
        {
          'status': 'Normal',
          'mingguKe': 1,
          'tglMulai': '26/10/2026',
          'tglSelesai': '01/11/2026',
          'rencana': rencana,
          'realisasi': realisasi,
        },
        {
          'status': 'Normal',
          'mingguKe': 2,
          'tglMulai': '02/11/2026',
          'tglSelesai': '08/11/2026',
          'rencana': 7.50,
          'realisasi': 0.0,
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
}

