import 'package:flutter/material.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/utils/execution_period_helper.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';
import 'package:tata_saka_app/widgets/horizontal_drag_scroll_area.dart';

class LembarBoqMingguanWidget extends StatelessWidget {
  final WeeklyReportModel report;
  final Map<String, dynamic>? kegiatan;
  final VoidCallback? onDownloadPdf;

  const LembarBoqMingguanWidget({
    super.key,
    required this.report,
    this.kegiatan,
    this.onDownloadPdf,
  });

  static const Color headerBgColor = Color(0xFFF3F4F6);
  static const Color borderColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    final divisiList = _resolveDivisiList();
    final metadata = _resolveMetadata();

    // Sum totals
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

    return HorizontalDragScrollArea(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Container(
          width: 960,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onDownloadPdf != null) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onDownloadPdf,
                    icon: const Icon(Icons.picture_as_pdf, size: 14, color: Color(0xFF1E3A8A)),
                    label: const Text('Export PDF BoQ 8-Kolom', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // 1. JUDUL RESMI
              Center(
                child: Column(
                  children: [
                    const Text(
                      'LAPORAN MINGGUAN',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'MINGGU ${_toRoman(report.mingguKe)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '( PERIODE TANGGAL : ${report.periodeAwal.toUpperCase()} - ${report.periodeAkhir.toUpperCase()} )',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. KOTAK INFORMASI PROYEK
              _buildProjectInfoTable(metadata),
              const SizedBox(height: 14),

              // 3. TABEL 14 KOLOM BoQ (KEMAJUAN FISIK PEKERJAAN)
              _buildBoqTable(divisiList, totalNilaiBobot, totalMingguLaluBobot, totalMingguIniBobot, totalSdMingguIniBobot, totalSisaBobot),
              const SizedBox(height: 16),

              // 4. SUMMARY KEMAJUAN (Rencana, Realisasi, Deviasi)
              _buildProgressSummary(rencanaTotal, realisasiTotal, deviasiTotal),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _resolveMetadata() {
    final keg = kegiatan ?? {};
    return {
      'pekerjaan': report.pekerjaan.isNotEmpty ? report.pekerjaan : (keg['namaKegiatan'] ?? '-'),
      'lokasi': report.lokasiProyek.isNotEmpty ? report.lokasiProyek : (keg['lokasi'] ?? 'Kab. Purbalingga'),
      'sumberDana': (keg['sumberDana'] ?? 'APBD Kab. Purbalingga').toString(),
      'kontraktor': report.kontraktor.isNotEmpty ? report.kontraktor : (keg['kontraktor'] ?? '-'),
      'noKontrak': report.nomorKontrak.isNotEmpty ? report.nomorKontrak : (keg['noSuratPesanan'] ?? keg['noSpmkKontraktor'] ?? '-'),
      'pengawas': (keg['konsultanPengawas'] ?? '-').toString(),
      'noKontrakPengawasan': (keg['noSpkKonsultan'] ?? keg['noSpmkKonsultan'] ?? '-').toString(),
      'tanggalLaporan': report.periodeAkhir.isNotEmpty ? report.periodeAkhir : report.tanggalKontrak,
    };
  }

  List<Map<String, dynamic>> _resolveDivisiList() {
    if (kegiatan != null) {
      final startDt = WeeklyReportModel.parseIndonesianDate(report.periodeAwal);
      final endDt = WeeklyReportModel.parseIndonesianDate(report.periodeAkhir);
      final minStart = ExecutionPeriodHelper.resolveExecutionPeriod(kegiatan).startDate;
      final boqRes = ProgressCalculator.calculateBoqProgress(
        kegMap: kegiatan!,
        startDt: startDt,
        endDt: endDt,
        minStartDt: minStart,
      );
      if (boqRes.divisiList.isNotEmpty) {
        return boqRes.divisiList;
      }
    }

    if (report.boqProgressList != null && report.boqProgressList!.isNotEmpty) {
      return report.boqProgressList!;
    }

    return [];
  }

  Widget _buildProjectInfoTable(Map<String, String> meta) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        children: [
          _buildMetaRow('Pekerjaan', ':  ${meta['pekerjaan']}'),
          _buildMetaRow('Lokasi', ':  ${meta['lokasi']}'),
          _buildMetaRow('Sumber Dana', ':  ${meta['sumberDana']}'),
          _buildMetaRow('Pelaksana Kontraktor', ':  ${meta['kontraktor']}'),
          _buildMetaRow('No Kontrak', ':  ${meta['noKontrak']}'),
          _buildMetaRow('Pengawas', ':  ${meta['pengawas']}'),
          _buildMetaRow('No Kontrak Pengawasan', ':  ${meta['noKontrakPengawasan']}'),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10.5, color: Colors.black, height: 1.25),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoqTable(
    List<Map<String, dynamic>> divisiList,
    double totalNilaiBobot,
    double totalMingguLaluBobot,
    double totalMingguIniBobot,
    double totalSdMingguIniBobot,
    double totalSisaBobot,
  ) {
    return Table(
      border: TableBorder.all(color: borderColor, width: 0.8),
      columnWidths: const {
        0: FixedColumnWidth(36),  // NO
        1: FlexColumnWidth(3.5),  // URAIAN
        2: FixedColumnWidth(48),  // Satuan
        3: FixedColumnWidth(64),  // Vol Kontrak
        4: FixedColumnWidth(58),  // Nilai Bobot
        5: FixedColumnWidth(54),  // Mgg Lalu Vol
        6: FixedColumnWidth(52),  // Mgg Lalu Bobot
        7: FixedColumnWidth(54),  // Mgg Ini Vol
        8: FixedColumnWidth(52),  // Mgg Ini Bobot
        9: FixedColumnWidth(56),  // S/D Vol
        10: FixedColumnWidth(52), // S/D Bobot
        11: FixedColumnWidth(56), // Sisa Vol
        12: FixedColumnWidth(52), // Sisa Bobot
        13: FixedColumnWidth(38), // Ket
      },
      children: [
        // Table Header
        TableRow(
          decoration: const BoxDecoration(color: headerBgColor),
          children: [
            _th('NO.', height: 42),
            _th('URAIAN'),
            _th('Satuan'),
            _th('Volume\nKontrak'),
            _th('Nilai\nBobot\n%'),
            _th('MINGGU LALU\nVol'),
            _th('MINGGU LALU\n%'),
            _th('MINGGU INI\nVol'),
            _th('MINGGU INI\n%'),
            _th('S/D MINGGU INI\nVol'),
            _th('S/D MINGGU INI\n%'),
            _th('Sisa Pekerjaan\nVol'),
            _th('Sisa Pekerjaan\n%'),
            _th('Ket.'),
          ],
        ),

        // Body Rows (Divisi and Items)
        ...divisiList.expand((div) {
          final romawi = div['nomorRomawi']?.toString() ?? 'I';
          final namaDiv = div['namaDivisi']?.toString() ?? 'DIVISI';
          final items = div['items'] as List? ?? [];

          return [
            // Divisi Header Row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                _tdText(romawi, isBold: true, align: TextAlign.center),
                _tdText(namaDiv.toUpperCase(), isBold: true),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
                _tdText(''),
              ],
            ),

            // Item Rows
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

              return TableRow(
                children: [
                  _tdText('$idx', align: TextAlign.center),
                  _tdText(uraian),
                  _tdText(satuan, align: TextAlign.center),
                  _tdText(volKontrak > 0 ? _fmtNum(volKontrak) : '-', align: TextAlign.right),
                  _tdText(bbtKontrak > 0 ? _fmtNum(bbtKontrak, dec: 3) : '-', align: TextAlign.right),
                  _tdText(mlVol > 0 ? _fmtNum(mlVol) : '-', align: TextAlign.right),
                  _tdText(mlBbt > 0 ? _fmtNum(mlBbt, dec: 2) : '-', align: TextAlign.right),
                  _tdText(miVol > 0 ? _fmtNum(miVol) : '-', align: TextAlign.right),
                  _tdText(miBbt > 0 ? _fmtNum(miBbt, dec: 2) : '-', align: TextAlign.right),
                  _tdText(sdVol > 0 ? _fmtNum(sdVol) : '-', align: TextAlign.right),
                  _tdText(sdBbt > 0 ? _fmtNum(sdBbt, dec: 2) : '-', align: TextAlign.right),
                  _tdText(ssVol > 0 ? _fmtNum(ssVol) : '-', align: TextAlign.right),
                  _tdText(ssBbt > 0 ? _fmtNum(ssBbt, dec: 2) : '-', align: TextAlign.right),
                  _tdText('-', align: TextAlign.center),
                ],
              );
            }),
          ];
        }),

        // SUMMARY TOTAL ROW
        TableRow(
          decoration: const BoxDecoration(color: headerBgColor),
          children: [
            _tdText(''),
            _tdText('Jumlah', isBold: true, align: TextAlign.center),
            _tdText(''),
            _tdText(''),
            _tdText(_fmtNum(totalNilaiBobot, dec: 3), isBold: true, align: TextAlign.right),
            _tdText(''),
            _tdText(_fmtNum(totalMingguLaluBobot, dec: 2), isBold: true, align: TextAlign.right),
            _tdText(''),
            _tdText(_fmtNum(totalMingguIniBobot, dec: 2), isBold: true, align: TextAlign.right),
            _tdText(''),
            _tdText(_fmtNum(totalSdMingguIniBobot, dec: 2), isBold: true, align: TextAlign.right),
            _tdText(''),
            _tdText(_fmtNum(totalSisaBobot, dec: 2), isBold: true, align: TextAlign.right),
            _tdText(''),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSummary(double rencana, double realisasi, double deviasi) {
    return Container(
      padding: const EdgeInsets.only(left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryLine('Rencana Pekerjaan', ':  ${_fmtNum(rencana, dec: 2)} %'),
          const SizedBox(height: 3),
          _buildSummaryLine('Realisasi Pekerjaan', ':  ${_fmtNum(realisasi, dec: 2)} %'),
          const SizedBox(height: 3),
          _buildSummaryLine(
            'Deviasi',
            ':  ${deviasi >= 0 ? '+' : ''}${_fmtNum(deviasi, dec: 2)} %',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, {bool isBold = false}) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _th(String text, {double? height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          height: 1.15,
        ),
      ),
    );
  }

  Widget _tdText(
    String text, {
    bool isBold = false,
    TextAlign align = TextAlign.left,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: Colors.black,
        ),
      ),
    );
  }

  static String _fmtNum(double n, {int dec = 2}) {
    if (n == 0) return '-';
    return n.toStringAsFixed(dec);
  }

  static String _toRoman(int n) {
    const roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV'];
    if (n >= 1 && n <= roman.length) {
      return roman[n - 1];
    }
    return '$n';
  }
}

