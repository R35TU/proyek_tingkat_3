import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Mobile/Desktop: save PDF to Documents directory and open it.
Future<void> savePdfPlatform({
  required BuildContext context,
  required Uint8List bytes,
  required String fileName,
}) async {
  final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final dir = await getApplicationDocumentsDirectory();
  final reportsDir = Directory('${dir.path}/laporan_pdf');
  if (!await reportsDir.exists()) {
    await reportsDir.create(recursive: true);
  }
  final file = File('${reportsDir.path}/$sanitized');
  await file.writeAsBytes(bytes, flush: true);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Dokumen PDF berhasil diunduh:\n${file.path.split(Platform.pathSeparator).last}'),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF059669),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Buka File',
        textColor: Colors.white,
        onPressed: () {
          OpenFilex.open(file.path);
        },
      ),
    ),
  );
}
