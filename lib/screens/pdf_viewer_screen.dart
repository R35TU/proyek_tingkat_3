import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:tata_saka_app/services/pdf_report_service.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final Future<Uint8List> Function() buildPdf;
  final String fileName;
  final PdfPageFormat pageFormat;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.buildPdf,
    required this.fileName,
    this.pageFormat = PdfPageFormat.a4,
  });

  Future<void> _handleDownload(BuildContext context, Uint8List bytes) async {
    final safeFileName = fileName.endsWith('.pdf') ? fileName : '$fileName.pdf';

    if (kIsWeb) {
      // Di Web, gunakan Printing.sharePdf agar otomatis terunduh melalui browser
      await Printing.sharePdf(bytes: bytes, filename: safeFileName);
    } else {
      // Di Mobile (Android/iOS), gunakan service penyimpanan lokal
      if (context.mounted) {
        await PdfReportService.downloadAndOpenPdf(
          context: context,
          bytes: bytes,
          fileName: safeFileName,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Simpan / Buka File PDF',
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () async {
              try {
                final bytes = await buildPdf();
                if (context.mounted) {
                  await _handleDownload(context, bytes);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menyimpan PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => buildPdf(),
        initialPageFormat: pageFormat,
        pdfFileName: fileName,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        maxPageWidth: 700,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text(
                'Menyiapkan Pratinjau Dokumen PDF...',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
        onError: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat pratinjau PDF: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
        actions: [
          PdfPreviewAction(
            icon: const Icon(Icons.download_rounded),
            onPressed: (context, buildPdfCallback, previewPageFormat) async {
              try {
                final bytes = await buildPdfCallback(previewPageFormat);
                if (context.mounted) {
                  await _handleDownload(context, bytes);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal mengunduh PDF: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
