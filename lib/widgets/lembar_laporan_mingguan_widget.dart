import 'package:flutter/material.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';

class LembarLaporanMingguanWidget extends StatelessWidget {
  final WeeklyReportModel report;
  final VoidCallback? onEdit;
  final VoidCallback? onDownloadPdf;

  const LembarLaporanMingguanWidget({
    super.key,
    required this.report,
    this.onEdit,
    this.onDownloadPdf,
  });

  // Colors matching the original physical document photo
  static const Color headerBgColor = Color(0xFFDCE6EE); // Cool grey/blue tone for headers
  static const Color yellowHighlight = Color(0xFFFFDE59); // Authentic vibrant yellow highlight
  static const Color borderColor = Color(0xFF4B5563); // Clean crisp border

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: 600,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onDownloadPdf != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDownloadPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 14, color: Color(0xFF1E3A8A)),
                  label: const Text('Export PDF Ringkasan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                ),
              ),
              const SizedBox(height: 6),
            ],
            // 1. JUDUL DOKUMEN RESMI
            const Center(
              child: Text(
                'RINGKASAN KEGIATAN MINGGUAN',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. KOTAK INFORMASI KONTRAK & PROYEK
          _buildInfoTable(),
          const SizedBox(height: 14),

          // 3. TABEL BOBOT S/D MINGGU INI (TABEL BAWAH)
          _buildWeeklyProgressTable(),
          const SizedBox(height: 14),
        ],
      ),
    ),
  );
}

  // TABLE BAGIAN ATAS (KOP & RINGKASAN PROGRESS MINGGU INI)
  Widget _buildInfoTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        children: [
          // Row: PEKERJAAN
          _buildInfoRow(
            label: 'PEKERJAAN',
            value: report.pekerjaan.toUpperCase(),
            isBold: true,
          ),
          _buildDivider(),

          // Row: LOKASI PROYEK
          _buildInfoRow(
            label: 'LOKASI PROYEK',
            value: report.lokasiProyek.toUpperCase(),
          ),
          _buildDivider(),

          // Row: KONTRAKTOR PELAKSANA
          _buildInfoRow(
            label: 'KONTRAKTOR PELAKSANA',
            value: report.kontraktor.toUpperCase(),
          ),
          _buildDivider(),

          // Row: JANGKA WAKTU KONTRAK
          _buildInfoRowWithSuffix(
            label: 'JANGKA WAKTU KONTRAK',
            value: '${report.jangkaWaktu}',
            suffix: 'Hari Kalender',
          ),
          _buildDivider(),

          // Row: NOMOR KONTRAK
          _buildInfoRow(
            label: 'NOMOR KONTRAK',
            value: report.nomorKontrak,
          ),
          _buildDivider(),

          // Row: TANGGAL KONTRAK
          _buildInfoRow(
            label: 'TANGGAL KONTRAK',
            value: report.tanggalKontrak,
          ),
          _buildDivider(),

          // Row: NILAI KONTRAK
          _buildInfoRow(
            label: 'NILAI KONTRAK',
            value: report.nilaiKontrak.startsWith('Rp')
                ? report.nilaiKontrak
                : 'Rp ${report.nilaiKontrak}',
          ),
          _buildDivider(),

          // Row: TANGGAL SPMK
          _buildInfoRow(
            label: 'TANGGAL SPMK',
            value: report.tanggalSpmk,
          ),
          _buildDivider(),

          // SECTION LAPORAN MINGGU KE - (Cool grey/blue header background)
          Container(
            color: headerBgColor,
            child: _buildInfoRowTwoCols(
              label: 'LAPORAN MINGGU KE -',
              col1: '${report.mingguKe}',
              col1Prefix: '',
              col2: '${report.totalMinggu}',
              col2Prefix: 'dari',
              isBoldVal: true,
            ),
          ),
          _buildDivider(),

          // PERIODE
          Container(
            color: Colors.white,
            child: _buildInfoRowTwoCols(
              label: 'PERIODE',
              col1: report.periodeAwal,
              col1Prefix: '',
              col2: report.periodeAkhir,
              col2Prefix: 's/d',
              isBoldVal: false,
            ),
          ),
          _buildDivider(),

          // RENCANA FISIK S/D MINGGU INI
          _buildProgressSummaryRow(
            label: 'RENCANA FISIK S/D MINGGU INI',
            percentStr: '${WeeklyReportModel.formatPercent(report.rencanaPersen, decimalDigits: 2, appendUnit: false)} %',
            nominalStr: WeeklyReportModel.formatRupiah(report.rencanaNominal, withRp: false),
            bgColor: Colors.white,
          ),
          _buildDivider(),

          // REALISASI FISIK S/D MINGGU INI
          _buildProgressSummaryRow(
            label: 'REALISASI FISIK S/D MINGGU INI',
            percentStr: '${WeeklyReportModel.formatPercent(report.realisasiPersen, decimalDigits: 2, appendUnit: false)} %',
            nominalStr: WeeklyReportModel.formatRupiah(report.realisasiNominal, withRp: false),
            bgColor: Colors.white,
          ),
          _buildDivider(),

          // DEVIASI (+/-) - HIGHLIGHT KUNING MENCOLOK SESUAI DOKUMEN FISIK
          _buildProgressSummaryRow(
            label: 'DEVIASI (+/-)',
            percentStr: '${WeeklyReportModel.formatPercent(report.deviasiPersen, decimalDigits: 2, showSign: false, appendUnit: false)} %',
            nominalStr: WeeklyReportModel.formatRupiah(report.deviasiNominal, withRp: false),
            bgColor: yellowHighlight,
            isBold: true,
          ),
          _buildDivider(),

          // WAKTU TERPAKAI
          _buildInfoRowWithSuffix(
            label: 'WAKTU TERPAKAI',
            value: '${report.waktuTerpakai}',
            suffix: 'Hari Kalender',
          ),
          _buildDivider(),

          // SISA WAKTU
          _buildInfoRowWithSuffix(
            label: 'SISA WAKTU',
            value: '${report.sisaWaktu}',
            suffix: 'Hari Kalender',
          ),
          _buildDivider(),

          // AKHIR MASA KONTRAK
          _buildInfoRow(
            label: 'AKHIR MASA KONTRAK',
            value: report.akhirMasaKontrak,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1.0,
      color: borderColor,
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 175,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithSuffix({
    required String label,
    required String value,
    required String suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      child: Row(
        children: [
          SizedBox(
            width: 175,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 30),
          Text(
            suffix,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowTwoCols({
    required String label,
    required String col1,
    required String col1Prefix,
    required String col2,
    required String col2Prefix,
    bool isBoldVal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      child: Row(
        children: [
          SizedBox(
            width: 175,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          if (col1Prefix.isNotEmpty) ...[
            Text(col1Prefix, style: const TextStyle(fontSize: 10, color: Colors.black)),
            const SizedBox(width: 4),
          ],
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                col1,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isBoldVal ? FontWeight.bold : FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                col2Prefix,
                style: const TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              col2,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isBoldVal ? FontWeight.bold : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummaryRow({
    required String label,
    required String percentStr,
    required String nominalStr,
    required Color bgColor,
    bool isBold = false,
  }) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      child: Row(
        children: [
          SizedBox(
            width: 175,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                percentStr,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(
                  nominalStr,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // TABEL BAWAH: BOBOT S/D MINGGU INI
  Widget _buildWeeklyProgressTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Table(
                border: const TableBorder(
                  horizontalInside: BorderSide(color: borderColor, width: 0.8),
                  verticalInside: BorderSide(color: borderColor, width: 0.8),
                ),
                columnWidths: const {
                  0: FixedColumnWidth(68),  // STATUS KONTRAK/ADDENDUM
                  1: FixedColumnWidth(52),  // MINGGU KE-
                  2: FixedColumnWidth(160), // PERIODE
                  3: FixedColumnWidth(68),  // RENCANA (%)
                  4: FixedColumnWidth(68),  // REALISASI (%)
                  5: FixedColumnWidth(68),  // DEVIASI (%)
                },
                children: [
                  // HEADER BARIS 1: MERGED COLUMNS
                  TableRow(
                    decoration: const BoxDecoration(color: headerBgColor),
                    children: [
                      _buildHeaderCell('STATUS\nKONTRAK/\nADDENDUM', height: 42),
                      _buildHeaderCell('MINGGU\nKE -', height: 42),
                      _buildHeaderCell('PERIODE', height: 42),
                      // Span 3 columns logically for BOBOT
                      _buildHeaderCell('BOBOT S/D MINGGU INI\nRENCANA\n(%)', height: 42),
                      _buildHeaderCell('BOBOT S/D MINGGU INI\nREALISASI\n(%)', height: 42),
                      _buildHeaderCell('BOBOT S/D MINGGU INI\nDEVIASI\n(%)', height: 42),
                    ],
                  ),

                  // DATA ROWS DARI tabelMingguan
                  ...report.tabelMingguan.map((row) {
                    final bool isCurrentWeek = row.mingguKe == report.mingguKe;
                    final Color rowColor = isCurrentWeek ? yellowHighlight : Colors.white;
                    final FontWeight weight = isCurrentWeek ? FontWeight.bold : FontWeight.normal;

                    final rencanaText = row.rencana != null
                        ? WeeklyReportModel.formatPercent(row.rencana, decimalDigits: 3, appendUnit: false)
                        : '';
                    final realisasiText = row.realisasi != null
                        ? WeeklyReportModel.formatPercent(row.realisasi, decimalDigits: 3, appendUnit: false)
                        : '';
                    final deviasiText = row.deviasi != null
                        ? WeeklyReportModel.formatPercent(row.deviasi, decimalDigits: 3, showSign: false, appendUnit: false)
                        : '';

                    return TableRow(
                      decoration: BoxDecoration(color: rowColor),
                      children: [
                        _buildDataCell(row.status, align: TextAlign.left, fontWeight: weight),
                        _buildDataCell('${row.mingguKe}', align: TextAlign.center, fontWeight: weight),
                        _buildDataCell(
                          '${row.tglMulai}    -    ${row.tglSelesai}',
                          align: TextAlign.center,
                          fontWeight: weight,
                        ),
                        _buildDataCell(rencanaText, align: TextAlign.right, fontWeight: weight),
                        _buildDataCell(realisasiText, align: TextAlign.right, fontWeight: weight),
                        _buildDataCell(deviasiText, align: TextAlign.right, fontWeight: weight),
                      ],
                    );
                  }),

                  // KOSONGKAN BEBERAPA BARIS CADANGAN DI BAWAH (SESUAI DOKUMEN CETAK ASLI)
                  ...List.generate(3, (idx) {
                    return TableRow(
                      decoration: const BoxDecoration(color: Colors.white),
                      children: [
                        _buildDataCell(''),
                        _buildDataCell(''),
                        _buildDataCell(''),
                        _buildDataCell(''),
                        _buildDataCell(''),
                        _buildDataCell(''),
                      ],
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(String text, {double height = 36}) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
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

  Widget _buildDataCell(
    String text, {
    TextAlign align = TextAlign.center,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.2),
      alignment: align == TextAlign.left
          ? Alignment.centerLeft
          : align == TextAlign.right
              ? Alignment.centerRight
              : Alignment.center,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: fontWeight,
          color: Colors.black,
        ),
      ),
    );
  }
}
