// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Web: trigger a browser file download via Blob + AnchorElement.
Future<void> savePdfPlatform({
  required BuildContext context,
  required Uint8List bytes,
  required String fileName,
}) async {
  final sanitized = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  // ignore: unused_local_variable
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', sanitized)
    ..click();
  html.Url.revokeObjectUrl(url);

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: Colors.white, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text('PDF berhasil diunduh ke folder Downloads browser Anda.')),
        ],
      ),
      backgroundColor: Color(0xFF059669),
      duration: Duration(seconds: 4),
    ),
  );
}
