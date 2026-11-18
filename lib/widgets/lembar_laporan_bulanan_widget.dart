import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/widgets/horizontal_drag_scroll_area.dart';

class LembarLaporanBulananWidget extends StatefulWidget {
  final MonthlyReportModel report;
  final VoidCallback? onDownloadPdf;

  const LembarLaporanBulananWidget({
    super.key,
    required this.report,
    this.onDownloadPdf,
  });

  @override
  State<LembarLaporanBulananWidget> createState() => _LembarLaporanBulananWidgetState();
}

class _LembarLaporanBulananWidgetState extends State<LembarLaporanBulananWidget> {
  late final ScrollController _horizontalScrollController;
  late final ScrollController _verticalScrollController;

  @override
  void initState() {
    super.initState();
    _horizontalScrollController = ScrollController();
    _verticalScrollController = ScrollController();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  String _formatNum(double val, {int decimals = 2, bool dashIfZero = false}) {
    if (dashIfZero && val.abs() < 0.0001) return '-';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: decimals,
    );
    return formatter.format(val).trim();
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Action Bar (Download PDF & Status)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: report.status == 'Selesai'
                          ? const Color(0xFFE6F4EA)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: report.status == 'Selesai'
                            ? const Color(0xFF34A853)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    child: Text(
                      report.statusDetail,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: report.status == 'Selesai'
                            ? const Color(0xFF137333)
                            : const Color(0xFFB45309),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: widget.onDownloadPdf ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Mengunduh Laporan Bulanan (Bulan ${report.bulanRomawi}).pdf...',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text(
                    'PDF',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Printable Paper Canvas with Dual-Axis High Contrast Scrolling
          Expanded(
            child: Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Document Title
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                'LAPORAN BULANAN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'BULAN ${report.bulanRomawi}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '( PERIODE TANGGAL: ${report.periodeFormatted.toUpperCase()} )',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Project Metadata Header
                        _buildProjectMetadata(report),
                        const SizedBox(height: 16),

                        // Main PU Table with Horizontal Scroll
                        HorizontalDragScrollArea(
                          child: SingleChildScrollView(
                            controller: _horizontalScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            child: _buildBoQTable(report),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Bottom Summary (Rencana, Realisasi, Deviasi)
                        _buildBottomSummary(report),
                        const SizedBox(height: 24),

                        // Tanda Tangan Multi-Pihak Digital
                        _buildSignaturesPreview(report),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectMetadata(MonthlyReportModel report) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 0.8),
      ),
      child: Column(
        children: [
          _buildMetaRow('Pekerjaan', report.namaKegiatan),
          const SizedBox(height: 4),
          _buildMetaRow('Lokasi', report.lokasi),
          const SizedBox(height: 4),
          _buildMetaRow('Sumber Dana', report.sumberDana),
          const SizedBox(height: 4),
          _buildMetaRow('Pelaksana Kontraktor', report.pelaksanaKontraktor),
          const SizedBox(height: 4),
          _buildMetaRow('No Kontrak', report.noKontrak),
          const SizedBox(height: 4),
          _buildMetaRow('Pengawas', report.konsultanPengawas),
          const SizedBox(height: 4),
          _buildMetaRow('No Kontrak Pengawas', report.noKontrakPengawas),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 170,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoQTable(MonthlyReportModel report) {
    const borderSide = BorderSide(color: Color(0xFF334155), width: 0.9);
    const tableBorder = TableBorder(
      left: borderSide,
      right: borderSide,
      top: borderSide,
      bottom: borderSide,
      verticalInside: borderSide,
      horizontalInside: borderSide,
    );

    return Table(
      border: tableBorder,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: FixedColumnWidth(34),  // NO
        1: FixedColumnWidth(70),  // No. Mata Pembayaran
        2: FixedColumnWidth(230), // Uraian
        3: FixedColumnWidth(55),  // Satuan
        4: FixedColumnWidth(65),  // Volume CCO
        5: FixedColumnWidth(65),  // Nilai Bobot %
        6: FixedColumnWidth(60),  // Bulan Lalu Vol
        7: FixedColumnWidth(58),  // Bulan Lalu Bobot
        8: FixedColumnWidth(60),  // Bulan Ini Vol
        9: FixedColumnWidth(58),  // Bulan Ini Bobot
        10: FixedColumnWidth(60), // S/D Bulan Ini Vol
        11: FixedColumnWidth(58), // S/D Bulan Ini Bobot
        12: FixedColumnWidth(60), // Sisa Vol
        13: FixedColumnWidth(58), // Sisa Bobot
        14: FixedColumnWidth(60), // Ket.
      },
      children: [
        // Header Row 1
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
          children: [
            _th('NO.'),
            _th('No. Mata\nPembayaran'),
            _th('URAIAN'),
            _th('Satuan'),
            _th('Volume\nCCO'),
            _th('Nilai\nBobot\n%'),
            _th('BULAN LALU'),
            _th('BULAN LALU'),
            _th('BULAN INI'),
            _th('BULAN INI'),
            _th('S/D BULAN INI'),
            _th('S/D BULAN INI'),
            _th('Sisa Pekerjaan'),
            _th('Sisa Pekerjaan'),
            _th('Ket.'),
          ],
        ),

        // Header Row 2 (Sub-headers for Physical Progress)
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
          children: [
            _thSub(''),
            _thSub(''),
            _thSub(''),
            _thSub(''),
            _thSub(''),
            _thSub(''),
            _thSub('Volume'),
            _thSub('Bobot\n%'),
            _thSub('Volume'),
            _thSub('Bobot\n%'),
            _thSub('Volume'),
            _thSub('Bobot\n%'),
            _thSub('Volume'),
            _thSub('Bobot\n%'),
            _thSub(''),
          ],
        ),

        // Division & Item Rows
        ...report.divisions.expand((division) {
          final List<TableRow> rows = [];

          // Division Row
          rows.add(
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _tdText(division.kode, bold: true, align: TextAlign.center),
                _tdText('', bold: true),
                _tdText(division.nama, bold: true),
                _tdText(''),
                _tdText(''),
                _tdText(
                  _formatNum(division.subtotalBobotCCO, decimals: 3),
                  align: TextAlign.right,
                  bold: true,
                ),
                _tdText(''),
                _tdText(
                  _formatNum(division.subtotalBobotBulanLalu, decimals: 2, dashIfZero: true),
                  align: TextAlign.right,
                  bold: true,
                ),
                _tdText(''),
                _tdText(
                  _formatNum(division.subtotalBobotBulanIni, decimals: 2, dashIfZero: true),
                  align: TextAlign.right,
                  bold: true,
                ),
                _tdText(''),
                _tdText(
                  _formatNum(division.subtotalBobotSdBulanIni, decimals: 2, dashIfZero: true),
                  align: TextAlign.right,
                  bold: true,
                ),
                _tdText(''),
                _tdText(
                  _formatNum(division.subtotalBobotSisa, decimals: 2, dashIfZero: true),
                  align: TextAlign.right,
                  bold: true,
                ),
                _tdText(''),
              ],
            ),
          );

          // Items
          for (final item in division.items) {
            rows.add(
              TableRow(
                children: [
                  _tdText(item.no, align: TextAlign.center),
                  _tdText(item.noMataPembayaran, align: TextAlign.center),
                  _tdText(item.uraian),
                  _tdText(item.satuan, align: TextAlign.center),
                  _tdText(_formatNum(item.volumeCCO, decimals: 2), align: TextAlign.right),
                  _tdText(_formatNum(item.bobotCCO, decimals: 3), align: TextAlign.right),
                  _tdText(
                    _formatNum(item.volumeBulanLalu, decimals: 2, dashIfZero: true),
                    align: TextAlign.right,
                  ),
                  _tdText(
                    _formatNum(item.bobotBulanLalu, decimals: 2, dashIfZero: true),
                    align: TextAlign.right,
                  ),
                  _tdText(
                    _formatNum(item.volumeBulanIni, decimals: 2, dashIfZero: true),
                    align: TextAlign.right,
                  ),
                  _tdText(
                    _formatNum(item.bobotBulanIni, decimals: 2, dashIfZero: true),
                    align: TextAlign.right,
                  ),
                  _tdText(
                    _formatNum(item.volumeSdBulanIni, decimals: 2, dashIfZero: true),
                    align: TextAlign.right,
                  ),
                  _tdText(
                    _formatNum(item.bobotSdBulanIni, decimals: 2, dashIfZero: true),
                    align: TextAlign.right,
                  ),
                  _tdText(
                    _formatNum(item.sisaVolume, decimals: 2, dashIfZero: true),
                    align: TextAlign.right,
                  ),
                  _tdText(
                    _formatNum(item.sisaBobot, decimals: 2, dashIfZero: true),
                    align: TextAlign.right,
                  ),
                  _tdText(item.keterangan, align: TextAlign.center),
                ],
              ),
            );
          }

          return rows;
        }),

        // Summary Total Row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
          children: [
            _tdText('', bold: true),
            _tdText('', bold: true),
            _tdText('Jumlah', bold: true, align: TextAlign.center),
            _tdText(''),
            _tdText(''),
            _tdText(
              _formatNum(report.totalBobotCCO, decimals: 3),
              align: TextAlign.right,
              bold: true,
            ),
            _tdText(''),
            _tdText(
              _formatNum(report.totalBobotBulanLalu, decimals: 2, dashIfZero: true),
              align: TextAlign.right,
              bold: true,
            ),
            _tdText(''),
            _tdText(
              _formatNum(report.totalBobotBulanIni, decimals: 2, dashIfZero: true),
              align: TextAlign.right,
              bold: true,
            ),
            _tdText(''),
            _tdText(
              _formatNum(report.totalBobotSdBulanIni, decimals: 2, dashIfZero: true),
              align: TextAlign.right,
              bold: true,
            ),
            _tdText(''),
            _tdText(
              _formatNum(report.totalBobotSisa, decimals: 2, dashIfZero: true),
              align: TextAlign.right,
              bold: true,
            ),
            _tdText(''),
          ],
        ),
      ],
    );
  }

  Widget _th(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _thSub(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _tdText(
    String text, {
    TextAlign align = TextAlign.left,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: bold ? FontWeight.bold : FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildBottomSummary(MonthlyReportModel report) {
    final deviasi = report.deviasiPersen;
    final isDeviasiPositif = deviasi >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryLine(
            'Rencana Pekerjaan',
            '${_formatNum(report.rencanaFisikPersen, decimals: 2)} %',
          ),
          const SizedBox(height: 3),
          _buildSummaryLine(
            'Realisasi Pekerjaan',
            '${_formatNum(report.realisasiKumulatifPersen, decimals: 2)} %',
            bold: true,
          ),
          const SizedBox(height: 3),
          _buildSummaryLine(
            'Deviasi',
            '${isDeviasiPositif ? '+' : ''}${_formatNum(deviasi, decimals: 2)} %',
            valueColor: isDeviasiPositif ? const Color(0xFF137333) : const Color(0xFFC5221F),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    String value, {
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: bold ? FontWeight.bold : FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: bold ? FontWeight.bold : FontWeight.w700,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildSignaturesPreview(MonthlyReportModel report) {
    final rawSigners = report.ttdList ?? [];
    final List<Map<String, dynamic>> signers = [];
    if (rawSigners.isNotEmpty) {
      signers.addAll(rawSigners);
    } else {
      final dateStr = report.periodeFormatted.split('-').last.trim();
      signers.addAll([
        {
          'peran': 'Kontraktor Pelaksana',
          'instansi': report.pelaksanaKontraktor,
          'nama': report.ttdKontraktorNama ?? '',
          'tanggal': report.ttdKontraktorTanggal ?? dateStr,
          'signature': report.ttdKontraktorSignature,
        },
        {
          'peran': 'Konsultan Supervisi',
          'instansi': 'CV. TATA SAKA CONSULTANT',
          'nama': report.ttdKonsultanNama ?? '',
          'tanggal': report.ttdKonsultanTanggal ?? dateStr,
          'signature': report.ttdKonsultanSignature,
        },
        {
          'peran': 'Pejabat Pembuat Komitmen (PPK)',
          'instansi': 'DPU-PR Kab. Purbalingga',
          'nama': report.ttdPpkNama ?? '',
          'tanggal': report.ttdPpkTanggal ?? dateStr,
          'signature': report.ttdPpkSignature,
        },
      ]);
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: signers.length == 1
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: signers.map((s) {
          final peran = (s['peran'] ?? s['jabatan'] ?? '').toString().trim();
          final instansi = (s['instansi'] ?? '').toString().trim();
          final nama = (s['nama'] ?? '').toString().trim();
          final tanggal = (s['tanggal'] ?? '').toString().trim();
          final sigStr = s['signature']?.toString();

          final List<String> headerLines = [];
          if (tanggal.isNotEmpty) headerLines.add(tanggal);
          if (peran.isNotEmpty) headerLines.add(peran);
          if (instansi.isNotEmpty) headerLines.add(instansi);

          Widget? sigWidget;
          if (sigStr != null && sigStr.isNotEmpty) {
            try {
              if (sigStr.startsWith('data:image')) {
                final base64Content = sigStr.split(',').last;
                final bytes = base64Decode(base64Content);
                sigWidget = Image.memory(bytes, height: 36, fit: BoxFit.contain);
              }
            } catch (_) {}
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    headerLines.isNotEmpty ? headerLines.join('\n') : 'Penandatangan',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8.5, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  sigWidget ?? const SizedBox(height: 36),
                  const Text(
                    '_______________________',
                    style: TextStyle(fontSize: 8.5, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nama.isNotEmpty ? nama : '( .................................... )',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 8.5,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
