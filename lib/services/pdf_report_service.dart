import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:tata_saka_app/models/addendum_model.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/services/pdf_saver_native.dart'
    if (dart.library.js_interop) 'package:tata_saka_app/services/pdf_saver_web.dart'
    if (dart.library.html) 'package:tata_saka_app/services/pdf_saver_web.dart';
import 'package:tata_saka_app/utils/execution_period_helper.dart';
import 'package:tata_saka_app/utils/plat_nomor_util.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';
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

  static String _fmtNum(num n, {int dec = 2}) {
    if (n == 0) return '-';
    return n.toStringAsFixed(dec);
  }

  static String _fmtVol(double vol) {
    if (vol == vol.toInt()) {
      return vol.toInt().toString();
    }
    return vol.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _fmtRupiahNoPrefix(double val, {bool forceDecimals = false}) {
    if (val == 0) return '-';
    final parts = val.toStringAsFixed(2).split('.');
    final intPart = num.tryParse(parts[0]) ?? 0;
    final formattedInt = RupiahUtil.formatNumber(intPart);
    final decPart = parts.length > 1 ? parts[1] : '00';
    if (forceDecimals || decPart != '00') {
      return '$formattedInt,$decPart';
    }
    return formattedInt;
  }

  static String _toRoman(int n) {
    const roman = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
      'XI',
      'XII',
      'XIII',
      'XIV',
      'XV',
    ];
    if (n >= 1 && n <= roman.length) {
      return roman[n - 1];
    }
    return '$n';
  }

  /// Asynchronously resolves image bytes from base64 string or HTTP URL
  static Future<Uint8List?> _resolveImageBytes(String? src) async {
    if (src == null || src.trim().isEmpty) return null;
    final str = src.trim();
    try {
      if (str.startsWith('http://') || str.startsWith('https://')) {
        final res = await http.get(Uri.parse(str)).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return res.bodyBytes;
        }
        return null;
      }
      String clean = str;
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      clean = clean.replaceAll(RegExp(r'\s+'), '');
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
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
    List<dynamic>? normalizedPekerjaanList,
    List<dynamic>? cuacaKejadianList,
  }) async {
    final pdf = pw.Document();

    final tglFormatted = (report['tanggalFormatted'] ?? report['tanggal'] ?? '-').toString();
    final pekList = normalizedPekerjaanList ??
        ((report['pekerjaanList'] as List?)?.map((e) => Map<String, dynamic>.from(e is Map ? e : {})).toList() ?? []);
    final cuacaList = cuacaKejadianList ??
        ((report['cuacaKejadianList'] as List?)?.map((e) => Map<String, dynamic>.from(e is Map ? e : {})).toList() ?? []);

    final instruksiKonsultan = report['instruksiKonsultan']?.toString() ??
        report['instruksi']?.toString() ??
        (report['instruksiSaran'] is Map ? report['instruksiSaran']['konsultanUraian']?.toString() : '') ??
        '';

    // Signers from report
    final ttdPengawasListRaw = report['ttdPengawasList'] as List<dynamic>?;
    final List<Map<String, String?>> signersRaw = [];
    if (ttdPengawasListRaw != null && ttdPengawasListRaw.isNotEmpty) {
      for (var t in ttdPengawasListRaw) {
        if (t is Map) {
          final n = t['nama']?.toString().trim() ?? '';
          final j = t['jabatan']?.toString().trim() ?? '';
          final s = t['signature']?.toString();
          if (n.isNotEmpty || j.isNotEmpty || (s != null && s.isNotEmpty)) {
            signersRaw.add({'nama': n, 'jabatan': j, 'signature': s});
          }
        }
      }
    }
    if (signersRaw.isEmpty) {
      final rawNama = report['ttdNama']?.toString().trim() ?? '';
      final rawJabatan = report['ttdJabatan']?.toString().trim() ?? '';
      final ttdSig = report['ttdSignature']?.toString().trim();
      if (rawNama.isNotEmpty ||
          rawJabatan.isNotEmpty ||
          (ttdSig != null && ttdSig.isNotEmpty)) {
        signersRaw.add({
          'nama': rawNama,
          'jabatan': rawJabatan,
          'signature': ttdSig,
        });
      }
    }

    // Resolve signatures asynchronously
    final List<Map<String, dynamic>> resolvedSigners = [];
    for (final s in signersRaw) {
      final sigStr = s['signature'];
      Uint8List? sigBytes;
      if (sigStr != null && sigStr.isNotEmpty) {
        sigBytes = await _resolveImageBytes(sigStr);
      }
      resolvedSigners.add({
        'nama': s['nama'] ?? '',
        'jabatan': s['jabatan'] ?? '',
        'bytes': sigBytes,
      });
    }

    // Resolve photos asynchronously
    final rawFotoList = (report['fotoList'] as List<dynamic>?) ?? [];
    final List<Uint8List> resolvedPhotos = [];
    for (final f in rawFotoList) {
      final bytes = await _resolveImageBytes(f?.toString());
      if (bytes != null) {
        resolvedPhotos.add(bytes);
      }
    }

    // Check attachment sheets
    final hasRekapSuhuLapangan = report['hasRekapSuhuLapangan'] == true &&
        (report['rekapSuhuLapanganList'] as List?)?.isNotEmpty == true;
    final rekapSuhuLapanganList = (report['rekapSuhuLapanganList'] as List<dynamic>?) ?? [];

    final hasRekapSuhuAmp = report['hasRekapSuhuAmp'] == true &&
        (report['rekapSuhuAmpList'] as List?)?.isNotEmpty == true;
    final rekapSuhuAmpList = (report['rekapSuhuAmpList'] as List<dynamic>?) ?? [];

    final hasRekapTonaseAspal = report['hasRekapTonaseAspal'] == true &&
        (report['rekapTonaseAspalList'] as List?)?.isNotEmpty == true;
    final rekapTonaseAspalList = (report['rekapTonaseAspalList'] as List<dynamic>?) ?? [];

    final hasRekapBeton = (report['hasRekapBeton'] == true || report['hasRekapitulasiBeton'] == true) &&
        (report['rekapPengecoranBetonList'] as List?)?.isNotEmpty == true;
    final rekapPengecoranBetonList = (report['rekapPengecoranBetonList'] as List<dynamic>?) ?? [];

    final bool hasDataPerjalananDt = (report['hasRekapPerjalananDt'] == true ||
            report['hasRekapitulasiAspal'] == true) ||
        (hasRekapSuhuLapangan && hasRekapSuhuAmp);

    int totalPages = 2;
    if (hasRekapSuhuLapangan) totalPages++;
    if (hasRekapSuhuAmp) totalPages++;
    if (hasRekapTonaseAspal) totalPages++;
    if (hasDataPerjalananDt) totalPages++;
    if (hasRekapBeton) totalPages++;

    int pageCounter = 2;
    final int suhuLapPage = hasRekapSuhuLapangan ? ++pageCounter : 0;
    final int suhuAmpPage = hasRekapSuhuAmp ? ++pageCounter : 0;
    final int tonasePage = hasRekapTonaseAspal ? ++pageCounter : 0;
    final int perjalananDtPage = hasDataPerjalananDt ? ++pageCounter : 0;
    final int betonPage = hasRekapBeton ? ++pageCounter : 0;

    // Build Table Rows for Lembar 1
    // 1. A. PEKERJAAN
    final List<List<String>> allJobRows = pekList.asMap().entries.map((entry) {
      final p = entry.value is Map ? (entry.value as Map) : <String, dynamic>{};
      final pJenis = p['jenis']?.toString() ?? '-';
      final pVol = p['volume']?.toString() ?? '-';
      final pLok = p['lokasi']?.toString() ?? lokasi;
      return [
        '${entry.key + 1}',
        pJenis.isNotEmpty ? pJenis : '-',
        pVol.isNotEmpty ? pVol : '-',
        pLok.isNotEmpty ? pLok : lokasi,
      ];
    }).toList();
    if (allJobRows.isEmpty) {
      allJobRows.add(['1', 'Tidak ada data pekerjaan', '-', lokasi]);
    }

    // 2. B. MATERIAL
    final List<List<String>> allMatRows = [];
    int mCount = 1;
    for (final p in pekList) {
      final mats = (p is Map ? p['materials'] : null) as List<dynamic>? ?? [];
      for (final m in mats) {
        if (m is Map) {
          allMatRows.add([
            '$mCount',
            m['jenis']?.toString() ?? '-',
            m['volume']?.toString() ?? '-',
            m['lokasiAwal']?.toString() ?? '-',
            m['lokasiTujuan']?.toString() ?? '-',
          ]);
          mCount++;
        }
      }
    }
    if (allMatRows.isEmpty) {
      allMatRows.add(['1', 'Nihil / Tanpa material', '-', '-', '-']);
    }

    // 3. C. JENIS PERALATAN YANG DIGUNAKAN (8 Columns)
    final List<List<String>> allAlatRows = [];
    int aCount = 1;
    for (final p in pekList) {
      final alats = (p is Map ? p['peralatans'] : null) as List<dynamic>? ?? [];
      for (final a in alats) {
        if (a is Map) {
          allAlatRows.add([
            '$aCount',
            a['jenis']?.toString() ?? '-',
            a['cacahAktif']?.toString() ?? a['jumlah']?.toString() ?? '-',
            a['jumlah']?.toString() ?? '-',
            a['noRusak']?.toString().isNotEmpty == true
                ? a['noRusak'].toString()
                : (a['jenisRusak']?.toString().isNotEmpty == true ? '$aCount' : '-'),
            a['jenisRusak']?.toString().isNotEmpty == true ? a['jenisRusak'].toString() : '-',
            a['kode']?.toString().isNotEmpty == true ? a['kode'].toString() : '-',
            a['rusak']?.toString().isNotEmpty == true ? a['rusak'].toString() : '-',
          ]);
          aCount++;
        }
      }
    }
    if (allAlatRows.isEmpty) {
      allAlatRows.add(['1', 'Pekerjaan manual / Nihil', '-', '-', '-', '-', '-', '-']);
    }

    // 4. D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR
    final List<List<String>> allPersRows = [];
    final Map<String, int> roleMap = {};
    final Map<String, String> roleLokMap = {};
    for (final p in pekList) {
      final pers = (p is Map ? p['personils'] : null) as List<dynamic>? ?? [];
      final pLok = (p is Map ? p['lokasi'] : null)?.toString() ?? lokasi;
      for (final pr in pers) {
        if (pr is Map) {
          final role = (pr['role'] ?? '-').toString().trim();
          final cnt = int.tryParse(pr['cacah']?.toString() ?? pr['count']?.toString() ?? '') ?? 1;
          roleMap[role] = (roleMap[role] ?? 0) + cnt;
          roleLokMap[role] = (pr['lokasi'] ?? pLok).toString();
        }
      }
    }
    if (roleMap.isNotEmpty) {
      int pCount = 1;
      roleMap.forEach((role, count) {
        allPersRows.add([
          '$pCount',
          role,
          '$count',
          roleLokMap[role] ?? lokasi,
        ]);
        pCount++;
      });
    } else {
      final defaultRoles = [
        'Pengawas DPU',
        'Konsultan Pengawas',
        'Pelaksana',
        'Logistik',
        'Kepala Tukang',
        'Tukang',
        'Pekerja',
      ];
      for (int i = 0; i < defaultRoles.length; i++) {
        allPersRows.add(['${i + 1}', defaultRoles[i], '-', lokasi]);
      }
    }

    // 5. E. CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN
    final List<List<String>> allCuacaRows = cuacaList.isNotEmpty
        ? cuacaList.asMap().entries.map((e) {
            final item = e.value is Map ? (e.value as Map) : <String, dynamic>{};
            final cuacaVal = item['cuaca']?.toString() ?? '-';
            final jk = item['jenisKejadian']?.toString() ?? item['jenis']?.toString() ?? '-';
            return [
              '${e.key + 1}',
              cuacaVal.isNotEmpty ? cuacaVal : '-',
              jk.isNotEmpty ? jk : '-',
              item['jam']?.toString() ?? '-',
              item['lokasi']?.toString() ?? '-',
              item['tanggungJawab']?.toString() ?? 'Tidak',
              item['akibat']?.toString() ?? '-',
            ];
          }).toList()
        : [
            ['1', 'Cerah', 'Nihil', '08:00 - 17:00', lokasi, 'Tidak', '-'],
          ];

    // ─────────────────────────────────────────────────────────────────────────
    // ── LEMBAR 1: BUKU HARIAN STANDAR (CATATAN HARIAN) ──────────────────────
    // ─────────────────────────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // KOP DOKUMEN RESMI
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'BUKU HARIAN STANDAR',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13.5,
                        decoration: pw.TextDecoration.underline,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Catatan Harian',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // INFORMASI IDENTITAS PROYEK
              _buildDocMetaRow('Hari / Tanggal', ':  $tglFormatted', fontSize: 8),
              _buildDocMetaRow('Nama Kegiatan', ':  $namaKegiatan', fontSize: 8),
              _buildDocMetaRow('Lokasi', ':  $lokasi', fontSize: 8),
              _buildDocMetaRow('Dana', ':  $dana', fontSize: 8),
              pw.SizedBox(height: 8),

              // 2-KOLOM LAYOUT (KIRI: A & D, KANAN: B, C, E)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // KOLOM KIRI (flex: 48)
                  pw.Expanded(
                    flex: 48,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildPdfDocSectionLabel('A.   PEKERJAAN'),
                        pw.SizedBox(height: 3),
                        _buildPdfDocTable(
                          colWidths: const {
                            0: pw.FixedColumnWidth(18),
                            1: pw.FlexColumnWidth(3.8),
                            2: pw.FlexColumnWidth(1.8),
                            3: pw.FlexColumnWidth(2.0),
                          },
                          headers: ['No', 'JENIS PEKERJAAN', 'VOLUME', 'LOKASI'],
                          rows: allJobRows,
                        ),
                        pw.SizedBox(height: 8),
                        _buildPdfDocSectionLabel('D.   PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR'),
                        pw.SizedBox(height: 3),
                        _buildPdfDocTable(
                          colWidths: const {
                            0: pw.FixedColumnWidth(18),
                            1: pw.FlexColumnWidth(3.8),
                            2: pw.FlexColumnWidth(1.6),
                            3: pw.FlexColumnWidth(2.0),
                          },
                          headers: ['No', 'Personil proyek', 'Cacah', 'Lokasi'],
                          rows: allPersRows,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 8),

                  // KOLOM KANAN (flex: 52)
                  pw.Expanded(
                    flex: 52,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _buildPdfDocSectionLabel('B.   MATERIAL'),
                        pw.SizedBox(height: 3),
                        _buildPdfDocTable(
                          colWidths: const {
                            0: pw.FixedColumnWidth(16),
                            1: pw.FlexColumnWidth(2.2),
                            2: pw.FlexColumnWidth(1.6),
                            3: pw.FlexColumnWidth(1.5),
                            4: pw.FlexColumnWidth(1.5),
                          },
                          headers: ['No', 'Jenis', 'Cacah Volume', 'Lokasi Awal', 'Lokasi Tujuan'],
                          rows: allMatRows,
                        ),
                        pw.SizedBox(height: 8),
                        _buildPdfDocSectionLabel('C.   JENIS PERALATAN YANG DIGUNAKAN'),
                        pw.SizedBox(height: 3),
                        _buildPdfDocTable(
                          colWidths: const {
                            0: pw.FixedColumnWidth(14),
                            1: pw.FlexColumnWidth(2.2),
                            2: pw.FlexColumnWidth(1.2),
                            3: pw.FlexColumnWidth(1.0),
                            4: pw.FixedColumnWidth(14),
                            5: pw.FlexColumnWidth(1.4),
                            6: pw.FlexColumnWidth(1.0),
                            7: pw.FlexColumnWidth(1.0),
                          },
                          headers: ['No', 'Jenis Peralatan', 'Cacah aktif', 'Jumlah', 'No', 'Jenis', 'Kode', 'Rusak'],
                          rows: allAlatRows,
                        ),
                        pw.SizedBox(height: 8),
                        _buildPdfDocSectionLabel('E.   CUACA/BENCANA/KEJADIAN PENGHAMBAT'),
                        pw.SizedBox(height: 3),
                        _buildPdfDocTable(
                          colWidths: const {
                            0: pw.FixedColumnWidth(16),
                            1: pw.FlexColumnWidth(1.8),
                            2: pw.FlexColumnWidth(2.0),
                            3: pw.FlexColumnWidth(1.4),
                            4: pw.FlexColumnWidth(1.4),
                            5: pw.FlexColumnWidth(1.8),
                            6: pw.FlexColumnWidth(1.8),
                          },
                          headers: ['No', 'Cuaca', 'Jenis Kejadian', 'Jam', 'Lokasi', 'Tanggung Jwb\nKontraktor', 'Akibat'],
                          rows: allCuacaRows,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // F. INSTRUKSI DAN SARAN-SARAN (LEMBAR 1 DENGAN TTD RESMI KONSULTAN)
              _buildPdfDocSectionLabel('F.   INSTRUKSI DAN SARAN-SARAN'),
              pw.SizedBox(height: 3),
              _buildPdfDocTableSectionF(
                konsultan: konsultan,
                instruksi: instruksiKonsultan,
                resolvedSigners: resolvedSigners,
              ),

              pw.Spacer(),

              // Footer Lembar 1
              pw.Divider(thickness: 0.6, color: PdfColors.black),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BUKU HARIAN STANDAR - CATATAN HARIAN', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                  pw.Text('Halaman 1 dari $totalPages', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // ── LEMBAR 2: RINCIAN OPERASIONAL PER ITEM PEKERJAAN ─────────────────────
    // ─────────────────────────────────────────────────────────────────────────
    final customFields = (report['customFields'] as List<dynamic>?) ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 6),
          child: pw.Column(
            children: [
              pw.Divider(thickness: 0.6, color: PdfColors.black),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('BUKU HARIAN STANDAR - RINCIAN OPERASIONAL', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                  pw.Text('Halaman 2 dari $totalPages', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                ],
              ),
            ],
          ),
        ),
        build: (context) => [
          // KOP DOKUMEN LEMBAR 2
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'BUKU HARIAN STANDAR',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 13.5,
                    decoration: pw.TextDecoration.underline,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Rincian Operasional Item Pekerjaan',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // INFORMASI IDENTITAS PROYEK
          _buildDocMetaRow('Hari / Tanggal', ':  $tglFormatted', fontSize: 8),
          _buildDocMetaRow('Nama Kegiatan', ':  $namaKegiatan', fontSize: 8),
          _buildDocMetaRow('Lokasi', ':  $lokasi', fontSize: 8),
          _buildDocMetaRow('Dana', ':  $dana', fontSize: 8),
          pw.SizedBox(height: 8),

          // SUB-BANNER RINCIAN OPERASIONAL
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFF1F5F9),
              border: pw.Border.all(color: PdfColors.black, width: 0.6),
            ),
            child: pw.Text(
              'RINCIAN OPERASIONAL PER ITEM PEKERJAAN',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
          ),
          pw.SizedBox(height: 8),

          // RINCIAN SETIAP ITEM PEKERJAAN
          ...pekList.asMap().entries.map((entry) {
            final index = entry.key;
            final p = entry.value is Map ? entry.value : {};
            final pIdx = index + 1;
            final pJenis = (p['jenis'] ?? p['uraian'] ?? 'Pekerjaan #$pIdx').toString();
            final pVolume = (p['volume'] ?? '-').toString();
            final pLokasi = (p['lokasi'] ?? lokasi).toString();

            final mats = (p['materials'] as List<dynamic>?) ?? [];
            final alats = (p['peralatans'] as List<dynamic>?) ?? [];
            final pers = (p['personils'] as List<dynamic>?) ?? [];

            final jobRows = [
              ['1', pJenis.isNotEmpty ? pJenis : '-', pVolume.isNotEmpty ? pVolume : '-', pLokasi.isNotEmpty ? pLokasi : lokasi],
            ];

            final matRows = mats.isNotEmpty
                ? mats.asMap().entries.map((mEntry) {
                    final m = mEntry.value is Map ? (mEntry.value as Map) : <String, dynamic>{};
                    return [
                      '${mEntry.key + 1}',
                      m['jenis']?.toString() ?? '-',
                      m['volume']?.toString() ?? '-',
                      m['lokasiAwal']?.toString() ?? '-',
                      m['lokasiTujuan']?.toString() ?? '-',
                    ];
                  }).toList()
                : [
                    ['1', 'Tidak ada penggunaan material pada pekerjaan ini', '-', '-', '-']
                  ];

            final alatRows = alats.isNotEmpty
                ? alats.asMap().entries.map((aEntry) {
                    final a = aEntry.value is Map ? (aEntry.value as Map) : <String, dynamic>{};
                    return [
                      '${aEntry.key + 1}',
                      a['jenis']?.toString() ?? '-',
                      a['cacahAktif']?.toString() ?? a['jumlah']?.toString() ?? '-',
                      a['jumlah']?.toString() ?? '-',
                      a['noRusak']?.toString().isNotEmpty == true
                          ? a['noRusak'].toString()
                          : (a['jenisRusak']?.toString().isNotEmpty == true ? '${aEntry.key + 1}' : '-'),
                      a['jenisRusak']?.toString().isNotEmpty == true ? a['jenisRusak'].toString() : '-',
                      a['kode']?.toString().isNotEmpty == true ? a['kode'].toString() : '-',
                      a['rusak']?.toString().isNotEmpty == true ? a['rusak'].toString() : '-',
                    ];
                  }).toList()
                : [
                    ['1', 'Pekerjaan manual / tanpa peralatan mekanis', '-', '-', '-', '-', '-', '-']
                  ];

            final persRows = pers.isNotEmpty
                ? pers.asMap().entries.map((prEntry) {
                    final pr = prEntry.value is Map ? (prEntry.value as Map) : <String, dynamic>{};
                    return [
                      '${prEntry.key + 1}',
                      pr['role']?.toString() ?? '-',
                      '${pr['cacah'] ?? pr['count'] ?? '-'}',
                      pr['lokasi']?.toString() ?? pLokasi,
                    ];
                  }).toList()
                : [
                    ['1', 'Personil proyek umum / terpadu', '-', pLokasi]
                  ];

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Partition Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE2E8F0)),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'ITEM #$pIdx: $pJenis',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
                        ),
                        pw.Text(
                          'Vol: $pVolume  |  Lokasi: $pLokasi',
                          style: const pw.TextStyle(fontSize: 7.5),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // A. PEKERJAAN
                  _buildPdfDocSectionLabel('A.   PEKERJAAN'),
                  pw.SizedBox(height: 2),
                  _buildPdfDocTable(
                    colWidths: const {
                      0: pw.FixedColumnWidth(20),
                      1: pw.FlexColumnWidth(4),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(2.5),
                    },
                    headers: ['No', 'JENIS PEKERJAAN', 'VOLUME', 'LOKASI'],
                    rows: jobRows,
                  ),
                  pw.SizedBox(height: 6),

                  // B. MATERIAL DIGUNAKAN
                  _buildPdfDocSectionLabel('B.   MATERIAL DIGUNAKAN'),
                  pw.SizedBox(height: 2),
                  _buildPdfDocTable(
                    colWidths: const {
                      0: pw.FixedColumnWidth(20),
                      1: pw.FlexColumnWidth(3),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(2),
                      4: pw.FlexColumnWidth(2),
                    },
                    headers: ['No', 'Jenis', 'Cacah Volume', 'Lokasi Awal', 'Lokasi Tujuan'],
                    rows: matRows,
                  ),
                  pw.SizedBox(height: 6),

                  // C. JENIS PERALATAN
                  _buildPdfDocSectionLabel('C.   JENIS PERALATAN YANG DIGUNAKAN'),
                  pw.SizedBox(height: 2),
                  _buildPdfDocTable(
                    colWidths: const {
                      0: pw.FixedColumnWidth(16),
                      1: pw.FlexColumnWidth(2.6),
                      2: pw.FlexColumnWidth(1.4),
                      3: pw.FlexColumnWidth(1.2),
                      4: pw.FixedColumnWidth(16),
                      5: pw.FlexColumnWidth(1.8),
                      6: pw.FlexColumnWidth(1.2),
                      7: pw.FlexColumnWidth(1.4),
                    },
                    headers: ['No', 'Jenis Peralatan', 'Cacah aktif', 'Jumlah', 'No', 'Jenis', 'Kode', 'Rusak'],
                    rows: alatRows,
                  ),
                  pw.SizedBox(height: 6),

                  // D. PERSONAL PROYEK
                  _buildPdfDocSectionLabel('D.   PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR'),
                  pw.SizedBox(height: 2),
                  _buildPdfDocTable(
                    colWidths: const {
                      0: pw.FixedColumnWidth(20),
                      1: pw.FlexColumnWidth(4),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(2.5),
                    },
                    headers: ['No', 'Personil proyek', 'Cacah', 'Lokasi'],
                    rows: persRows,
                  ),
                ],
              ),
            );
          }),

          // E. CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN
          pw.SizedBox(height: 4),
          _buildPdfDocSectionLabel('E.   CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN'),
          pw.SizedBox(height: 3),
          _buildPdfDocTable(
            colWidths: const {
              0: pw.FixedColumnWidth(20),
              1: pw.FlexColumnWidth(1.8),
              2: pw.FlexColumnWidth(2.2),
              3: pw.FlexColumnWidth(1.6),
              4: pw.FlexColumnWidth(1.6),
              5: pw.FlexColumnWidth(2.0),
              6: pw.FlexColumnWidth(2.2),
            },
            headers: ['No', 'Cuaca', 'Jenis Kejadian', 'Jam', 'Lokasi', 'Tanggung Jwb Kontraktor\n(Ya / Tidak)', 'Akibat'],
            rows: allCuacaRows,
          ),
          pw.SizedBox(height: 10),

          // F. INSTRUKSI DAN SARAN-SARAN (DENGAN TTD RESMI KONSULTAN SUPERVISI)
          _buildPdfDocSectionLabel('F.   INSTRUKSI DAN SARAN-SARAN'),
          pw.SizedBox(height: 3),
          _buildPdfDocTableSectionF(
            konsultan: konsultan,
            instruksi: instruksiKonsultan,
            resolvedSigners: resolvedSigners,
          ),
          pw.SizedBox(height: 10),

          // FIELD TAMBAHAN / CATATAN KHUSUS (Jika Ada)
          if (customFields.isNotEmpty) ...[
            _buildPdfDocSectionLabel('G.   FIELD TAMBAHAN / CATATAN KHUSUS'),
            pw.SizedBox(height: 3),
            _buildPdfDocTable(
              colWidths: const {
                0: pw.FixedColumnWidth(20),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(7),
              },
              headers: ['No', 'Nama Field', 'Keterangan / Uraian'],
              rows: customFields.asMap().entries.map((e) => [
                '${e.key + 1}',
                e.value['nama']?.toString() ?? '',
                e.value['isi']?.toString() ?? '',
              ]).toList(),
            ),
            pw.SizedBox(height: 10),
          ],

          // DOKUMENTASI FOTO LAPANGAN
          if (resolvedPhotos.isNotEmpty) ...[
            _buildPdfDocSectionLabel(customFields.isNotEmpty ? 'H.   DOKUMENTASI FOTO LAPANGAN' : 'G.   DOKUMENTASI FOTO LAPANGAN'),
            pw.SizedBox(height: 4),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: resolvedPhotos.asMap().entries.map((e) {
                return pw.Container(
                  width: 160,
                  height: 120,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Expanded(
                        child: pw.Image(pw.MemoryImage(e.value), fit: pw.BoxFit.cover),
                      ),
                      pw.Container(
                        color: const PdfColor.fromInt(0xFFE2E8F0),
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        width: double.infinity,
                        child: pw.Text(
                          'Foto #${e.key + 1}',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 10),
          ],
        ],
      ),
    );

    // ─────────────────────────────────────────────────────────────────────────
    // ── LEMBAR 3+: LAMPIRAN REKAPITULASI DOKUMEN ─────────────────────────────
    // ─────────────────────────────────────────────────────────────────────────

    // 1. REKAP WAKTU & SUHU LAPANGAN
    if (hasRekapSuhuLapangan) {
      final headers = [
        'No',
        'NOMOR\nKENDARAAN',
        'JAM DATANG\nKE LAPANGAN',
        'SUHU\nDATANG',
        'SUHU\nHAMPAR',
        'JAM MULAI TUANG\nKE FINISHER',
        'JAM SELESEI TUANG\nKE FINISHER',
        'SUHU PEMADATAN\nAKHIR',
        'JAM PULANG\nKE LAPANGAN',
      ];
      final tableRows = rekapSuhuLapanganList.asMap().entries.map((entry) {
        final item = entry.value as Map<String, dynamic>;
        final rawSuhuDatang = item['suhuDatang'];
        final rawSuhuHampar = item['suhuHampar'] ?? item['suhuLap'] ?? item['suhu'];
        final rawSuhuAkhir = item['suhuPemadatanAkhir'] ?? item['suhuAkhir'];

        String fmtSuhu(dynamic val) {
          if (val == null) return '-';
          final s = val.toString().trim();
          if (s.isEmpty || s == '-') return '-';
          return s.endsWith('°C') ? s : '$s°C';
        }

        return [
          '${entry.key + 1}',
          PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
          item['jamDatang']?.toString().isNotEmpty == true ? item['jamDatang'].toString() : '-',
          fmtSuhu(rawSuhuDatang),
          fmtSuhu(rawSuhuHampar),
          item['jamMulaiTuang']?.toString().isNotEmpty == true ? item['jamMulaiTuang'].toString() : '-',
          item['jamSelesaiTuang']?.toString().isNotEmpty == true ? item['jamSelesaiTuang'].toString() : '-',
          fmtSuhu(rawSuhuAkhir),
          item['jamPulang']?.toString().isNotEmpty == true ? item['jamPulang'].toString() : '-',
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'REKAPITULASI WAKTU TEMPUH DT & SUHU DI LAPANGAN',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
                _buildDocMetaRow('PENYEDIA JASA', ':  $kontraktor'),
                _buildDocMetaRow('KONSULTAN PENGAWAS', ':  ${konsultan.isNotEmpty ? konsultan : '-'}'),
                pw.SizedBox(height: 8),
                _buildPdfDocTable(
                  colWidths: const {
                    0: pw.FixedColumnWidth(18),
                    1: pw.FlexColumnWidth(2.3),
                    2: pw.FlexColumnWidth(1.8),
                    3: pw.FlexColumnWidth(1.6),
                    4: pw.FlexColumnWidth(1.6),
                    5: pw.FlexColumnWidth(1.9),
                    6: pw.FlexColumnWidth(1.9),
                    7: pw.FlexColumnWidth(1.8),
                    8: pw.FlexColumnWidth(1.8),
                  },
                  headers: headers,
                  rows: tableRows,
                ),
                pw.Spacer(),
                pw.Divider(thickness: 0.6, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('REKAPITULASI WAKTU TEMPUH DT & SUHU DI LAPANGAN', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text('Halaman $suhuLapPage dari $totalPages', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // 2. REKAP SUHU DI AMP
    if (hasRekapSuhuAmp) {
      final headers = [
        'No',
        'NOMOR KENDARAAN',
        'JAM PERGI / DARI AMP',
        'SUHU DI AMP',
        'JAM PULANG KE AMP',
      ];
      final tableRows = rekapSuhuAmpList.asMap().entries.map((entry) {
        final item = entry.value as Map<String, dynamic>;
        return [
          '${entry.key + 1}',
          PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
          item['jamPergi']?.toString() ?? '',
          item['suhuAmp']?.toString() ?? '',
          item['jamPulang']?.toString() ?? '',
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'REKAPITULASI WAKTU TEMPUH DT & SUHU DI AMP',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
                _buildDocMetaRow('PENYEDIA JASA', ':  $kontraktor'),
                _buildDocMetaRow('KONSULTAN PENGAWAS', ':  ${konsultan.isNotEmpty ? konsultan : '-'}'),
                pw.SizedBox(height: 8),
                _buildPdfDocTable(
                  colWidths: const {
                    0: pw.FixedColumnWidth(20),
                    1: pw.FlexColumnWidth(2.8),
                    2: pw.FlexColumnWidth(2.2),
                    3: pw.FlexColumnWidth(2.0),
                    4: pw.FlexColumnWidth(2.2),
                  },
                  headers: headers,
                  rows: tableRows,
                ),
                pw.Spacer(),
                pw.Divider(thickness: 0.6, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('REKAPITULASI WAKTU TEMPUH DT & SUHU DI AMP', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text('Halaman $suhuAmpPage dari $totalPages', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // 3. REKAP TONASE ASPAL
    if (hasRekapTonaseAspal) {
      final headers = [
        'No',
        'NOMOR KENDARAAN',
        'TONASE TIKET',
        'JUMLAH KUMULATIF',
      ];
      final tableRows = rekapTonaseAspalList.asMap().entries.map((entry) {
        final item = entry.value as Map<String, dynamic>;
        return [
          '${entry.key + 1}',
          PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
          item['tonaseTiket']?.toString() ?? '',
          item['jumlahKumulatif']?.toString() ?? '',
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'REKAPITULASI TONASE ASPAL',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
                _buildDocMetaRow('PENYEDIA JASA', ':  $kontraktor'),
                _buildDocMetaRow('KONSULTAN PENGAWAS', ':  ${konsultan.isNotEmpty ? konsultan : '-'}'),
                pw.SizedBox(height: 8),
                _buildPdfDocTable(
                  colWidths: const {
                    0: pw.FixedColumnWidth(24),
                    1: pw.FlexColumnWidth(3.5),
                    2: pw.FlexColumnWidth(2.5),
                    3: pw.FlexColumnWidth(2.5),
                  },
                  headers: headers,
                  rows: tableRows,
                ),
                pw.Spacer(),
                pw.Divider(thickness: 0.6, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('REKAPITULASI TONASE ASPAL', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text('Halaman $tonasePage dari $totalPages', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // 4. DATA PERJALANAN DUMP TRUCK (DT)
    if (hasDataPerjalananDt) {
      final jarakTempuhVal = report['jarakTempuh']?.toString() ?? '35.5';
      final double jarakKm = double.tryParse(jarakTempuhVal.replaceAll(',', '.')) ?? 35.5;

      final rawLapList = (report['rekapSuhuLapanganList'] as List<dynamic>?) ?? [];
      final rawDtList = (report['rekapPengirimanDtList'] as List<dynamic>?) ?? [];
      final lapanganList = rawLapList.isNotEmpty
          ? rawLapList.asMap().entries.map((e) {
              final m = Map<String, dynamic>.from(e.value as Map);
              if ((m['waktuAntrian'] == null || m['waktuAntrian'].toString().isEmpty) &&
                  e.key < rawDtList.length &&
                  rawDtList[e.key] is Map) {
                m['waktuAntrian'] = (rawDtList[e.key] as Map)['waktuAntrian'];
              }
              return m;
            }).toList()
          : (rawDtList.isNotEmpty
              ? rawDtList.map((m) => {
                  'nomorKendaraan': m['nomorKendaraan'],
                  'jamDatang': m['jamDatangLap'] ?? m['jamDatang'],
                  'suhuDatang': m['suhuDatang'],
                  'suhu': m['suhuLap'] ?? m['suhu'],
                  'suhuLap': m['suhuLap'] ?? m['suhu'],
                  'jamMulaiTuang': m['jamMulaiTuang'],
                  'jamSelesaiTuang': m['jamSelesaiTuang'],
                  'suhuPemadatanAkhir': m['suhuPemadatanAkhir'],
                  'jamPulang': m['jamPulangLap'] ?? m['jamPulang'],
                  'waktuAntrian': m['waktuAntrian'],
                }).toList()
              : []);

      final dtRows = PlatNomorUtil.computeDataPerjalananRows(
        lapanganList: lapanganList,
        ampList: (report['rekapSuhuAmpList'] as List<dynamic>?) ?? [],
        tonaseList: (report['rekapTonaseAspalList'] as List<dynamic>?) ?? [],
        jarakKm: jarakKm,
      );

      final headers = [
        'No',
        'HURUF',
        'ANGKA',
        'SERI',
        'BERANGKAT\nAMP',
        'SUHU\nAMP',
        'TIBA\nLAPANGAN',
        'SUHU\nTIBA',
        'MULAI\nHAMPAR',
        'SELESAI\nHAMPAR',
        'SUHU\nHAMPAR',
        'SUHU\nAKHIR',
        'KEMBALI\nAMP',
        'TIBA\nAMP',
        'TONASE\n(TON)',
        'JARAK\n(KM)',
      ];

      final tableRows = dtRows.asMap().entries.map((e) {
        final r = e.value;
        return [
          '${e.key + 1}',
          (r['hurufDepan'] ?? '').toString(),
          (r['angka'] ?? '').toString(),
          (r['hurufBelakang'] ?? '').toString(),
          (r['jamBerangkatAmp'] ?? '').toString(),
          (r['suhuAmp'] ?? '').toString(),
          (r['jamTibaLap'] ?? '').toString(),
          (r['suhuTibaLap'] ?? '').toString(),
          (r['jamMulaiHampar'] ?? '').toString(),
          (r['jamSelesaiHampar'] ?? '').toString(),
          (r['suhuHampar'] ?? '').toString(),
          (r['suhuAkhir'] ?? '').toString(),
          (r['jamKembaliAmp'] ?? '').toString(),
          (r['jamTibaAmp'] ?? '').toString(),
          (r['beratAc'] is num ? (r['beratAc'] as num).toStringAsFixed(2) : '-'),
          '$jarakKm',
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'DATA PERJALANAN DUMP TRUCK (DT)',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan', fontSize: 7.5),
                _buildDocMetaRow('KONTRAKTOR', ':  $kontraktor', fontSize: 7.5),
                pw.SizedBox(height: 6),
                _buildPdfDocTable(
                  colWidths: const {
                    0: pw.FixedColumnWidth(16),
                    1: pw.FixedColumnWidth(24),
                    2: pw.FixedColumnWidth(30),
                    3: pw.FixedColumnWidth(24),
                    4: pw.FlexColumnWidth(1.2),
                    5: pw.FlexColumnWidth(1.0),
                    6: pw.FlexColumnWidth(1.2),
                    7: pw.FlexColumnWidth(1.0),
                    8: pw.FlexColumnWidth(1.2),
                    9: pw.FlexColumnWidth(1.2),
                    10: pw.FlexColumnWidth(1.0),
                    11: pw.FlexColumnWidth(1.0),
                    12: pw.FlexColumnWidth(1.2),
                    13: pw.FlexColumnWidth(1.2),
                    14: pw.FlexColumnWidth(1.2),
                    15: pw.FlexColumnWidth(1.0),
                  },
                  headers: headers,
                  rows: tableRows,
                  headerFontSize: 6.0,
                  cellFontSize: 6.0,
                ),
                pw.Spacer(),
                pw.Divider(thickness: 0.6, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DATA PERJALANAN DUMP TRUCK', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text('Halaman $perjalananDtPage dari $totalPages', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // 5. REKAPITULASI PENGECORAN BETON READY MIX
    if (hasRekapBeton) {
      final headers = [
        'No',
        'NOMOR KENDARAAN\n(TRUCK MIXER)',
        'BATCHING PLANT\nREADY MIX',
        'JAM BERANGKAT\nDARI BP',
        'JAM DATANG\nDI LAPANGAN',
        'JAM BERANGKAT\nDARI LAPANGAN',
        'JAM TIBA DI\nBATCHING PLANT',
        'SLUMP TEST\n(CM)',
        'VOLUME\n(M³)',
      ];

      final tableRows = rekapPengecoranBetonList.asMap().entries.map((entry) {
        final item = entry.value as Map<String, dynamic>;
        final rawVol = item['volume']?.toString() ?? '-';
        final jamBerangkat = item['jamBerangkat']?.toString() ?? '';
        final jamDatang = item['jamDatang']?.toString() ?? '';
        final jamBerangkatLap = item['jamBerangkatLap']?.toString() ??
            item['jamBerangkatLapangan']?.toString() ??
            '';
        final jamTibaPlant = item['jamTibaPlant']?.toString() ??
            item['jamTibaBatchingPlant']?.toString() ??
            '';
        return [
          '${entry.key + 1}',
          PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
          item['batchingPlant']?.toString().isNotEmpty == true ? item['batchingPlant'].toString() : '-',
          jamBerangkat.isNotEmpty ? jamBerangkat : '-',
          jamDatang.isNotEmpty ? jamDatang : '-',
          jamBerangkatLap.isNotEmpty ? jamBerangkatLap : '-',
          jamTibaPlant.isNotEmpty ? jamTibaPlant : '-',
          item['slumpTest']?.toString() ?? '',
          rawVol.endsWith('m³') ? rawVol : '$rawVol m³',
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Center(
                  child: pw.Text(
                    'REKAPITULASI PENGECORAN BETON READY MIX',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      decoration: pw.TextDecoration.underline,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
                _buildDocMetaRow('PENYEDIA JASA', ':  $kontraktor'),
                _buildDocMetaRow('KONSULTAN PENGAWAS', ':  ${konsultan.isNotEmpty ? konsultan : '-'}'),
                pw.SizedBox(height: 8),
                _buildPdfDocTable(
                  colWidths: const {
                    0: pw.FixedColumnWidth(16),
                    1: pw.FlexColumnWidth(2.2),
                    2: pw.FlexColumnWidth(2.4),
                    3: pw.FlexColumnWidth(1.8),
                    4: pw.FlexColumnWidth(1.8),
                    5: pw.FlexColumnWidth(1.8),
                    6: pw.FlexColumnWidth(1.8),
                    7: pw.FlexColumnWidth(1.5),
                    8: pw.FlexColumnWidth(1.5),
                  },
                  headers: headers,
                  rows: tableRows,
                ),
                pw.Spacer(),
                pw.Divider(thickness: 0.6, color: PdfColors.black),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('REKAPITULASI PENGECORAN BETON READY MIX', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                    pw.Text('Halaman $betonPage dari $totalPages', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  ],
                ),
              ],
            );
          },
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

    const Color headerBgColorVal = Color(0xFFDCE6EE);
    final pdfHeaderBg = PdfColor.fromInt(headerBgColorVal.value);
    const Color yellowHighlightVal = Color(0xFFFFDE59);
    final pdfYellowHighlight = PdfColor.fromInt(yellowHighlightVal.value);

    // Resolve dynamic multi-signers asynchronously
    final List<Map<String, dynamic>> resolvedSigners = [];
    final rawSigners = report.ttdList;
    if (rawSigners != null && rawSigners.isNotEmpty) {
      for (final s in rawSigners) {
        final sigStr = s['signature']?.toString();
        Uint8List? sigBytes;
        if (sigStr != null && sigStr.isNotEmpty) {
          sigBytes = await _resolveImageBytes(sigStr);
        }
        resolvedSigners.add({
          'peran': s['peran'] ?? s['jabatan'] ?? '',
          'instansi': s['instansi'] ?? '',
          'nama': s['nama'] ?? '',
          'tanggal': s['tanggal'] ?? '',
          'bytes': sigBytes,
        });
      }
    } else {
      final kontraktorSig = await _resolveImageBytes(report.ttdKontraktorSignature);
      final konsultanSig = await _resolveImageBytes(report.ttdKonsultanSignature);
      final ppkSig = await _resolveImageBytes(report.ttdPpkSignature);

      resolvedSigners.addAll([
        {
          'peran': 'Kontraktor Pelaksana',
          'instansi': report.kontraktor,
          'nama': report.ttdKontraktorNama ?? '',
          'tanggal': report.ttdKontraktorTanggal ?? '',
          'bytes': kontraktorSig,
        },
        {
          'peran': 'Konsultan Supervisi',
          'instansi': (kegiatan['konsultanPengawas'] ?? '').toString(),
          'nama': report.ttdKonsultanNama ?? '',
          'tanggal': report.ttdKonsultanTanggal ?? '',
          'bytes': konsultanSig,
        },
        {
          'peran': 'Pejabat Pembuat Komitmen (PPK)',
          'instansi': contract.instansiDinas.isNotEmpty ? contract.instansiDinas.first : '',
          'nama': report.ttdPpkNama ?? '',
          'tanggal': report.ttdPpkTanggal ?? report.periodeAkhir,
          'bytes': ppkSig,
        },
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        footer: (context) => _buildPageFooter(
          title: 'RINGKASAN KEGIATAN MINGGUAN | MINGGU KE-${report.mingguKe}',
          context: context,
        ),
        build: (context) => [
          // JUDUL DOKUMEN RESMI
          pw.Center(
            child: pw.Text(
              'RINGKASAN KEGIATAN MINGGUAN',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ),
          pw.SizedBox(height: 12),

          // KOTAK INFORMASI KONTRAK & PROYEK (Persis LembarLaporanMingguanWidget)
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Column(
              children: [
                _buildInfoRowPdf('PEKERJAAN', report.pekerjaan.toUpperCase(), isBold: true),
                _buildDividerPdf(),
                _buildInfoRowPdf('LOKASI PROYEK', report.lokasiProyek.toUpperCase()),
                _buildDividerPdf(),
                _buildInfoRowPdf('KONTRAKTOR PELAKSANA', report.kontraktor.toUpperCase()),
                _buildDividerPdf(),
                _buildInfoRowWithSuffixPdf('JANGKA WAKTU KONTRAK', '${report.jangkaWaktu}', 'Hari Kalender'),
                _buildDividerPdf(),
                _buildInfoRowPdf('NOMOR KONTRAK', report.nomorKontrak),
                _buildDividerPdf(),
                _buildInfoRowPdf('TANGGAL KONTRAK', report.tanggalKontrak),
                _buildDividerPdf(),
                _buildInfoRowPdf(
                  'NILAI KONTRAK',
                  report.nilaiKontrak.startsWith('Rp') ? report.nilaiKontrak : 'Rp ${report.nilaiKontrak}',
                ),
                _buildDividerPdf(),
                _buildInfoRowPdf('TANGGAL SPMK', report.tanggalSpmk),
                _buildDividerPdf(),
                // SECTION LAPORAN MINGGU KE -
                pw.Container(
                  color: pdfHeaderBg,
                  child: _buildInfoRowTwoColsPdf(
                    'LAPORAN MINGGU KE -',
                    '${report.mingguKe}',
                    '',
                    '${report.totalMinggu}',
                    'dari',
                    isBoldVal: true,
                  ),
                ),
                _buildDividerPdf(),
                // PERIODE
                _buildInfoRowTwoColsPdf(
                  'PERIODE',
                  report.periodeAwal,
                  '',
                  report.periodeAkhir,
                  's/d',
                  isBoldVal: false,
                ),
                _buildDividerPdf(),
                // RENCANA FISIK
                _buildProgressSummaryRowPdf(
                  'RENCANA FISIK S/D MINGGU INI',
                  '${WeeklyReportModel.formatPercent(report.rencanaPersen, decimalDigits: 2, appendUnit: false)} %',
                  WeeklyReportModel.formatRupiah(report.rencanaNominal, withRp: false),
                  PdfColors.white,
                ),
                _buildDividerPdf(),
                // REALISASI FISIK
                _buildProgressSummaryRowPdf(
                  'REALISASI FISIK S/D MINGGU INI',
                  '${WeeklyReportModel.formatPercent(report.realisasiPersen, decimalDigits: 2, appendUnit: false)} %',
                  WeeklyReportModel.formatRupiah(report.realisasiNominal, withRp: false),
                  PdfColors.white,
                ),
                _buildDividerPdf(),
                // DEVIASI (+/-)
                _buildProgressSummaryRowPdf(
                  'DEVIASI (+/-)',
                  '${WeeklyReportModel.formatPercent(report.deviasiPersen, decimalDigits: 2, showSign: false, appendUnit: false)} %',
                  WeeklyReportModel.formatRupiah(report.deviasiNominal, withRp: false),
                  pdfYellowHighlight,
                  isBold: true,
                ),
                _buildDividerPdf(),
                _buildInfoRowWithSuffixPdf('WAKTU TERPAKAI', '${report.waktuTerpakai}', 'Hari Kalender'),
                _buildDividerPdf(),
                _buildInfoRowWithSuffixPdf('SISA WAKTU', '${report.sisaWaktu}', 'Hari Kalender'),
                _buildDividerPdf(),
                _buildInfoRowPdf('AKHIR MASA KONTRAK', report.akhirMasaKontrak),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          // TABEL BOBOT S/D MINGGU INI (TABEL BAWAH)
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
            columnWidths: const {
              0: pw.FixedColumnWidth(68),
              1: pw.FixedColumnWidth(48),
              2: pw.FlexColumnWidth(3.0),
              3: pw.FixedColumnWidth(68),
              4: pw.FixedColumnWidth(68),
              5: pw.FixedColumnWidth(68),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: pdfHeaderBg),
                children: [
                  _headerCellPdf('STATUS\nKONTRAK/\nADDENDUM'),
                  _headerCellPdf('MINGGU\nKE -'),
                  _headerCellPdf('PERIODE'),
                  _headerCellPdf('BOBOT S/D MINGGU INI\nRENCANA\n(%)'),
                  _headerCellPdf('BOBOT S/D MINGGU INI\nREALISASI\n(%)'),
                  _headerCellPdf('BOBOT S/D MINGGU INI\nDEVIASI\n(%)'),
                ],
              ),
              ...report.tabelMingguan.map((row) {
                final bool isCurrentWeek = row.mingguKe == report.mingguKe;
                final pdfColor = isCurrentWeek ? pdfYellowHighlight : PdfColors.white;
                final weight = isCurrentWeek ? pw.FontWeight.bold : pw.FontWeight.normal;

                final rencanaText = row.rencana != null
                    ? WeeklyReportModel.formatPercent(row.rencana, decimalDigits: 3, appendUnit: false)
                    : '';
                final realisasiText = row.realisasi != null
                    ? WeeklyReportModel.formatPercent(row.realisasi, decimalDigits: 3, appendUnit: false)
                    : '';
                final deviasiText = row.deviasi != null
                    ? WeeklyReportModel.formatPercent(row.deviasi, decimalDigits: 3, showSign: false, appendUnit: false)
                    : '';

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: pdfColor),
                  children: [
                    _dataCellPdf(row.status, align: pw.TextAlign.left, weight: weight),
                    _dataCellPdf('${row.mingguKe}', align: pw.TextAlign.center, weight: weight),
                    _dataCellPdf('${row.tglMulai}    -    ${row.tglSelesai}', align: pw.TextAlign.center, weight: weight),
                    _dataCellPdf(rencanaText, align: pw.TextAlign.right, weight: weight),
                    _dataCellPdf(realisasiText, align: pw.TextAlign.right, weight: weight),
                    _dataCellPdf(deviasiText, align: pw.TextAlign.right, weight: weight),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 16),

          // TANDA TANGAN DOKUMEN DIGITAL (BERDASARKAN INPUT PENGGUNA)
          _buildDynamicSignatures(signers: resolvedSigners),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 3. GENERATE PDF: LEMBAR BoQ 14-KOLOM (KEMAJUAN FISIK MINGGUAN) ───────
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateLembarBoqMingguanPdf({
    required WeeklyReportModel report,
    required Map<String, dynamic> kegiatan,
    required ContractModel contract,
  }) async {
    final pdf = pw.Document();

    final metadata = {
      'pekerjaan': report.pekerjaan.isNotEmpty ? report.pekerjaan : (kegiatan['namaKegiatan'] ?? '-'),
      'lokasi': report.lokasiProyek.isNotEmpty ? report.lokasiProyek : (kegiatan['lokasi'] ?? 'Kab. Purbalingga'),
      'sumberDana': (kegiatan['sumberDana'] ?? contract.sumberDana).toString(),
      'kontraktor': report.kontraktor.isNotEmpty ? report.kontraktor : (kegiatan['kontraktor'] ?? '-'),
      'noKontrak': report.nomorKontrak.isNotEmpty ? report.nomorKontrak : (kegiatan['noSuratPesanan'] ?? kegiatan['noSpmkKontraktor'] ?? '-'),
      'pengawas': (kegiatan['konsultanPengawas'] ?? '-').toString(),
      'noKontrakPengawasan': (kegiatan['noSpkKonsultan'] ?? kegiatan['noSpmkKonsultan'] ?? '-').toString(),
    };

    // Calculate divisi list accurately matching LembarBoqMingguanWidget
    final List<Map<String, dynamic>> resolvedSigners = [];
    final rawSigners = report.ttdList;
    if (rawSigners != null && rawSigners.isNotEmpty) {
      for (final s in rawSigners) {
        final sigStr = s['signature']?.toString();
        Uint8List? sigBytes;
        if (sigStr != null && sigStr.isNotEmpty) {
          sigBytes = await _resolveImageBytes(sigStr);
        }
        resolvedSigners.add({
          'peran': s['peran'] ?? s['jabatan'] ?? '',
          'instansi': s['instansi'] ?? '',
          'nama': s['nama'] ?? '',
          'tanggal': s['tanggal'] ?? '',
          'bytes': sigBytes,
        });
      }
    } else {
      final kontraktorSig = await _resolveImageBytes(report.ttdKontraktorSignature);
      final konsultanSig = await _resolveImageBytes(report.ttdKonsultanSignature);
      final ppkSig = await _resolveImageBytes(report.ttdPpkSignature);

      resolvedSigners.addAll([
        {
          'peran': 'Kontraktor Pelaksana',
          'instansi': metadata['kontraktor'] ?? report.kontraktor,
          'nama': report.ttdKontraktorNama ?? '',
          'tanggal': report.ttdKontraktorTanggal ?? '',
          'bytes': kontraktorSig,
        },
        {
          'peran': 'Konsultan Supervisi',
          'instansi': (kegiatan['konsultanPengawas'] ?? '').toString(),
          'nama': report.ttdKonsultanNama ?? '',
          'tanggal': report.ttdKonsultanTanggal ?? '',
          'bytes': konsultanSig,
        },
        {
          'peran': 'Pejabat Pembuat Komitmen (PPK)',
          'instansi': contract.instansiDinas.isNotEmpty ? contract.instansiDinas.first : '',
          'nama': report.ttdPpkNama ?? '',
          'tanggal': report.ttdPpkTanggal ?? report.periodeAkhir,
          'bytes': ppkSig,
        },
      ]);
    }

    final startDt = WeeklyReportModel.parseIndonesianDate(report.periodeAwal);
    final endDt = WeeklyReportModel.parseIndonesianDate(report.periodeAkhir);
    final period = ExecutionPeriodHelper.resolveExecutionPeriod(kegiatan, contract: contract);
    final boqRes = ProgressCalculator.calculateBoqProgress(
      kegMap: kegiatan,
      startDt: startDt,
      endDt: endDt,
      minStartDt: period.startDate,
    );
    List<Map<String, dynamic>> divisiList = boqRes.divisiList.isNotEmpty
        ? boqRes.divisiList
        : (report.boqProgressList ?? []);

    // Totals
    double totalNilaiBobot = 0.0;
    double totalMingguLaluBobot = 0.0;
    double totalMingguIniBobot = 0.0;
    double totalSdMingguIniBobot = 0.0;
    double totalSisaBobot = 0.0;

    for (final div in divisiList) {
      final items = div['items'] as List? ?? [];
      for (final item in items) {
        totalNilaiBobot += (item['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
        totalMingguLaluBobot += (item['mingguLaluBobot'] as num?)?.toDouble() ?? 0.0;
        totalMingguIniBobot += (item['mingguIniBobot'] as num?)?.toDouble() ?? 0.0;
        totalSdMingguIniBobot += (item['sdMingguIniBobot'] as num?)?.toDouble() ?? 0.0;
        totalSisaBobot += (item['sisaBobot'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final realisasiTotal = totalSdMingguIniBobot > 0 ? totalSdMingguIniBobot : report.realisasiPersen;
    final rencanaTotal = report.rencanaPersen;
    final deviasiTotal = realisasiTotal - rencanaTotal;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        footer: (context) => _buildPageFooter(
          title: 'LEMBAR KEMAJUAN FISIK PEKERJAAN (BoQ) | MINGGU KE-${report.mingguKe}',
          context: context,
        ),
        build: (context) => [
          // JUDUL RESMI
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'LAPORAN MINGGUAN',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 0.8),
                ),
                pw.Text(
                  'MINGGU ${_toRoman(report.mingguKe)}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '( PERIODE TANGGAL : ${report.periodeAwal.toUpperCase()} - ${report.periodeAkhir.toUpperCase()} )',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // KOTAK INFORMASI PROYEK (Persis LembarBoqMingguanWidget)
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildMetaRowSimplePdf('Pekerjaan', metadata['pekerjaan'] ?? '-'),
                      _buildMetaRowSimplePdf('Lokasi', metadata['lokasi'] ?? '-'),
                      _buildMetaRowSimplePdf('Sumber Dana', metadata['sumberDana'] ?? '-'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildMetaRowSimplePdf('Kontraktor', metadata['kontraktor'] ?? '-'),
                      _buildMetaRowSimplePdf('No. Kontrak', metadata['noKontrak'] ?? '-'),
                      _buildMetaRowSimplePdf('Pengawas', metadata['pengawas'] ?? '-'),
                      _buildMetaRowSimplePdf('No. Kontrak Pengawasan', metadata['noKontrakPengawasan'] ?? '-'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

          // TABEL 14 KOLOM BoQ
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
            columnWidths: const {
              0: pw.FixedColumnWidth(20),  // NO
              1: pw.FlexColumnWidth(3.5),  // URAIAN
              2: pw.FixedColumnWidth(28),  // Satuan
              3: pw.FixedColumnWidth(40),  // Vol Kontrak
              4: pw.FixedColumnWidth(38),  // Nilai Bobot
              5: pw.FixedColumnWidth(36),  // Mgg Lalu Vol
              6: pw.FixedColumnWidth(34),  // Mgg Lalu Bobot
              7: pw.FixedColumnWidth(36),  // Mgg Ini Vol
              8: pw.FixedColumnWidth(34),  // Mgg Ini Bobot
              9: pw.FixedColumnWidth(38),  // S/D Vol
              10: pw.FixedColumnWidth(34), // S/D Bobot
              11: pw.FixedColumnWidth(38), // Sisa Vol
              12: pw.FixedColumnWidth(34), // Sisa Bobot
              13: pw.FixedColumnWidth(24), // Ket
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: [
                  _cellBoqPdf('NO.', isHeader: true, align: pw.TextAlign.center),
                  _cellBoqPdf('URAIAN', isHeader: true),
                  _cellBoqPdf('Satuan', isHeader: true, align: pw.TextAlign.center),
                  _cellBoqPdf('Volume\nKontrak', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Nilai\nBobot\n%', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('MINGGU LALU\nVol', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('MINGGU LALU\n%', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('MINGGU INI\nVol', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('MINGGU INI\n%', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('S/D MINGGU INI\nVol', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('S/D MINGGU INI\n%', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Sisa Pekerjaan\nVol', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Sisa Pekerjaan\n%', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Ket.', isHeader: true, align: pw.TextAlign.center),
                ],
              ),
              // Body
              ...divisiList.expand((div) {
                final romawi = div['nomorRomawi']?.toString() ?? 'I';
                final namaDiv = div['namaDivisi']?.toString() ?? 'DIVISI';
                final items = div['items'] as List? ?? [];

                return [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                    children: [
                      _cellBoqPdf(romawi, isBold: true, align: pw.TextAlign.center),
                      _cellBoqPdf(namaDiv.toUpperCase(), isBold: true),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                    ],
                  ),
                  ...items.asMap().entries.map((itEntry) {
                    final idx = itEntry.key + 1;
                    final it = itEntry.value;

                    final uraian = (it['uraian'] ?? '').toString();
                    final satuan = (it['satuan'] ?? '').toString();
                    final volKontrak = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
                    final bbtKontrak = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;

                    final mlVol = (it['mingguLaluVolume'] as num?)?.toDouble() ?? 0.0;
                    final mlBbt = (it['mingguLaluBobot'] as num?)?.toDouble() ?? 0.0;
                    final miVol = (it['mingguIniVolume'] as num?)?.toDouble() ?? 0.0;
                    final miBbt = (it['mingguIniBobot'] as num?)?.toDouble() ?? 0.0;
                    final sdVol = (it['sdMingguIniVolume'] as num?)?.toDouble() ?? 0.0;
                    final sdBbt = (it['sdMingguIniBobot'] as num?)?.toDouble() ?? 0.0;
                    final ssVol = (it['sisaVolume'] as num?)?.toDouble() ?? 0.0;
                    final ssBbt = (it['sisaBobot'] as num?)?.toDouble() ?? 0.0;

                    return pw.TableRow(
                      children: [
                        _cellBoqPdf('$idx', align: pw.TextAlign.center),
                        _cellBoqPdf(uraian),
                        _cellBoqPdf(satuan, align: pw.TextAlign.center),
                        _cellBoqPdf(volKontrak > 0 ? _fmtNum(volKontrak) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(bbtKontrak > 0 ? _fmtNum(bbtKontrak, dec: 3) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(mlVol > 0 ? _fmtNum(mlVol) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(mlBbt > 0 ? _fmtNum(mlBbt, dec: 2) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(miVol > 0 ? _fmtNum(miVol) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(miBbt > 0 ? _fmtNum(miBbt, dec: 2) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(sdVol > 0 ? _fmtNum(sdVol) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(sdBbt > 0 ? _fmtNum(sdBbt, dec: 2) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(ssVol > 0 ? _fmtNum(ssVol) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(ssBbt > 0 ? _fmtNum(ssBbt, dec: 2) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf('-', align: pw.TextAlign.center),
                      ],
                    );
                  }),
                ];
              }),
              // Summary Total Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: [
                  _cellBoqPdf(''),
                  _cellBoqPdf('Jumlah', isBold: true, align: pw.TextAlign.center),
                  _cellBoqPdf(''),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(totalNilaiBobot, dec: 3), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(totalMingguLaluBobot, dec: 2), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(totalMingguIniBobot, dec: 2), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(totalSdMingguIniBobot, dec: 2), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(totalSisaBobot, dec: 2), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // SUMMARY KEMAJUAN (Rencana, Realisasi, Deviasi)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSummaryLinePdf('Rencana Fisik s/d Minggu ini', '${_fmtNum(rencanaTotal)} %'),
                pw.SizedBox(height: 2),
                _buildSummaryLinePdf('Realisasi Fisik s/d Minggu ini', '${_fmtNum(realisasiTotal)} %'),
                pw.SizedBox(height: 2),
                _buildSummaryLinePdf('Deviasi (+/-)', '${deviasiTotal >= 0 ? "+" : ""}${_fmtNum(deviasiTotal)} %', isBold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // TANDA TANGAN DOKUMEN DIGITAL (BERDASARKAN INPUT PENGGUNA)
          _buildDynamicSignatures(signers: resolvedSigners),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 4. GENERATE PDF: LAPORAN BULANAN (LEMBAR BoQ 15-KOLOM) ───────────────
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateLaporanBulananPdf({
    required MonthlyReportModel report,
    required ContractModel contract,
  }) async {
    final pdf = pw.Document();

    // Resolve dynamic multi-signers asynchronously
    final List<Map<String, dynamic>> resolvedSigners = [];
    final rawSigners = report.ttdList;
    if (rawSigners != null && rawSigners.isNotEmpty) {
      for (final s in rawSigners) {
        final sigStr = s['signature']?.toString();
        Uint8List? sigBytes;
        if (sigStr != null && sigStr.isNotEmpty) {
          sigBytes = await _resolveImageBytes(sigStr);
        }
        final peran = (s['peran'] ?? s['jabatan'] ?? '').toString().trim();
        final instansi = (s['instansi'] ?? '').toString().trim();
        final nama = (s['nama'] ?? '').toString().trim();
        final tanggal = (s['tanggal'] ?? '').toString().trim();
        if (peran.isNotEmpty ||
            instansi.isNotEmpty ||
            nama.isNotEmpty ||
            tanggal.isNotEmpty ||
            sigBytes != null) {
          resolvedSigners.add({
            'peran': peran,
            'instansi': instansi,
            'nama': nama,
            'tanggal': tanggal,
            'bytes': sigBytes,
          });
        }
      }
    } else {
      final kontraktorSig = await _resolveImageBytes(report.ttdKontraktorSignature);
      final konsultanSig = await _resolveImageBytes(report.ttdKonsultanSignature);
      final ppkSig = await _resolveImageBytes(report.ttdPpkSignature);

      final legacyGroups = [
        {
          'peran': (report.ttdKontraktorJabatan ?? '').trim(),
          'instansi': '',
          'nama': (report.ttdKontraktorNama ?? '').trim(),
          'tanggal': (report.ttdKontraktorTanggal ?? '').trim(),
          'bytes': kontraktorSig,
        },
        {
          'peran': (report.ttdKonsultanJabatan ?? '').trim(),
          'instansi': '',
          'nama': (report.ttdKonsultanNama ?? '').trim(),
          'tanggal': (report.ttdKonsultanTanggal ?? '').trim(),
          'bytes': konsultanSig,
        },
        {
          'peran': (report.ttdPpkJabatan ?? '').trim(),
          'instansi': '',
          'nama': (report.ttdPpkNama ?? '').trim(),
          'tanggal': (report.ttdPpkTanggal ?? '').trim(),
          'bytes': ppkSig,
        },
      ];
      for (final item in legacyGroups) {
        final peran = (item['peran'] ?? '').toString().trim();
        final nama = (item['nama'] ?? '').toString().trim();
        final tanggal = (item['tanggal'] ?? '').toString().trim();
        final bytes = item['bytes'] as Uint8List?;
        if (peran.isNotEmpty ||
            nama.isNotEmpty ||
            tanggal.isNotEmpty ||
            bytes != null) {
          resolvedSigners.add(item);
        }
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        footer: (context) => _buildPageFooter(
          title: 'LAPORAN BULANAN | BULAN ${report.bulanRomawi} (${report.namaBulan})',
          context: context,
        ),
        build: (context) => [
          // JUDUL RESMI
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'LAPORAN BULANAN',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 0.8),
                ),
                pw.Text(
                  'BULAN ${report.bulanRomawi}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '( PERIODE TANGGAL: ${report.periodeFormatted.toUpperCase()} )',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // KOTAK INFORMASI PROYEK (Persis LembarLaporanBulananWidget)
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildMetaRowSimplePdf('Pekerjaan', report.namaKegiatan),
                      _buildMetaRowSimplePdf('Lokasi', report.lokasi),
                      _buildMetaRowSimplePdf('Sumber Dana', report.sumberDana),
                      _buildMetaRowSimplePdf('Pelaksana Kontraktor', report.pelaksanaKontraktor),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildMetaRowSimplePdf('No Kontrak', report.noKontrak),
                      _buildMetaRowSimplePdf('Pengawas', report.konsultanPengawas),
                      _buildMetaRowSimplePdf('No Kontrak Pengawas', report.noKontrakPengawas),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

          // TABEL 15 KOLOM BoQ BULANAN
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
            columnWidths: const {
              0: pw.FixedColumnWidth(18),  // NO
              1: pw.FixedColumnWidth(44),  // No. Mata Pembayaran
              2: pw.FlexColumnWidth(3.5),  // Uraian
              3: pw.FixedColumnWidth(26),  // Satuan
              4: pw.FixedColumnWidth(38),  // Vol CCO
              5: pw.FixedColumnWidth(36),  // Nilai Bobot %
              6: pw.FixedColumnWidth(36),  // Bln Lalu Vol
              7: pw.FixedColumnWidth(34),  // Bln Lalu Bobot
              8: pw.FixedColumnWidth(36),  // Bln Ini Vol
              9: pw.FixedColumnWidth(34),  // Bln Ini Bobot
              10: pw.FixedColumnWidth(38), // S/D Bln Ini Vol
              11: pw.FixedColumnWidth(34), // S/D Bln Ini Bobot
              12: pw.FixedColumnWidth(38), // Sisa Vol
              13: pw.FixedColumnWidth(34), // Sisa Bobot
              14: pw.FixedColumnWidth(24), // Ket.
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                children: [
                  _cellBoqPdf('NO.', isHeader: true, align: pw.TextAlign.center),
                  _cellBoqPdf('No. Mata\nPembayaran', isHeader: true, align: pw.TextAlign.center),
                  _cellBoqPdf('Uraian', isHeader: true),
                  _cellBoqPdf('Satuan', isHeader: true, align: pw.TextAlign.center),
                  _cellBoqPdf('Volume\nCCO', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Nilai\nBobot %', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Bulan Lalu\nVol', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Bulan Lalu\nBobot', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Bulan Ini\nVol', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Bulan Ini\nBobot', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('S/D Bln Ini\nVol', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('S/D Bln Ini\nBobot', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Sisa\nVol', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Sisa\nBobot', isHeader: true, align: pw.TextAlign.right),
                  _cellBoqPdf('Ket.', isHeader: true, align: pw.TextAlign.center),
                ],
              ),
              ...report.divisions.expand((div) {
                return [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
                    children: [
                      _cellBoqPdf(div.kode, isBold: true, align: pw.TextAlign.center),
                      _cellBoqPdf(''),
                      _cellBoqPdf(div.nama, isBold: true),
                      _cellBoqPdf(''),
                      _cellBoqPdf(''),
                      _cellBoqPdf(_fmtNum(div.subtotalBobotCCO, dec: 3), isBold: true, align: pw.TextAlign.right),
                      _cellBoqPdf(''),
                      _cellBoqPdf(_fmtNum(div.subtotalBobotBulanLalu, dec: 3), isBold: true, align: pw.TextAlign.right),
                      _cellBoqPdf(''),
                      _cellBoqPdf(_fmtNum(div.subtotalBobotBulanIni, dec: 3), isBold: true, align: pw.TextAlign.right),
                      _cellBoqPdf(''),
                      _cellBoqPdf(_fmtNum(div.subtotalBobotSdBulanIni, dec: 3), isBold: true, align: pw.TextAlign.right),
                      _cellBoqPdf(''),
                      _cellBoqPdf(_fmtNum(div.subtotalBobotCCO - div.subtotalBobotSdBulanIni, dec: 3), isBold: true, align: pw.TextAlign.right),
                      _cellBoqPdf(''),
                    ],
                  ),
                  ...div.items.map((it) {
                    return pw.TableRow(
                      children: [
                        _cellBoqPdf(it.no, align: pw.TextAlign.center),
                        _cellBoqPdf(it.noMataPembayaran, align: pw.TextAlign.center),
                        _cellBoqPdf(it.uraian),
                        _cellBoqPdf(it.satuan, align: pw.TextAlign.center),
                        _cellBoqPdf(_fmtNum(it.volumeCCO), align: pw.TextAlign.right),
                        _cellBoqPdf(_fmtNum(it.bobotCCO, dec: 3), align: pw.TextAlign.right),
                        _cellBoqPdf(it.volumeBulanLalu > 0 ? _fmtNum(it.volumeBulanLalu) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(it.bobotBulanLalu > 0 ? _fmtNum(it.bobotBulanLalu, dec: 3) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(it.volumeBulanIni > 0 ? _fmtNum(it.volumeBulanIni) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(it.bobotBulanIni > 0 ? _fmtNum(it.bobotBulanIni, dec: 3) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(it.volumeSdBulanIni > 0 ? _fmtNum(it.volumeSdBulanIni) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(it.bobotSdBulanIni > 0 ? _fmtNum(it.bobotSdBulanIni, dec: 3) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(it.sisaVolume > 0 ? _fmtNum(it.sisaVolume) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(it.sisaBobot > 0 ? _fmtNum(it.sisaBobot, dec: 3) : '-', align: pw.TextAlign.right),
                        _cellBoqPdf(it.keterangan.isNotEmpty ? it.keterangan : '-', align: pw.TextAlign.center),
                      ],
                    );
                  }),
                ];
              }),
              // Total Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
                children: [
                  _cellBoqPdf(''),
                  _cellBoqPdf(''),
                  _cellBoqPdf('Jumlah Total', isBold: true),
                  _cellBoqPdf(''),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(report.totalBobotCCO, dec: 3), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(report.totalBobotBulanLalu, dec: 3), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(report.totalBobotBulanIni, dec: 3), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(report.totalBobotSdBulanIni, dec: 3), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                  _cellBoqPdf(_fmtNum(report.totalBobotSisa, dec: 3), isBold: true, align: pw.TextAlign.right),
                  _cellBoqPdf(''),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),

          // SUMMARY (Rencana, Realisasi, Deviasi)
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 30),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSummaryLinePdf('Rencana Fisik s/d Bulan ini', '${formatNum(report.rencanaFisikPersen)} %'),
                pw.SizedBox(height: 2),
                _buildSummaryLinePdf('Realisasi Fisik s/d Bulan ini', '${formatNum(report.realisasiKumulatifPersen)} %'),
                pw.SizedBox(height: 2),
                _buildSummaryLinePdf('Deviasi (+/-)', '${report.deviasiPersen >= 0 ? "+" : ""}${formatNum(report.deviasiPersen)} %', isBold: true),
              ],
            ),
          ),
          pw.SizedBox(height: 14),

          // TANDA TANGAN DOKUMEN DIGITAL (BERDASARKAN INPUT PENGGUNA)
          _buildDynamicSignatures(signers: resolvedSigners),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── 5. GENERATE PDF: DAFTAR PERHITUNGAN TAMBAH KURANG (18-KOLOM) ─────────
  // ═══════════════════════════════════════════════════════════════════════════
  static Future<Uint8List> generateLembarTambahKurangPdf({
    required KegiatanModel kegiatan,
    required Map<String, dynamic> addendumData,
    required List<Map<String, dynamic>> baselineDivisiList,
    required ContractModel contract,
  }) async {
    final pdf = pw.Document();

    final noAdd = (addendumData['nomorAddendum'] ?? '01').toString();
    final addDivList = (addendumData['rkkDivisiList'] as List?)
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
        margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        footer: (context) => _buildPageFooter(
          title: 'DAFTAR PERHITUNGAN TAMBAH KURANG KE - $noAdd',
          context: context,
        ),
        build: (context) => [
          // JUDUL DOKUMEN RESMI
          pw.Center(
            child: pw.Text(
              'DAFTAR PERHITUNGAN TAMBAH KURANG KE - $noAdd',
              style: pw.TextStyle(
                fontSize: 12.5,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
                letterSpacing: 0.8,
              ),
            ),
          ),
          pw.SizedBox(height: 10),

          // KOTAK METADATA PROYEK (Persis LembarTambahKurangWidget)
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildMetaRowSimplePdf('Kegiatan', kegiatan.namaKegiatan),
                      _buildMetaRowSimplePdf('Pekerjaan', kegiatan.namaKegiatan),
                      _buildMetaRowSimplePdf('Lokasi', kegiatan.lokasi.isNotEmpty ? kegiatan.lokasi : 'Kab. Purbalingga'),
                      _buildMetaRowSimplePdf('Sumber Dana', kegiatan.sumberDana.isNotEmpty ? kegiatan.sumberDana : 'APBD Kab. Purbalingga'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildMetaRowSimplePdf('Pelaksana Kontraktor', kegiatan.kontraktor.isNotEmpty ? kegiatan.kontraktor : '-'),
                      _buildMetaRowSimplePdf('No Kontrak', kegiatan.suratPesananFull.isNotEmpty ? kegiatan.suratPesananFull : '-'),
                      _buildMetaRowSimplePdf('Pengawas', kegiatan.konsultanPengawas.isNotEmpty ? kegiatan.konsultanPengawas : '-'),
                      _buildMetaRowSimplePdf('No Kontrak Pengawasan', kegiatan.spkKonsultanFull.isNotEmpty ? kegiatan.spkKonsultanFull : '-'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),

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
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: [
                  _cell('NO', isHeader: true, align: pw.TextAlign.center),
                  _cell('NO MATA\nBAYAR', isHeader: true, align: pw.TextAlign.center),
                  _cell('URAIAN PEKERJAAN', isHeader: true),
                  _cell('SAT', isHeader: true, align: pw.TextAlign.center),
                  _cell('HARGA\nSATUAN (Rp)', isHeader: true, align: pw.TextAlign.right),
                  _cell('KONTRAK AWAL', isHeader: true, align: pw.TextAlign.center),
                  _cell(''),
                  _cell(''),
                  _cell('ADDENDUM $noAdd', isHeader: true, align: pw.TextAlign.center),
                  _cell(''),
                  _cell(''),
                  _cell('PEKERJAAN TAMBAH', isHeader: true, align: pw.TextAlign.center),
                  _cell(''),
                  _cell(''),
                  _cell('PEKERJAAN KURANG', isHeader: true, align: pw.TextAlign.center),
                  _cell(''),
                  _cell(''),
                  _cell('KET', isHeader: true, align: pw.TextAlign.center),
                ],
              ),
              // Header Sub-Columns 2
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: [
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell('TOTAL (Rp)', isHeader: true, align: pw.TextAlign.right),
                  _cell('BOBOT', isHeader: true, align: pw.TextAlign.right),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell('TOTAL (Rp)', isHeader: true, align: pw.TextAlign.right),
                  _cell('BOBOT', isHeader: true, align: pw.TextAlign.right),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell('TOTAL (Rp)', isHeader: true, align: pw.TextAlign.right),
                  _cell('BOBOT', isHeader: true, align: pw.TextAlign.right),
                  _cell('VOL', isHeader: true, align: pw.TextAlign.right),
                  _cell('TOTAL (Rp)', isHeader: true, align: pw.TextAlign.right),
                  _cell('BOBOT', isHeader: true, align: pw.TextAlign.right),
                  _cell(''),
                ],
              ),
              ...report.divisiResults.expand((div) {
                return [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF8FAFC)),
                    children: [
                      _cell(div.nomorRomawi, isHeader: true, align: pw.TextAlign.center),
                      _cell(''),
                      _cell(div.namaDivisi.toUpperCase(), isHeader: true),
                      _cell(''),
                      _cell(''),
                      _cell(''),
                      _cell(_fmtRupiahNoPrefix(div.subtotalBaselineHarga), isHeader: true, align: pw.TextAlign.right),
                      _cell(formatNum(div.subtotalBaselineBobot, decimals: 3), isHeader: true, align: pw.TextAlign.right),
                      _cell(''),
                      _cell(_fmtRupiahNoPrefix(div.subtotalAddendumHarga), isHeader: true, align: pw.TextAlign.right),
                      _cell(formatNum(div.subtotalAddendumBobot, decimals: 3), isHeader: true, align: pw.TextAlign.right),
                      _cell(''),
                      _cell(div.subtotalTambahHarga > 0 ? _fmtRupiahNoPrefix(div.subtotalTambahHarga) : '-', isHeader: true, align: pw.TextAlign.right),
                      _cell(div.subtotalTambahBobot > 0 ? formatNum(div.subtotalTambahBobot, decimals: 3) : '-', isHeader: true, align: pw.TextAlign.right),
                      _cell(''),
                      _cell(div.subtotalKurangHarga > 0 ? _fmtRupiahNoPrefix(div.subtotalKurangHarga) : '-', isHeader: true, align: pw.TextAlign.right),
                      _cell(div.subtotalKurangBobot > 0 ? formatNum(div.subtotalKurangBobot, decimals: 3) : '-', isHeader: true, align: pw.TextAlign.right),
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
                        _cell(_fmtRupiahNoPrefix(it.hargaSatuan), align: pw.TextAlign.right),
                        _cell(_fmtVol(it.baselineVolume), align: pw.TextAlign.right),
                        _cell(_fmtRupiahNoPrefix(it.baselineTotalHarga), align: pw.TextAlign.right),
                        _cell(formatNum(it.baselineBobot, decimals: 3), align: pw.TextAlign.right),
                        _cell(_fmtVol(it.addendumVolume), align: pw.TextAlign.right),
                        _cell(_fmtRupiahNoPrefix(it.addendumTotalHarga), align: pw.TextAlign.right),
                        _cell(formatNum(it.addendumBobot, decimals: 3), align: pw.TextAlign.right),
                        _cell(it.tambahVolume > 0 ? _fmtVol(it.tambahVolume) : '-', align: pw.TextAlign.right),
                        _cell(it.tambahTotalHarga > 0 ? _fmtRupiahNoPrefix(it.tambahTotalHarga) : '-', align: pw.TextAlign.right),
                        _cell(it.tambahBobot > 0 ? formatNum(it.tambahBobot, decimals: 3) : '-', align: pw.TextAlign.right),
                        _cell(it.kurangVolume > 0 ? _fmtVol(it.kurangVolume) : '-', align: pw.TextAlign.right),
                        _cell(it.kurangTotalHarga > 0 ? _fmtRupiahNoPrefix(it.kurangTotalHarga) : '-', align: pw.TextAlign.right),
                        _cell(it.kurangBobot > 0 ? formatNum(it.kurangBobot, decimals: 3) : '-', align: pw.TextAlign.right),
                        _cell(it.keterangan.isNotEmpty ? it.keterangan : '-', align: pw.TextAlign.center),
                      ],
                    );
                  }),
                ];
              }),
              // Total Row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                children: [
                  _cell('', isHeader: true),
                  _cell(''),
                  _cell('Jumlah Total Harga Pekerjaan', isHeader: true),
                  _cell(''),
                  _cell(''),
                  _cell(''),
                  _cell(_fmtRupiahNoPrefix(report.totalBaselineHarga), isHeader: true, align: pw.TextAlign.right),
                  _cell('100.000', isHeader: true, align: pw.TextAlign.right),
                  _cell(''),
                  _cell(_fmtRupiahNoPrefix(report.totalAddendumHarga), isHeader: true, align: pw.TextAlign.right),
                  _cell('100.000', isHeader: true, align: pw.TextAlign.right),
                  _cell(''),
                  _cell(_fmtRupiahNoPrefix(report.totalTambahHarga), isHeader: true, align: pw.TextAlign.right),
                  _cell(formatNum(report.totalTambahBobot, decimals: 3), isHeader: true, align: pw.TextAlign.right),
                  _cell(''),
                  _cell(_fmtRupiahNoPrefix(report.totalKurangHarga), isHeader: true, align: pw.TextAlign.right),
                  _cell(formatNum(report.totalKurangBobot, decimals: 3), isHeader: true, align: pw.TextAlign.right),
                  _cell(
                    (report.totalAddendumHarga - report.totalBaselineHarga).abs() < 1.0 ? 'SEIMBANG' : 'SELISIH',
                    isHeader: true,
                    align: pw.TextAlign.center,
                  ),
                ],
              ),
              if (report.totalDibulatkan > 0)
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                  children: [
                    _cell('', isHeader: true),
                    _cell(''),
                    _cell('Jumlah Total Harga Pekerjaan ( Dibulatkan )', isHeader: true),
                    _cell(''),
                    _cell(''),
                    _cell(''),
                    _cell(_fmtRupiahNoPrefix(report.totalDibulatkan, forceDecimals: true), isHeader: true, align: pw.TextAlign.right),
                    _cell('100.000', isHeader: true, align: pw.TextAlign.right),
                    _cell(''),
                    _cell(_fmtRupiahNoPrefix(report.totalDibulatkan, forceDecimals: true), isHeader: true, align: pw.TextAlign.right),
                    _cell('100.000', isHeader: true, align: pw.TextAlign.right),
                    _cell(''),
                    _cell('', isHeader: true),
                    _cell('', isHeader: true),
                    _cell(''),
                    _cell('', isHeader: true),
                    _cell('', isHeader: true),
                    _cell('SEIMBANG', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 14),

          // TANDA TANGAN RESMI
          pw.Column(
            children: [
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 60),
                  child: pw.Text(
                    'Purbalingga, ${addendumData['tanggalAddendum']?.toString().isNotEmpty == true ? addendumData['tanggalAddendum'] : 'Agustus 2026'}',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 40),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          contract.instansiDinas.isNotEmpty
                              ? 'Kepala ${contract.instansiDinas.first}'
                              : 'Pejabat Penandatanganan Kontrak',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('Selaku Pejabat Penandatanganan Kontrak', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 40),
                        pw.Text(
                          kegiatan.penggunaAnggaran.isNotEmpty ? kegiatan.penggunaAnggaran : '( .................................... )',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                        ),
                        if (kegiatan.penggunaAnggaran.isNotEmpty)
                          pw.Text('NIP. -', style: const pw.TextStyle(fontSize: 7.5))
                        else
                          pw.SizedBox(height: 9),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 40),
                    child: pw.Column(
                      children: [
                        pw.Text('Kontraktor Pelaksana', style: const pw.TextStyle(fontSize: 8.5)),
                        pw.Text(
                          kegiatan.kontraktor.isNotEmpty ? kegiatan.kontraktor : '',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 40),
                        pw.Text(
                          kegiatan.direkturPenyedia.isNotEmpty ? kegiatan.direkturPenyedia : '( .................................... )',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                        ),
                        pw.Text('Direktur', style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── FILE MANAGEMENT & DOWNLOAD HELPERS ───────────────────────────────────
  // ═══════════════════════════════════════════════════════════════════════════

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

  static pw.Widget _buildDocMetaRow(String label, String value, {double labelWidth = 110, double fontSize = 7.5}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 0.8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: fontSize, color: PdfColors.black),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetaRowSimplePdf(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 7.5),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryLinePdf(String label, String value, {bool isBold = false}) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 180,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ),
        pw.Text(': ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfDocSectionLabel(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
    );
  }

  static pw.Widget _buildPdfDocTable({
    required Map<int, pw.TableColumnWidth> colWidths,
    required List<String> headers,
    required List<List<String>> rows,
    double headerFontSize = 6.0,
    double cellFontSize = 6.0,
    pw.EdgeInsets cellPadding = const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
  }) {
    return pw.Table(
      columnWidths: colWidths,
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.6),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE2E8F0)),
          children: headers.asMap().entries.map((e) {
            return pw.Padding(
              padding: cellPadding,
              child: pw.Text(
                e.value,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: headerFontSize,
                  color: PdfColors.black,
                ),
              ),
            );
          }).toList(),
        ),
        ...rows.map((row) {
          return pw.TableRow(
            children: row.asMap().entries.map((e) {
              final align = (e.key == 0) ? pw.TextAlign.center : pw.TextAlign.left;
              return pw.Padding(
                padding: cellPadding,
                child: pw.Text(
                  e.value,
                  textAlign: align,
                  style: pw.TextStyle(
                    fontSize: cellFontSize,
                    color: PdfColors.black,
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildPdfDocTableSectionF({
    required String konsultan,
    required String instruksi,
    required List<Map<String, dynamic>> resolvedSigners,
  }) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3.8),
        1: pw.FlexColumnWidth(5.8),
        2: pw.FlexColumnWidth(3.4),
      },
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE2E8F0)),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(3),
              child: pw.Text('', textAlign: pw.TextAlign.center),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(3),
              child: pw.Text(
                'Uraian dan Saran - Saran',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(3),
              child: pw.Text(
                'ttd',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5),
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Konsultan Supervisi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
                  pw.SizedBox(height: 2),
                  pw.Text(konsultan, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7)),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Text(
                instruksi.trim().isNotEmpty ? instruksi : '-',
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(3),
              child: pw.Column(
                children: resolvedSigners.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final nama = (s['nama'] ?? '').toString();
                  final jabatan = (s['jabatan'] ?? '').toString();
                  final bytes = s['bytes'] as Uint8List?;

                  return pw.Column(
                    children: [
                      if (idx > 0) ...[
                        pw.SizedBox(height: 3),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                        pw.SizedBox(height: 2),
                      ],
                      if (bytes != null)
                        pw.Container(
                          height: 28,
                          child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
                        )
                      else
                        pw.SizedBox(height: 20),
                      if (nama.isNotEmpty)
                        pw.Text(
                          nama,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 7,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      if (jabatan.isNotEmpty)
                        pw.Text(
                          jabatan,
                          textAlign: pw.TextAlign.center,
                          style: const pw.TextStyle(fontSize: 6.5),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRowPdf(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRowWithSuffixPdf(String label, String value, String suffix) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(
            width: 50,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 20),
          pw.Text(suffix, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRowTwoColsPdf(
    String label,
    String col1,
    String col1Prefix,
    String col2,
    String col2Prefix, {
    bool isBoldVal = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          if (col1Prefix.isNotEmpty) pw.Text('$col1Prefix ', style: const pw.TextStyle(fontSize: 7.5)),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              col1,
              style: pw.TextStyle(fontSize: 8, fontWeight: isBoldVal ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
          if (col2Prefix.isNotEmpty) pw.Text('$col2Prefix ', style: const pw.TextStyle(fontSize: 7.5)),
          pw.Expanded(
            child: pw.Text(
              col2,
              style: pw.TextStyle(fontSize: 8, fontWeight: isBoldVal ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProgressSummaryRowPdf(String label, String percentStr, String nominalStr, PdfColor bgColor, {bool isBold = false}) {
    return pw.Container(
      color: bgColor,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              percentStr,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
          pw.SizedBox(width: 30),
          pw.Expanded(
            child: pw.Text(
              nominalStr,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDividerPdf() {
    return pw.Divider(thickness: 0.6, color: PdfColors.black, height: 1);
  }

  static pw.Widget _headerCellPdf(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _dataCellPdf(String text, {pw.TextAlign align = pw.TextAlign.center, pw.FontWeight weight = pw.FontWeight.normal}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2.5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: weight),
      ),
    );
  }

  static pw.Widget _cellBoqPdf(String text, {bool isHeader = false, bool isBold = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 6.0,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildPageFooter({
    required String title,
    required pw.Context context,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.only(top: 2),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 0.6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
          pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDynamicSignatures({
    required List<Map<String, dynamic>> signers,
  }) {
    final activeSigners = signers.where((s) {
      final peran = (s['peran'] ?? s['jabatan'] ?? '').toString().trim();
      final instansi = (s['instansi'] ?? '').toString().trim();
      final nama = (s['nama'] ?? '').toString().trim();
      final tanggal = (s['tanggal'] ?? '').toString().trim();
      final bytes = s['bytes'] as Uint8List?;
      return peran.isNotEmpty ||
          instansi.isNotEmpty ||
          nama.isNotEmpty ||
          tanggal.isNotEmpty ||
          bytes != null;
    }).toList();

    if (activeSigners.isEmpty) {
      return pw.SizedBox(height: 16);
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: activeSigners.length == 1
            ? pw.MainAxisAlignment.center
            : pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: activeSigners.map((s) {
          final peran = (s['peran'] ?? s['jabatan'] ?? '').toString().trim();
          final instansi = (s['instansi'] ?? '').toString().trim();
          final nama = (s['nama'] ?? '').toString().trim();
          final tanggal = (s['tanggal'] ?? '').toString().trim();
          final bytes = s['bytes'] as Uint8List?;

          final List<String> headerLines = [];
          if (tanggal.isNotEmpty) headerLines.add(tanggal);
          if (peran.isNotEmpty) headerLines.add(peran);
          if (instansi.isNotEmpty) headerLines.add(instansi);

          return pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (headerLines.isNotEmpty)
                    pw.Text(
                      headerLines.join('\n'),
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  if (headerLines.isNotEmpty) pw.SizedBox(height: 4),
                  if (bytes != null)
                    pw.Container(
                      height: 34,
                      alignment: pw.Alignment.center,
                      child: pw.Image(
                        pw.MemoryImage(bytes),
                        fit: pw.BoxFit.contain,
                      ),
                    )
                  else
                    pw.SizedBox(height: 34),
                  if (bytes != null || nama.isNotEmpty)
                    pw.Text(
                      '_______________________',
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  if (nama.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      nama,
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
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
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(leftRole, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5)),
              pw.SizedBox(height: 32),
              pw.Text('_______________________', style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text(leftName, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(centerRole, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5)),
              pw.SizedBox(height: 32),
              pw.Text('_______________________', style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text(centerName, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(date, style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text(rightRole, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5)),
              pw.SizedBox(height: 32),
              pw.Text('_______________________', style: const pw.TextStyle(fontSize: 7.5)),
              pw.Text(rightName, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 6.5 : 6.0,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
