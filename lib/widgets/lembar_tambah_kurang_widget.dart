import 'package:flutter/material.dart';
import 'package:tata_saka_app/models/addendum_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';

class LembarTambahKurangWidget extends StatelessWidget {
  final KegiatanModel kegiatan;
  final Map<String, dynamic> addendumData;
  final List<Map<String, dynamic>> baselineDivisiList;
  final VoidCallback? onDownloadPdf;

  const LembarTambahKurangWidget({
    super.key,
    required this.kegiatan,
    required this.addendumData,
    required this.baselineDivisiList,
    this.onDownloadPdf,
  });

  static const Color headerBgColor = Color(0xFFF3F4F6);
  static const Color borderColor = Colors.black;

  @override
  Widget build(BuildContext context) {
    final nomorAddendum = addendumData['nomorAddendum']?.toString() ?? '01';
    final addendumDivisiList =
        (addendumData['rkkDivisiList'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    final paguDibulatkan = RupiahUtil.parseToDouble(kegiatan.nilaiKontrak);
    final report = TambahKurangCalculator.calculate(
      baselineDivisiList: baselineDivisiList,
      addendumDivisiList: addendumDivisiList,
      customPaguDibulatkan: paguDibulatkan > 0 ? paguDibulatkan : null,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: 1320,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onDownloadPdf != null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onDownloadPdf,
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    size: 14,
                    color: Color(0xFF1E3A8A),
                  ),
                  label: const Text(
                    'Export PDF Tambah Kurang (18-Kolom)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
            // 1. JUDUL DOKUMEN RESMI
            Center(
              child: Text(
                'DAFTAR PERHITUNGAN TAMBAH KURANG KE - $nomorAddendum',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 0.8,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 2. KOTAK METADATA PROYEK
            _buildMetadataTable(),
            const SizedBox(height: 16),

            // 3. TABEL 18 KOLOM PERHITUNGAN TAMBAH KURANG
            _buildTambahKurangTable(nomorAddendum, report),
            const SizedBox(height: 24),

            // 4. BAGIAN TANDA TANGAN RESMI
            _buildSignatureSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black45, width: 0.8),
        color: const Color(0xFFFAFAFA),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow('Kegiatan', kegiatan.namaKegiatan),
                _buildMetaRow('Pekerjaan', kegiatan.namaKegiatan),
                _buildMetaRow(
                  'Lokasi',
                  kegiatan.lokasi.isNotEmpty
                      ? kegiatan.lokasi
                      : 'Kab. Purbalingga',
                ),
                _buildMetaRow(
                  'Sumber Dana',
                  kegiatan.sumberDana.isNotEmpty
                      ? kegiatan.sumberDana
                      : 'APBD Kab. Purbalingga',
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetaRow(
                  'Pelaksana Kontraktor',
                  kegiatan.kontraktor.isNotEmpty ? kegiatan.kontraktor : '-',
                ),
                _buildMetaRow(
                  'No Kontrak',
                  kegiatan.suratPesananFull.isNotEmpty
                      ? kegiatan.suratPesananFull
                      : '-',
                ),
                _buildMetaRow(
                  'Pengawas',
                  kegiatan.konsultanPengawas.isNotEmpty
                      ? kegiatan.konsultanPengawas
                      : 'CV. TATA SAKA CONSULTANT',
                ),
                _buildMetaRow(
                  'No Kontrak Pengawasan',
                  kegiatan.spkKonsultanFull.isNotEmpty
                      ? kegiatan.spkKonsultanFull
                      : '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
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
            ' :  ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 10.5, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTambahKurangTable(
    String nomorAddendum,
    TambahKurangReportResult report,
  ) {
    const colWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(30), // No
      1: FixedColumnWidth(75), // No Mata Pembayaran
      2: FixedColumnWidth(230), // Uraian
      3: FixedColumnWidth(40), // Satuan
      4: FixedColumnWidth(95), // Harga Satuan
      // KONTRAK AWAL
      5: FixedColumnWidth(55), // Vol
      6: FixedColumnWidth(95), // Total
      7: FixedColumnWidth(52), // Bobot
      // ADDENDUM KE - N
      8: FixedColumnWidth(55), // Vol
      9: FixedColumnWidth(95), // Total
      10: FixedColumnWidth(52), // Bobot
      // PEKERJAAN TAMBAH
      11: FixedColumnWidth(55), // Vol
      12: FixedColumnWidth(95), // Total
      13: FixedColumnWidth(52), // Bobot
      // PEKERJAAN KURANG
      14: FixedColumnWidth(55), // Vol
      15: FixedColumnWidth(95), // Total
      16: FixedColumnWidth(52), // Bobot
      // KET
      17: FixedColumnWidth(52), // Ket
    };

    return Table(
      border: TableBorder.all(color: borderColor, width: 0.8),
      columnWidths: colWidths,
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // ─── HEADER BARIS 1 (Grup Kolom) ───
        TableRow(
          decoration: const BoxDecoration(color: headerBgColor),
          children: [
            _th('No', height: 28),
            _th('No Mata\nPembayaran', height: 28),
            _th('Uraian', height: 28),
            _th('Satuan', height: 28),
            _th('Harga\nSatuan\n( Rp. )', height: 28),
            _th('KONTRAK AWAL', height: 28),
            _th(''),
            _th(''),
            _th('ADDENDUM $nomorAddendum', height: 28),
            _th(''),
            _th(''),
            _th('PEKERJAAN TAMBAH KURANG', height: 28),
            _th(''),
            _th(''),
            _th(''),
            _th(''),
            _th(''),
            _th('KET.', height: 28),
          ],
        ),

        // ─── HEADER BARIS 2 (Sub-Kolom) ───
        TableRow(
          decoration: const BoxDecoration(color: headerBgColor),
          children: [
            _th(''),
            _th(''),
            _th(''),
            _th(''),
            _th(''),
            // Kontrak Awal
            _th('Volume\nPekerjaan'),
            _th('Total\nHarga\n( Rp. )'),
            _th('Nilai\nBobot\n%'),
            // Addendum
            _th('Volume\nPekerjaan'),
            _th('Total\nHarga\n( Rp. )'),
            _th('Nilai\nBobot\n%'),
            // Pekerjaan Tambah
            _th('Volume\nPekerjaan'),
            _th('Total\nHarga\n( Rp. )'),
            _th('Nilai\nBobot\n%'),
            // Pekerjaan Kurang
            _th('Volume\nPekerjaan'),
            _th('Total\nHarga\n( Rp. )'),
            _th('Nilai\nBobot\n%'),
            _th(''),
          ],
        ),

        // ─── DATA ROWS PER DIVISI & ITEM ───
        ...report.divisiResults.expand((div) {
          return [
            // Division Header Row (Format Resmi Fisik PU: Bersih Tanpa Subtotal di Judul Divisi)
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                _tdText(div.nomorRomawi, align: TextAlign.center, isBold: true),
                _tdText(''),
                _tdText(div.namaDivisi.toUpperCase(), isBold: true),
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
                _tdText(''),
                _tdText(''),
                _tdText(''),
              ],
            ),

            // Item Rows
            ...div.items.map((it) {
              return TableRow(
                children: [
                  _tdText(it.no, align: TextAlign.center),
                  _tdText(
                    it.noMataPembayaran,
                    align: TextAlign.center,
                    isBold: true,
                  ),
                  _tdText(it.uraian),
                  _tdText(it.satuan, align: TextAlign.center),
                  _tdText(
                    _fmtRupiahNoPrefix(it.hargaSatuan),
                    align: TextAlign.right,
                  ),

                  // Kontrak Awal
                  _tdText(
                    it.baselineVolume > 0 ? _fmtVol(it.baselineVolume) : '-',
                    align: TextAlign.right,
                  ),
                  _tdText(
                    it.baselineTotalHarga > 0
                        ? _fmtRupiahNoPrefix(it.baselineTotalHarga)
                        : '-',
                    align: TextAlign.right,
                  ),
                  _tdText(
                    it.baselineBobot > 0
                        ? it.baselineBobot.toStringAsFixed(3)
                        : '-',
                    align: TextAlign.right,
                  ),

                  // Addendum
                  _tdText(
                    it.addendumVolume > 0 ? _fmtVol(it.addendumVolume) : '-',
                    align: TextAlign.right,
                  ),
                  _tdText(
                    it.addendumTotalHarga > 0
                        ? _fmtRupiahNoPrefix(it.addendumTotalHarga)
                        : '-',
                    align: TextAlign.right,
                  ),
                  _tdText(
                    it.addendumBobot > 0
                        ? it.addendumBobot.toStringAsFixed(3)
                        : '-',
                    align: TextAlign.right,
                  ),

                  // Tambah
                  _tdText(
                    it.tambahVolume > 0 ? _fmtVol(it.tambahVolume) : '-',
                    align: TextAlign.right,
                  ),
                  _tdText(
                    it.tambahTotalHarga > 0
                        ? _fmtRupiahNoPrefix(it.tambahTotalHarga)
                        : '-',
                    align: TextAlign.right,
                  ),
                  _tdText(
                    it.tambahBobot > 0
                        ? it.tambahBobot.toStringAsFixed(3)
                        : '-',
                    align: TextAlign.right,
                  ),

                  // Kurang
                  _tdText(
                    it.kurangVolume > 0 ? _fmtVol(it.kurangVolume) : '-',
                    align: TextAlign.right,
                  ),
                  _tdText(
                    it.kurangTotalHarga > 0
                        ? _fmtRupiahNoPrefix(it.kurangTotalHarga)
                        : '-',
                    align: TextAlign.right,
                  ),
                  _tdText(
                    it.kurangBobot > 0
                        ? it.kurangBobot.toStringAsFixed(3)
                        : '-',
                    align: TextAlign.right,
                  ),

                  // Ket
                  _tdText(
                    it.keterangan,
                    align: TextAlign.center,
                    isBold: it.keterangan != 'Tetap',
                    color: it.keterangan == 'Tambah'
                        ? const Color(0xFF047857)
                        : (it.keterangan == 'Kurang'
                              ? const Color(0xFFB45309)
                              : Colors.black),
                  ),
                ],
              );
            }),
          ];
        }),

        // ─── SUMMARY FOOTER ROW 1: JUMLAH HARGA PEKERJAAN ───
        TableRow(
          decoration: const BoxDecoration(color: headerBgColor),
          children: [
            _tdText(''),
            _tdText(''),
            _tdText(
              'Jumlah Harga Pekerjaan ( Termasuk Biaya umum, Keuntungan dan ( Pajak )',
              isBold: true,
            ),
            _tdText(''),
            _tdText(''),
            // Baseline
            _tdText(''),
            _tdText(
              _fmtRupiahNoPrefix(
                report.totalBaselineHarga,
                forceDecimals: true,
              ),
              align: TextAlign.right,
              isBold: true,
            ),
            _tdText(
              report.totalBaselineBobot.toStringAsFixed(3),
              align: TextAlign.right,
              isBold: true,
            ),
            // Addendum
            _tdText(''),
            _tdText(
              _fmtRupiahNoPrefix(
                report.totalAddendumHarga,
                forceDecimals: true,
              ),
              align: TextAlign.right,
              isBold: true,
            ),
            _tdText(
              report.totalAddendumBobot.toStringAsFixed(3),
              align: TextAlign.right,
              isBold: true,
            ),
            // Tambah
            _tdText(''),
            _tdText(
              _fmtRupiahNoPrefix(report.totalTambahHarga, forceDecimals: true),
              align: TextAlign.right,
              isBold: true,
            ),
            _tdText(
              report.totalTambahBobot.toStringAsFixed(3),
              align: TextAlign.right,
              isBold: true,
            ),
            // Kurang
            _tdText(''),
            _tdText(
              _fmtRupiahNoPrefix(report.totalKurangHarga, forceDecimals: true),
              align: TextAlign.right,
              isBold: true,
            ),
            _tdText(
              report.totalKurangBobot.toStringAsFixed(3),
              align: TextAlign.right,
              isBold: true,
            ),
            _tdText(''),
          ],
        ),

        // ─── SUMMARY FOOTER ROW 2: DIBULATKAN ───
        TableRow(
          decoration: const BoxDecoration(color: headerBgColor),
          children: [
            _tdText(''),
            _tdText(''),
            _tdText(
              'Jumlah Total Harga Pekerjaan ( Dibulatkan )',
              isBold: true,
            ),
            _tdText(''),
            _tdText(''),
            // Baseline (Kontrak Awal Dibulatkan)
            _tdText(''),
            _tdText(
              _fmtRupiahNoPrefix(report.totalDibulatkan, forceDecimals: true),
              align: TextAlign.right,
              isBold: true,
            ),
            _tdText(''),
            // Addendum (Addendum Dibulatkan)
            _tdText(''),
            _tdText(
              _fmtRupiahNoPrefix(report.totalDibulatkan, forceDecimals: true),
              align: TextAlign.right,
              isBold: true,
            ),
            _tdText(''),
            // Tambah
            _tdText(''),
            _tdText(''),
            _tdText(''),
            // Kurang
            _tdText(''),
            _tdText(''),
            _tdText(''),
            _tdText(''),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    final tglStr =
        addendumData['tanggalAddendum']?.toString().isNotEmpty == true
        ? addendumData['tanggalAddendum']
        : 'Agustus 2026';

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 60),
            child: Text(
              'Purbalingga, $tglStr',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kiri: PPK / DPU-PR
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Column(
                children: [
                  const Text(
                    'Kepala DPU-PR Kabupaten Purbalingga',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Selaku Pejabat Penandatanganan Kontrak',
                    style: TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                  const SizedBox(height: 54),
                  Text(
                    kegiatan.penggunaAnggaran.isNotEmpty
                        ? kegiatan.penggunaAnggaran
                        : 'DRAJAT UJI WAKHYONO, S.T., M.T',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const Text(
                    'NIP. 19711111 199803 1 008',
                    style: TextStyle(fontSize: 9.5),
                  ),
                ],
              ),
            ),

            // Kanan: Kontraktor Pelaksana
            Padding(
              padding: const EdgeInsets.only(right: 40),
              child: Column(
                children: [
                  const Text(
                    'Kontraktor Pelaksana',
                    style: TextStyle(fontSize: 10.5, color: Colors.black87),
                  ),
                  Text(
                    kegiatan.kontraktor.isNotEmpty
                        ? kegiatan.kontraktor
                        : 'CV. DIVAN INSAN CEMERLANG',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 54),
                  Text(
                    kegiatan.direkturPenyedia.isNotEmpty
                        ? kegiatan.direkturPenyedia
                        : 'NURKHOLIS WIDIANTO',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const Text('Direktur', style: TextStyle(fontSize: 9.5)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _th(String text, {double? height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 8.0,
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
    Color color = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
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
}
