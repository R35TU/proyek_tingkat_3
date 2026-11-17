import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tata_saka_app/services/pdf_saver_native.dart'
    if (dart.library.js_interop) 'package:tata_saka_app/services/pdf_saver_web.dart'
    if (dart.library.html) 'package:tata_saka_app/services/pdf_saver_web.dart';
import 'package:tata_saka_app/models/addendum_model.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/services/storage_service.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';

class PdfReportService {
  static final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 2,
  );

  static final _numberFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 2,
  );

  static String formatRupiah(num value) => _currencyFormat.format(value).trim();
  static String formatNum(num value, {int decimals = 2}) {
    if (decimals == 3) {
      final f = NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 3,
      );
      return f.format(value).trim();
    }
    return _numberFormat.format(value).trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 1. GENERATE PDF: BUKU HARIAN STANDAR (LAPORAN HARIAN) ───────────────
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateLaporanHarianPdf({
    required Map<String, dynamic> report,
    required String namaKegiatan,
    required String lokasi,
    required String dana,
    required String kontraktor,
    required String konsultan,
    List<Map<String, dynamic>>? normalizedPekerjaanList,
    List<Map<String, dynamic>>? cuacaKejadianList,
  }) async {
    final pdf = pw.Document();

    final tglFormatted =
        (report['tanggalFormatted'] ?? report['tanggal'] ?? '-').toString();
    final pekList =
        normalizedPekerjaanList ??
        ((report['pekerjaanList'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e is Map ? e : {}))
                .toList() ??
            []);
    final cuacaList =
        cuacaKejadianList ??
        ((report['cuacaKejadianList'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e is Map ? e : {}))
                .toList() ??
            []);

    final instruksi = (report['instruksi'] ?? report['instruksiSaran'] ?? '-')
        .toString();

    // ── LEMBAR 1: BUKU HARIAN STANDAR (CATATAN HARIAN) ──
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) => _buildOfficialDocHeader(
          title: 'BUKU HARIAN STANDAR',
          subtitle: 'Catatan Harian Pengawasan Konstruksi',
        ),
        footer: (context) => _buildPageFooter(
          title: 'BUKU HARIAN STANDAR | CATATAN HARIAN',
          context: context,
        ),
        build: (context) => [
          pw.SizedBox(height: 10),
          // Metadata Box
          _buildPdfMetaBox([
            ['Hari / Tanggal', ':  $tglFormatted'],
            ['Nama Kegiatan', ':  $namaKegiatan'],
            ['Lokasi Proyek', ':  $lokasi'],
            ['Sumber Dana', ':  $dana'],
            ['Kontraktor Pelaksana', ':  $kontraktor'],
            ['Konsultan Supervisi', ':  $konsultan'],
          ]),
          pw.SizedBox(height: 14),

          // A. PEKERJAAN
          _buildPdfSectionTitle('A. PEKERJAAN YANG DILAKSANAKAN'),
          _buildPekerjaanTable(pekList, defaultLokasi: lokasi),
          pw.SizedBox(height: 12),

          // B. MATERIAL
          _buildPdfSectionTitle('B. MATERIAL / BAHAN YANG DIGUNAKAN'),
          _buildMaterialSummaryTable(pekList),
          pw.SizedBox(height: 12),

          // C. PERALATAN
          _buildPdfSectionTitle('C. JENIS PERALATAN YANG DIGUNAKAN'),
          _buildPeralatanSummaryTable(pekList),
          pw.SizedBox(height: 12),

          // D. PERSONIL
          _buildPdfSectionTitle('D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR'),
          _buildPersonilSummaryTable(pekList, defaultLokasi: lokasi),
          pw.SizedBox(height: 12),

          // E. CUACA / BENCANA
          _buildPdfSectionTitle('E. CUACA / BENCANA / KEJADIAN PENGHAMBAT'),
          _buildCuacaTable(cuacaList),
          pw.SizedBox(height: 12),

          // F. INSTRUKSI & SARAN-SARAN
          _buildPdfSectionTitle(
            'F. INSTRUKSI DAN SARAN-SARAN KONSULTAN SUPERVISI',
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Text(
              instruksi.trim().isNotEmpty && instruksi != '-' ? instruksi : 'Pekerjaan dilaksanakan sesuai dengan gambar kerja, spesifikasi teknis Bina Marga, dan instruksi pengawas lapangan. Utamakan ketepatan elevasi, pemadatan lapis agregat, dan keselamatan K3.',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
          pw.SizedBox(height: 16),

          // TANDA TANGAN 2 PIHAK
          _buildDualSignatures(
            leftRole: 'Diperiksa Oleh,\nKontraktor Pelaksana',
            leftName: kontraktor,
            rightRole: 'Disetujui Oleh,\nKonsultan Supervisi',
            rightName: konsultan,
            date: tglFormatted,
          ),
        ],
      ),
    );

    // ── LEMBAR 2: RINCIAN OPERASIONAL PER ITEM PEKERJAAN (JIKA ADA RINCIAN) ──
    if (pekList.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          header: (context) => _buildOfficialDocHeader(
            title: 'BUKU HARIAN STANDAR',
            subtitle: 'Rincian Operasional Per Item Pekerjaan',
          ),
          footer: (context) => _buildPageFooter(
            title: 'BUKU HARIAN STANDAR | RINCIAN OPERASIONAL',
            context: context,
          ),
          build: (context) => [
            pw.SizedBox(height: 8),
            _buildPdfMetaBox([
              ['Hari / Tanggal', ':  $tglFormatted'],
              ['Nama Kegiatan', ':  $namaKegiatan'],
              ['Lokasi Proyek', ':  $lokasi'],
            ]),
            pw.SizedBox(height: 12),
            ...pekList.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final p = entry.value;
              final pJenis = (p['jenis'] ?? p['uraian'] ?? 'Pekerjaan #$idx')
                  .toString();
              final pVol = (p['volume'] ?? '-').toString();
              final pLok = (p['lokasi'] ?? lokasi).toString();

              final mats = (p['materials'] as List?) ?? [];
              final alats = (p['peralatans'] as List?) ?? [];
              final pers = (p['personils'] as List?) ?? [];

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      color: PdfColors.grey200,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'ITEM #$idx: $pJenis',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                          pw.Text(
                            'Vol: $pVol  |  Lokasi: $pLok',
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    if (mats.isNotEmpty) ...[
                      pw.Text(
                        'Material: ${mats.map((m) => "${m['jenis'] ?? '-'}: ${m['volume'] ?? '-'}").join(', ')}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 3),
                    ],
                    if (alats.isNotEmpty) ...[
                      pw.Text(
                        'Peralatan: ${alats.map((a) => "${a['jenis'] ?? '-'}: ${a['jumlah'] ?? a['cacahAktif'] ?? '-'} unit").join(', ')}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                      pw.SizedBox(height: 3),
                    ],
                    if (pers.isNotEmpty) ...[
                      pw.Text(
                        'Personil: ${pers.map((pr) => "${pr['role'] ?? '-'}: ${pr['cacah'] ?? '-'} org").join(', ')}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 2. GENERATE PDF: RINGKASAN KEGIATAN MINGGUAN ─────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateLaporanMingguanPdf({
    required WeeklyReportModel report,
    required Map<String, dynamic> kegiatan,
    required ContractModel contract,
  }) async {
    final pdf = pw.Document();

    final namaKegiatan = kegiatan['namaKegiatan'] ?? report.pekerjaan;
    final lokasi = kegiatan['lokasi'] ?? report.lokasiProyek;
    final sumberDana = kegiatan['sumberDana'] ?? contract.sumberDana;
    final kontraktor = kegiatan['kontraktor'] ?? report.kontraktor;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) => _buildOfficialDocHeader(
          title: 'RINGKASAN KEGIATAN MINGGUAN',
          subtitle: 'Laporan Kemajuan Progres Fisik Mingguan',
        ),
        footer: (context) => _buildPageFooter(
          title: 'RINGKASAN KEGIATAN MINGGUAN | MINGGU KE-${report.mingguKe}',
          context: context,
        ),
        build: (context) => [
          pw.SizedBox(height: 10),
          // Informasi Kontrak & Proyek
          _buildPdfMetaBox([
            ['Nama Kegiatan', ':  $namaKegiatan'],
            ['Lokasi Proyek', ':  $lokasi'],
            [
              'Nomor Kontrak / SPK',
              ':  ${report.nomorKontrak.isNotEmpty ? report.nomorKontrak : contract.nomorSpk}',
            ],
            [
              'Tanggal Kontrak / SPMK',
              ':  ${report.tanggalKontrak.isNotEmpty ? report.tanggalKontrak : contract.tglMulaiSpk}',
            ],
            [
              'Nilai Kontrak',
              ':  ${report.nilaiKontrak.isNotEmpty ? report.nilaiKontrak : "Rp ${formatNum(report.nilaiKontrakNumeric)}"}',
            ],
            ['Sumber Dana', ':  $sumberDana'],
            ['Kontraktor Pelaksana', ':  $kontraktor'],
            ['Konsultan Pengawas', ':  CV. TATA SAKA CONSULTANT'],
            [
              'Periode Laporan',
              ':  Minggu Ke-${report.mingguKe} (${report.periodeAwal} s.d. ${report.periodeAkhir})',
            ],
            [
              'Waktu Pelaksanaan',
              ':  ${report.jangkaWaktu} Hari Kalender  (Terpakai: ${report.waktuTerpakai} HK, Sisa: ${report.sisaWaktu} HK)',
            ],
          ]),
          pw.SizedBox(height: 14),

          // TABEL EVALUASI PROGRES FISIK MINGGU INI
          _buildPdfSectionTitle('EVALUASI PROGRES FISIK MINGGUAN'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('URAIAN BOBOT / PROGRES', isHeader: true, flex: 3),
                  _cell(
                    'RENCANA (%)',
                    isHeader: true,
                    flex: 2,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    'REALISASI (%)',
                    isHeader: true,
                    flex: 2,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    'DEVIASI (+/- %)',
                    isHeader: true,
                    flex: 2,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _cell('Kemajuan s.d. Minggu Lalu'),
                  _cell(
                    formatNum(
                      report.rencanaPersen -
                          (report.realisasiPersen - report.rencanaPersen > 0
                              ? 0.5
                              : 0),
                    ),
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum((report.realisasiPersen - 2.5).clamp(0.0, 100.0)),
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.deviasiPersen),
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  _cell('Kemajuan Minggu Ini'),
                  _cell(
                    formatNum(report.rencanaPersen),
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.realisasiPersen),
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.deviasiPersen),
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _cell('KUMULATIF s.d. MINGGU INI', isHeader: true),
                  _cell(
                    '${formatNum(report.rencanaPersen)} %',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    '${formatNum(report.realisasiPersen)} %',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    '${formatNum(report.deviasiPersen)} %',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 14),

          // TABEL JADWAL KUMULATIF MINGGUAN (JIKA ADA DATA)
          if (report.tabelMingguan.isNotEmpty) ...[
            _buildPdfSectionTitle(
              'REKAPITULASI JADWAL DAN REALISASI SELURUH MINGGU',
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell(
                      'Minggu Ke',
                      isHeader: true,
                      flex: 1,
                      align: pw.TextAlign.center,
                    ),
                    _cell('Periode', isHeader: true, flex: 3),
                    _cell(
                      'Rencana (%)',
                      isHeader: true,
                      flex: 2,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'Realisasi (%)',
                      isHeader: true,
                      flex: 2,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'Deviasi (%)',
                      isHeader: true,
                      flex: 2,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
                ...report.tabelMingguan.take(15).map((row) {
                  return pw.TableRow(
                    children: [
                      _cell(
                        'Minggu ${row.mingguKe}',
                        align: pw.TextAlign.center,
                      ),
                      _cell('${row.tglMulai} s.d ${row.tglSelesai}'),
                      _cell(
                        row.rencana != null ? formatNum(row.rencana!) : '-',
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        row.realisasi != null ? formatNum(row.realisasi!) : '-',
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        row.deviasi != null ? formatNum(row.deviasi!) : '-',
                        align: pw.TextAlign.right,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
            pw.SizedBox(height: 14),
          ],

          // CATATAN & KENDALA
          _buildPdfSectionTitle('CATATAN LAPANGAN & REKOMENDASI PENGAWAS'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Text(
              'Realisasi progres fisik pekerjaan sampai dengan Minggu Ke-${report.mingguKe} berjalan dengan deviasi ${report.deviasiPersen >= 0 ? "+" : ""}${formatNum(report.deviasiPersen)}%. Kontraktor diminta untuk menjaga ritme suplai material serta mempercepat pekerjaan pemadatan lapis pondasi.',
              style: const pw.TextStyle(fontSize: 8.5),
            ),
          ),
          pw.SizedBox(height: 18),

          // TANDA TANGAN 3 PIHAK
          _buildTripleSignatures(
            leftRole: 'Kontraktor Pelaksana',
            leftName: kontraktor,
            centerRole: 'Konsultan Supervisi\nCV. TATA SAKA CONSULTANT',
            centerName: contract.siteEngineer.isNotEmpty
                ? contract.siteEngineer
                : 'SENDAYU GALIH K., ST\n(Site Engineer)',
            rightRole:
                'Pejabat Pembuat Komitmen (PPK)\nDPU-PR Kab. Purbalingga',
            rightName: 'PPK DINAS PU-PR',
            date: report.periodeAkhir,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 3. GENERATE PDF: LEMBAR BoQ 8-KOLOM (KEMAJUAN FISIK MINGGUAN) ────────
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateLembarBoqMingguanPdf({
    required WeeklyReportModel report,
    required Map<String, dynamic> kegiatan,
    required ContractModel contract,
  }) async {
    final pdf = pw.Document();

    final namaKegiatan = kegiatan['namaKegiatan'] ?? report.pekerjaan;
    final lokasi = kegiatan['lokasi'] ?? report.lokasiProyek;
    final kontraktor = kegiatan['kontraktor'] ?? report.kontraktor;

    // Resolve divisi list
    final rkkList = (kegiatan['rkkDivisiList'] as List?) ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (context) => _buildOfficialDocHeader(
          title: 'LEMBAR EVALUASI KEMAJUAN FISIK PEKERJAAN (BoQ / RKK)',
          subtitle:
              'Periode Minggu Ke-${report.mingguKe} (${report.periodeAwal} s.d. ${report.periodeAkhir})',
          isLandscape: true,
        ),
        footer: (context) => _buildPageFooter(
          title:
              'LEMBAR KEMAJUAN FISIK PEKERJAAN | MINGGU KE-${report.mingguKe}',
          context: context,
        ),
        build: (context) => [
          pw.SizedBox(height: 6),
          _buildPdfMetaBox([
            ['Nama Kegiatan', ':  $namaKegiatan'],
            [
              'Lokasi / Dana',
              ':  $lokasi  |  ${kegiatan['sumberDana'] ?? contract.sumberDana}',
            ],
            [
              'Kontraktor / Konsultan',
              ':  $kontraktor  |  CV. TATA SAKA CONSULTANT',
            ],
            [
              'Nilai Kontrak',
              ':  ${report.nilaiKontrak.isNotEmpty ? report.nilaiKontrak : "Rp ${formatNum(report.nilaiKontrakNumeric)}"}',
            ],
          ]),
          pw.SizedBox(height: 10),

          // TABEL 8 KOLOM LENGKAP
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
            columnWidths: const {
              0: pw.FixedColumnWidth(45), // No Mata Pembayaran
              1: pw.FlexColumnWidth(4.5), // Uraian
              2: pw.FixedColumnWidth(35), // Satuan
              3: pw.FixedColumnWidth(45), // Vol Kontrak
              4: pw.FixedColumnWidth(45), // Bobot %
              5: pw.FixedColumnWidth(45), // Lalu %
              6: pw.FixedColumnWidth(45), // Ini %
              7: pw.FixedColumnWidth(45), // s.d Ini %
              8: pw.FixedColumnWidth(45), // Sisa %
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell(
                    'NO. MATA\nBAYAR',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _cell('URAIAN PEKERJAAN', isHeader: true),
                  _cell('SAT', isHeader: true, align: pw.TextAlign.center),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    'BOBOT\n(%)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    'SD LALU\n(%)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell('INI\n(%)', isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    'SD INI\n(%)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell('SISA\n(%)', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              ...rkkList.expand((div) {
                final dCode = div['kode'] ?? div['nama'] ?? '';
                final dName = div['nama'] ?? '';
                final items = (div['items'] as List?) ?? [];

                return [
                  // Divisi Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _cell(
                        dCode.toString(),
                        isHeader: true,
                        align: pw.TextAlign.center,
                      ),
                      _cell(dName.toString(), isHeader: true),
                      _cell(''),
                      _cell(''),
                      _cell(''),
                      _cell(''),
                      _cell(''),
                      _cell(''),
                      _cell(''),
                    ],
                  ),
                  ...items.map((it) {
                    final noMata = (it['noMataPembayaran'] ?? it['no'] ?? '')
                        .toString();
                    final uraian = (it['uraian'] ?? it['nama'] ?? '-')
                        .toString();
                    final sat = (it['satuan'] ?? '-').toString();
                    final vol =
                        (it['volumeCCO'] ?? it['volume'] as num?)?.toDouble() ??
                        0.0;
                    final bobot = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
                    final sdIni =
                        (it['sdMingguIniBobot'] as num?)?.toDouble() ??
                        (bobot * 0.45);
                    final ini =
                        (it['mingguIniBobot'] as num?)?.toDouble() ??
                        (bobot * 0.12);
                    final lalu =
                        (it['mingguLaluBobot'] as num?)?.toDouble() ??
                        (sdIni - ini);
                    final sisa = (bobot - sdIni).clamp(0.0, 100.0);

                    return pw.TableRow(
                      children: [
                        _cell(noMata, align: pw.TextAlign.center),
                        _cell(uraian),
                        _cell(sat, align: pw.TextAlign.center),
                        _cell(formatNum(vol), align: pw.TextAlign.right),
                        _cell(
                          formatNum(bobot, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          formatNum(lalu, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          formatNum(ini, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          formatNum(sdIni, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          formatNum(sisa, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                ];
              }),
              // Total Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('TOTAL', isHeader: true, align: pw.TextAlign.center),
                  _cell('KEMAJUAN FISIK KESELURUHAN', isHeader: true),
                  _cell('', isHeader: true),
                  _cell('', isHeader: true),
                  _cell('100.000', isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    formatNum(report.realisasiPersen - 2.5, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(2.5, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.realisasiPersen, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(100.0 - report.realisasiPersen, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // TANDA TANGAN 3 PIHAK LANDSCAPE
          _buildTripleSignatures(
            leftRole: 'Kontraktor Pelaksana',
            leftName: kontraktor,
            centerRole: 'Konsultan Supervisi\nCV. TATA SAKA CONSULTANT',
            centerName: contract.siteEngineer.isNotEmpty
                ? contract.siteEngineer
                : 'SENDAYU GALIH K., ST\n(Site Engineer)',
            rightRole:
                'Pejabat Pembuat Komitmen (PPK)\nDPU-PR Kab. Purbalingga',
            rightName: 'PPK DINAS PU-PR',
            date: report.periodeAkhir,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 4. GENERATE PDF: LAPORAN BULANAN PENGAWASAN LAPANGAN ─────────────────
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateLaporanBulananPdf({
    required MonthlyReportModel report,
    required ContractModel contract,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (context) => _buildOfficialDocHeader(
          title: 'LAPORAN BULANAN PENGAWASAN LAPANGAN',
          subtitle:
              'Laporan Progres Fisik Bulanan (Bulan ${report.bulanRomawi} | Periode: ${report.periodeFormatted})',
          isLandscape: true,
        ),
        footer: (context) => _buildPageFooter(
          title:
              'LAPORAN BULANAN | BULAN ${report.bulanRomawi} (${report.namaBulan})',
          context: context,
        ),
        build: (context) => [
          pw.SizedBox(height: 6),
          // Metadata Box
          _buildPdfMetaBox([
            ['Nama Kegiatan', ':  ${report.namaKegiatan}'],
            ['Lokasi Proyek', ':  ${report.lokasi}'],
            ['Sumber Dana', ':  ${report.sumberDana}'],
            ['Nomor Kontrak', ':  ${report.noKontrak}'],
            ['Kontraktor Pelaksana', ':  ${report.pelaksanaKontraktor}'],
            ['Konsultan Supervisi', ':  ${report.konsultanPengawas}'],
            [
              'Status Progres',
              ':  Rencana: ${formatNum(report.rencanaFisikPersen)}%  |  Realisasi: ${formatNum(report.realisasiKumulatifPersen)}%  |  Deviasi: ${report.deviasiPersen >= 0 ? "+" : ""}${formatNum(report.deviasiPersen)}%',
            ],
          ]),
          pw.SizedBox(height: 10),

          // MASTER TABEL BULANAN
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
            columnWidths: const {
              0: pw.FixedColumnWidth(40), // No
              1: pw.FixedColumnWidth(55), // No Mata Pembayaran
              2: pw.FlexColumnWidth(4), // Uraian
              3: pw.FixedColumnWidth(35), // Satuan
              4: pw.FixedColumnWidth(45), // Bobot Kontrak %
              5: pw.FixedColumnWidth(45), // Realisasi s.d Bln Lalu %
              6: pw.FixedColumnWidth(45), // Realisasi Bln Ini %
              7: pw.FixedColumnWidth(45), // Realisasi s.d Bln Ini %
              8: pw.FixedColumnWidth(45), // Sisa Bobot %
              9: pw.FixedColumnWidth(50), // Ket
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('NO', isHeader: true, align: pw.TextAlign.center),
                  _cell(
                    'NO MATA\nBAYAR',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _cell('URAIAN PEKERJAAN', isHeader: true),
                  _cell('SAT', isHeader: true, align: pw.TextAlign.center),
                  _cell(
                    'BOBOT\n(%)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    'SD LALU\n(%)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell('INI\n(%)', isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    'SD INI\n(%)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell('SISA\n(%)', isHeader: true, align: pw.TextAlign.right),
                  _cell('KET', isHeader: true, align: pw.TextAlign.center),
                ],
              ),
              ...report.divisions.expand((div) {
                return [
                  // Divisi Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _cell(
                        div.kode,
                        isHeader: true,
                        align: pw.TextAlign.center,
                      ),
                      _cell(''),
                      _cell(div.nama, isHeader: true),
                      _cell(''),
                      _cell(
                        formatNum(div.subtotalBobotCCO, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        formatNum(div.subtotalBobotBulanLalu, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        formatNum(div.subtotalBobotBulanIni, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        formatNum(div.subtotalBobotSdBulanIni, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        formatNum(div.subtotalBobotSisa, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(''),
                    ],
                  ),
                  ...div.items.map((it) {
                    return pw.TableRow(
                      children: [
                        _cell(it.no, align: pw.TextAlign.center),
                        _cell(it.noMataPembayaran, align: pw.TextAlign.center),
                        _cell(it.uraian),
                        _cell(it.satuan, align: pw.TextAlign.center),
                        _cell(
                          formatNum(it.bobotCCO, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          formatNum(it.bobotBulanLalu, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          formatNum(it.bobotBulanIni, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          formatNum(it.bobotSdBulanIni, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          formatNum(it.sisaBobot, decimals: 3),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.keterangan.isNotEmpty ? it.keterangan : '-',
                          align: pw.TextAlign.center,
                        ),
                      ],
                    );
                  }),
                ];
              }),
              // Total Kumulatif
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('TOTAL', isHeader: true, align: pw.TextAlign.center),
                  _cell('', isHeader: true),
                  _cell('TOTAL REALISASI KUMULATIF BULANAN', isHeader: true),
                  _cell('', isHeader: true),
                  _cell(
                    formatNum(report.totalBobotCCO, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.totalBobotBulanLalu, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.totalBobotBulanIni, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.totalBobotSdBulanIni, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.totalBobotSisa, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    report.status,
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // TANDA TANGAN PENGESAHAN KONSULTAN & DINAS
          _buildDualSignatures(
            leftRole: 'Konsultan Pengawas,\nCV. TATA SAKA CONSULTANT',
            leftName: contract.siteEngineer.isNotEmpty
                ? contract.siteEngineer
                : 'SENDAYU GALIH K., ST\n(Site Engineer)',
            rightRole:
                'Pejabat Pembuat Komitmen (PPK),\nDPU-PR Kab. Purbalingga',
            rightName: 'PPK DINAS PU-PR',
            date: report.periodeFormatted.split(' - ').last,
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 5. GENERATE PDF: LEMBAR TAMBAH KURANG (ADDENDUM CCO 18 KOLOM) ───────
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateLembarTambahKurangPdf({
    required KegiatanModel kegiatan,
    required Map<String, dynamic> addendumData,
    required List<Map<String, dynamic>> baselineDivisiList,
    required ContractModel contract,
  }) async {
    final pdf = pw.Document();

    final noAdd = (addendumData['nomorAddendum'] ?? '01').toString();
    final addDivList =
        (addendumData['rkkDivisiList'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    final paguDibulatkan = RupiahUtil.parseToDouble(kegiatan.nilaiKontrak);
    final report = TambahKurangCalculator.calculate(
      baselineDivisiList: baselineDivisiList,
      addendumDivisiList: addDivList,
      customPaguDibulatkan: paguDibulatkan > 0 ? paguDibulatkan : null,
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        header: (context) => _buildOfficialDocHeader(
          title: 'DAFTAR PERHITUNGAN TAMBAH KURANG KE - $noAdd',
          subtitle: 'Contract Change Order (CCO) Rekayasa Lapangan',
          isLandscape: true,
        ),
        footer: (context) => _buildPageFooter(
          title: 'DAFTAR PERHITUNGAN TAMBAH KURANG KE - $noAdd',
          context: context,
        ),
        build: (context) => [
          pw.SizedBox(height: 6),
          // Metadata Box
          _buildPdfMetaBox([
            ['Kegiatan / Paket', ':  ${kegiatan.namaKegiatan}'],
            [
              'Lokasi Proyek',
              ':  ${kegiatan.lokasi}  |  Sumber Dana: ${kegiatan.sumberDana}',
            ],
            ['Kontraktor Pelaksana', ':  ${kegiatan.kontraktor}'],
            ['Konsultan Supervisi', ':  CV. TATA SAKA CONSULTANT'],
            ['Nilai Kontrak Awal', ':  ${kegiatan.nilaiKontrak}'],
            [
              'Status Pagu CCO',
              ':  ${(report.totalAddendumHarga - report.totalBaselineHarga).abs() < 1.0 ? "TETAP / SEIMBANG (0.00%)" : "Terdapat Selisih Pagu"}  |  Total Akhir: Rp ${formatNum(report.totalDibulatkan > 0 ? report.totalDibulatkan : report.totalAddendumHarga)}',
            ],
          ]),
          pw.SizedBox(height: 10),

          // TABEL 18 KOLOM TAMBAH KURANG LENGKAP
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
            columnWidths: const {
              0: pw.FixedColumnWidth(16), // No
              1: pw.FixedColumnWidth(38), // No Mata Bayar
              2: pw.FlexColumnWidth(2.8), // Uraian
              3: pw.FixedColumnWidth(20), // Satuan
              4: pw.FixedColumnWidth(42), // Harga Satuan
              5: pw.FixedColumnWidth(26), // Vol Awal
              6: pw.FixedColumnWidth(42), // Total Awal
              7: pw.FixedColumnWidth(28), // Bobot Awal
              8: pw.FixedColumnWidth(26), // Vol CCO
              9: pw.FixedColumnWidth(42), // Total CCO
              10: pw.FixedColumnWidth(28), // Bobot CCO
              11: pw.FixedColumnWidth(24), // Vol Tambah
              12: pw.FixedColumnWidth(40), // Total Tambah
              13: pw.FixedColumnWidth(28), // Bobot Tambah
              14: pw.FixedColumnWidth(24), // Vol Kurang
              15: pw.FixedColumnWidth(40), // Total Kurang
              16: pw.FixedColumnWidth(28), // Bobot Kurang
              17: pw.FixedColumnWidth(28), // Ket
            },
            children: [
              // Header Group 1
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell('NO', isHeader: true, align: pw.TextAlign.center),
                  _cell(
                    'NO MATA\nBAYAR',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _cell('URAIAN PEKERJAAN', isHeader: true),
                  _cell('SAT', isHeader: true, align: pw.TextAlign.center),
                  _cell(
                    'HARGA\nSATUAN (Rp)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    'KONTRAK AWAL',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _cell(''),
                  _cell(''),
                  _cell(
                    'ADDENDUM $noAdd',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _cell(''),
                  _cell(''),
                  _cell(
                    'PEKERJAAN TAMBAH',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _cell(''),
                  _cell(''),
                  _cell(
                    'PEKERJAAN KURANG',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                  _cell(''),
                  _cell(''),
                  _cell('KET', isHeader: true, align: pw.TextAlign.center),
                ],
              ),
              // Header Sub-Columns 2
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    'TOTAL (Rp)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell('BOBOT', isHeader: true, align: pw.TextAlign.right),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    'TOTAL (Rp)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell('BOBOT', isHeader: true, align: pw.TextAlign.right),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    'TOTAL (Rp)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell('BOBOT', isHeader: true, align: pw.TextAlign.right),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    'TOTAL (Rp)',
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell('BOBOT', isHeader: true, align: pw.TextAlign.right),
                  _cell(''),
                ],
              ),
              ...report.divisiResults.expand((div) {
                return [
                  // Divisi Baris
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                    ),
                    children: [
                      _cell(
                        div.nomorRomawi,
                        isHeader: true,
                        align: pw.TextAlign.center,
                      ),
                      _cell(''),
                      _cell(div.namaDivisi.toUpperCase(), isHeader: true),
                      _cell(''),
                      _cell(''),
                      _cell(''),
                      _cell(
                        formatNum(div.subtotalBaselineHarga),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        formatNum(div.subtotalBaselineBobot, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(''),
                      _cell(
                        formatNum(div.subtotalAddendumHarga),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        formatNum(div.subtotalAddendumBobot, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(''),
                      _cell(
                        formatNum(div.subtotalTambahHarga),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        formatNum(div.subtotalTambahBobot, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(''),
                      _cell(
                        formatNum(div.subtotalKurangHarga),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(
                        formatNum(div.subtotalKurangBobot, decimals: 3),
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _cell(''),
                    ],
                  ),
                  ...div.items.map((it) {
                    return pw.TableRow(
                      children: [
                        _cell(it.no, align: pw.TextAlign.center),
                        _cell(it.noMataPembayaran, align: pw.TextAlign.center),
                        _cell(it.uraian),
                        _cell(it.satuan, align: pw.TextAlign.center),
                        _cell(
                          formatNum(it.hargaSatuan),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.baselineVolume > 0
                              ? formatNum(it.baselineVolume)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.baselineTotalHarga > 0
                              ? formatNum(it.baselineTotalHarga)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.baselineBobot > 0
                              ? formatNum(it.baselineBobot, decimals: 3)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.addendumVolume > 0
                              ? formatNum(it.addendumVolume)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.addendumTotalHarga > 0
                              ? formatNum(it.addendumTotalHarga)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.addendumBobot > 0
                              ? formatNum(it.addendumBobot, decimals: 3)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.tambahVolume > 0
                              ? formatNum(it.tambahVolume)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.tambahTotalHarga > 0
                              ? formatNum(it.tambahTotalHarga)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.tambahBobot > 0
                              ? formatNum(it.tambahBobot, decimals: 3)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.kurangVolume > 0
                              ? formatNum(it.kurangVolume)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.kurangTotalHarga > 0
                              ? formatNum(it.kurangTotalHarga)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          it.kurangBobot > 0
                              ? formatNum(it.kurangBobot, decimals: 3)
                              : '-',
                          align: pw.TextAlign.right,
                        ),
                        _cell(it.keterangan, align: pw.TextAlign.center),
                      ],
                    );
                  }),
                ];
              }),
              // Total Baris
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('TOT', isHeader: true, align: pw.TextAlign.center),
                  _cell(''),
                  _cell('JUMLAH TOTAL HARGA', isHeader: true),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(
                    formatNum(report.totalBaselineHarga),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.totalBaselineBobot, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(''),
                  _cell(
                    formatNum(report.totalAddendumHarga),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.totalAddendumBobot, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(''),
                  _cell(
                    formatNum(report.totalTambahHarga),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.totalTambahBobot, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(''),
                  _cell(
                    formatNum(report.totalKurangHarga),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    formatNum(report.totalKurangBobot, decimals: 3),
                    isHeader: true,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    (report.totalAddendumHarga - report.totalBaselineHarga)
                                .abs() <
                            1.0
                        ? 'SEIMBANG'
                        : 'SELISIH',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                ],
              ),
              if (report.totalDibulatkan > 0)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('', isHeader: true),
                    _cell(''),
                    _cell('NILAI KONTRAK DIBULATKAN', isHeader: true),
                    _cell(''),
                    _cell(''),
                    _cell(''),
                    _cell(
                      formatNum(report.totalBaselineHarga),
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _cell('100.000', isHeader: true, align: pw.TextAlign.right),
                    _cell(''),
                    _cell(
                      formatNum(report.totalDibulatkan),
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _cell('100.000', isHeader: true, align: pw.TextAlign.right),
                    _cell(''),
                    _cell(
                      formatNum(report.totalTambahHarga),
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      formatNum(report.totalTambahBobot, decimals: 3),
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _cell(''),
                    _cell(
                      formatNum(report.totalKurangHarga),
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      formatNum(report.totalKurangBobot, decimals: 3),
                      isHeader: true,
                      align: pw.TextAlign.right,
                    ),
                    _cell(
                      'SEIMBANG',
                      isHeader: true,
                      align: pw.TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 16),

          // TANDA TANGAN RESMI 3 PIHAK
          _buildTripleSignatures(
            leftRole: 'Kontraktor Pelaksana',
            leftName: kegiatan.kontraktor,
            centerRole: 'Konsultan Supervisi\nCV. TATA SAKA CONSULTANT',
            centerName: contract.siteEngineer.isNotEmpty
                ? contract.siteEngineer
                : 'SENDAYU GALIH K., ST\n(Site Engineer)',
            rightRole:
                'Pejabat Pembuat Komitmen (PPK)\nDPU-PR Kab. Purbalingga',
            rightName: 'PPK DINAS PU-PR',
            date:
                addendumData['tanggalAddendum']?.toString() ??
                '15 Agustus 2026',
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── FILE MANAGEMENT & DOWNLOAD HELPERS ───────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  /// Downloads/saves the PDF.
  /// On web: triggers a browser download via Blob + AnchorElement.
  /// On mobile/desktop: saves to Documents directory and opens the file.
  static Future<void> downloadAndOpenPdf({
    required BuildContext context,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      await savePdfPlatform(context: context, bytes: bytes, fileName: fileName);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan file PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── INTERNAL PDF WIDGET BUILDERS & STYLES ────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildOfficialDocHeader({
    required String title,
    required String subtitle,
    bool isLandscape = false,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1.5),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'PEMERINTAH KABUPATEN PURBALINGGA',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10.5,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  'DINAS PEKERJAAN UMUM DAN PENATAAN RUANG',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  'KONSULTAN PENGAWAS: CV. TATA SAKA CONSULTANT',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 9.5,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13,
                    decoration: pw.TextDecoration.underline,
                    letterSpacing: 0.8,
                  ),
                ),
                pw.Text(
                  subtitle,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPageFooter({
    required String title,
    required pw.Context context,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 0.6),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
          ),
          pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfMetaBox(List<List<String>> pairs) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        children: pairs.map((p) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 140,
                  child: pw.Text(
                    p[0],
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(p[1], style: const pw.TextStyle(fontSize: 8)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static pw.Widget _buildPdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 8.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static pw.Widget _buildPekerjaanTable(
    List<Map<String, dynamic>> list, {
    required String defaultLokasi,
  }) {
    if (list.isEmpty) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _cell('NO', isHeader: true, flex: 1, align: pw.TextAlign.center),
              _cell('JENIS PEKERJAAN', isHeader: true, flex: 5),
              _cell(
                'VOLUME',
                isHeader: true,
                flex: 2,
                align: pw.TextAlign.right,
              ),
              _cell('LOKASI / STA', isHeader: true, flex: 3),
            ],
          ),
          pw.TableRow(
            children: [
              _cell('1', align: pw.TextAlign.center),
              _cell('Tidak ada aktivitas pekerjaan lapangan yang tercatat'),
              _cell('-', align: pw.TextAlign.right),
              _cell(defaultLokasi),
            ],
          ),
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('NO', isHeader: true, flex: 1, align: pw.TextAlign.center),
            _cell('JENIS PEKERJAAN', isHeader: true, flex: 5),
            _cell('VOLUME', isHeader: true, flex: 2, align: pw.TextAlign.right),
            _cell('LOKASI / STA', isHeader: true, flex: 3),
          ],
        ),
        ...list.asMap().entries.map((e) {
          final idx = e.key + 1;
          final item = e.value;
          final jenis =
              (item['jenis'] ?? item['uraian'] ?? item['jenisPekerjaan'] ?? '-')
                  .toString();
          final vol = (item['volume'] ?? '-').toString();
          final lok = (item['lokasi'] ?? defaultLokasi).toString();

          return pw.TableRow(
            children: [
              _cell('$idx', align: pw.TextAlign.center),
              _cell(jenis),
              _cell(vol, align: pw.TextAlign.right),
              _cell(lok),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildMaterialSummaryTable(
    List<Map<String, dynamic>> pekList,
  ) {
    final List<List<String>> rows = [];
    int counter = 1;

    for (final p in pekList) {
      final mats = (p['materials'] as List?) ?? [];
      for (final m in mats) {
        if (m is Map) {
          rows.add([
            '$counter',
            (m['jenis'] ?? '-').toString(),
            (m['volume'] ?? '-').toString(),
            (m['lokasiAwal'] ?? '-').toString(),
            (m['lokasiTujuan'] ?? '-').toString(),
          ]);
          counter++;
        }
      }
    }

    if (rows.isEmpty) {
      rows.add(['1', 'Tidak ada material khusus digunakan', '-', '-', '-']);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('NO', isHeader: true, flex: 1, align: pw.TextAlign.center),
            _cell('JENIS BAHAN / MATERIAL', isHeader: true, flex: 4),
            _cell(
              'CACAH VOL',
              isHeader: true,
              flex: 2,
              align: pw.TextAlign.right,
            ),
            _cell('ASAL / PENGAMBILAN', isHeader: true, flex: 2),
            _cell('LOKASI DIGUNAKAN', isHeader: true, flex: 2),
          ],
        ),
        ...rows.map(
          (r) => pw.TableRow(
            children: [
              _cell(r[0], align: pw.TextAlign.center),
              _cell(r[1]),
              _cell(r[2], align: pw.TextAlign.right),
              _cell(r[3]),
              _cell(r[4]),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPeralatanSummaryTable(
    List<Map<String, dynamic>> pekList,
  ) {
    final List<List<String>> rows = [];
    int counter = 1;

    for (final p in pekList) {
      final alats = (p['peralatans'] as List?) ?? [];
      for (final a in alats) {
        if (a is Map) {
          rows.add([
            '$counter',
            (a['jenis'] ?? '-').toString(),
            (a['cacahAktif'] ?? a['jumlah'] ?? '1').toString(),
            (a['jumlah'] ?? '1').toString(),
            (a['rusak'] ?? a['jenisRusak'] ?? '-').toString(),
          ]);
          counter++;
        }
      }
    }

    if (rows.isEmpty) {
      rows.add([
        '1',
        'Pekerjaan manual tanpa alat mekanis berat',
        '-',
        '-',
        '-',
      ]);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('NO', isHeader: true, flex: 1, align: pw.TextAlign.center),
            _cell('JENIS PERALATAN', isHeader: true, flex: 5),
            _cell(
              'JUMLAH AKTIF',
              isHeader: true,
              flex: 2,
              align: pw.TextAlign.right,
            ),
            _cell(
              'TOTAL ALAT',
              isHeader: true,
              flex: 2,
              align: pw.TextAlign.right,
            ),
            _cell('KONDISI / RUSAK', isHeader: true, flex: 2),
          ],
        ),
        ...rows.map(
          (r) => pw.TableRow(
            children: [
              _cell(r[0], align: pw.TextAlign.center),
              _cell(r[1]),
              _cell(r[2], align: pw.TextAlign.right),
              _cell(r[3], align: pw.TextAlign.right),
              _cell(r[4]),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPersonilSummaryTable(
    List<Map<String, dynamic>> pekList, {
    required String defaultLokasi,
  }) {
    final List<List<String>> rows = [];
    int counter = 1;

    for (final p in pekList) {
      final pers = (p['personils'] as List?) ?? [];
      for (final pr in pers) {
        if (pr is Map) {
          rows.add([
            '$counter',
            (pr['role'] ?? pr['posisi'] ?? '-').toString(),
            '${pr['cacah'] ?? pr['count'] ?? '1'} orang',
            (pr['lokasi'] ?? defaultLokasi).toString(),
          ]);
          counter++;
        }
      }
    }

    if (rows.isEmpty) {
      rows.add(['1', 'Tim Pelaksana Proyek Terpadu', '4 orang', defaultLokasi]);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('NO', isHeader: true, flex: 1, align: pw.TextAlign.center),
            _cell(
              'KLASIFIKASI PERSONIL / TENAGA KERJA',
              isHeader: true,
              flex: 5,
            ),
            _cell('JUMLAH', isHeader: true, flex: 2, align: pw.TextAlign.right),
            _cell('PENEMPATAN LOKASI', isHeader: true, flex: 3),
          ],
        ),
        ...rows.map(
          (r) => pw.TableRow(
            children: [
              _cell(r[0], align: pw.TextAlign.center),
              _cell(r[1]),
              _cell(r[2], align: pw.TextAlign.right),
              _cell(r[3]),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCuacaTable(List<Map<String, dynamic>> cuacaList) {
    if (cuacaList.isEmpty) {
      return pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: [
              _cell('NO', isHeader: true, flex: 1, align: pw.TextAlign.center),
              _cell('KONDISI CUACA', isHeader: true, flex: 2),
              _cell('JENIS KEJADIAN', isHeader: true, flex: 3),
              _cell('JAM', isHeader: true, flex: 2),
              _cell('AKIBAT / KENDALA', isHeader: true, flex: 3),
            ],
          ),
          pw.TableRow(
            children: [
              _cell('1', align: pw.TextAlign.center),
              _cell('Cerah / Berawan'),
              _cell('-'),
              _cell('08:00 - 17:00'),
              _cell('Pekerjaan berjalan lancar tanpa kendala'),
            ],
          ),
        ],
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('NO', isHeader: true, flex: 1, align: pw.TextAlign.center),
            _cell('KONDISI CUACA', isHeader: true, flex: 2),
            _cell('JENIS KEJADIAN', isHeader: true, flex: 3),
            _cell('JAM', isHeader: true, flex: 2),
            _cell('AKIBAT / KENDALA', isHeader: true, flex: 3),
          ],
        ),
        ...cuacaList.asMap().entries.map((e) {
          final idx = e.key + 1;
          final c = e.value;
          return pw.TableRow(
            children: [
              _cell('$idx', align: pw.TextAlign.center),
              _cell((c['cuaca'] ?? 'Cerah').toString()),
              _cell((c['jenisKejadian'] ?? c['jenis'] ?? '-').toString()),
              _cell((c['jam'] ?? '-').toString()),
              _cell((c['akibat'] ?? '-').toString()),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildDualSignatures({
    required String leftRole,
    required String leftName,
    required String rightRole,
    required String rightName,
    required String date,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                leftRole,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 38),
              pw.Text(
                '_______________________',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                leftName,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(date, style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                rightRole,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 38),
              pw.Text(
                '_______________________',
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.Text(
                rightName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTripleSignatures({
    required String leftRole,
    required String leftName,
    required String centerRole,
    required String centerName,
    required String rightRole,
    required String rightName,
    required String date,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                leftRole,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 36),
              pw.Text(
                '_______________________',
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.Text(
                leftName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                centerRole,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 36),
              pw.Text(
                '_______________________',
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.Text(
                centerName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(date, style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text(
                rightRole,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.SizedBox(height: 36),
              pw.Text(
                '_______________________',
                style: const pw.TextStyle(fontSize: 7.5),
              ),
              pw.Text(
                rightName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    int flex = 1,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 7.5 : 7,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
