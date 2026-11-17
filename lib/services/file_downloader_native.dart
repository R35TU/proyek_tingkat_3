import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Unduh berkas dari [url] (mis. Cloudflare R2) ke penyimpanan aplikasi
/// lalu langsung dibuka dengan aplikasi pendamping (OpenFilex).
Future<void> downloadAndOpenRemoteImpl(String url, String fileName) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Gagal mengunduh berkas (HTTP ${response.statusCode})');
  }
  final dir = await getApplicationDocumentsDirectory();
  final safe = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final file = File('${dir.path}/proyek_dokumen/$safe');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(response.bodyBytes);
  await OpenFilex.open(file.path);
}

/// Native: pembukaan tab browser tidak berlaku — gunakan
/// [downloadAndOpenRemote] (unduh lalu buka via OpenFilex).
Future<void> openRemoteInNewTabImpl(String url) async {
  throw UnsupportedError('openRemoteInNewTab hanya untuk web');
}
