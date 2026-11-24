import 'dart:html' as html;
import 'package:http/http.dart' as http;

/// Web: memicu unduhan berkas dari [url] via browser.
/// Mengambil bytes via http.get untuk membuat Blob URL agar atribut download
/// tidak diabaikan oleh browser karena batasan cross-origin.
Future<void> downloadAndOpenRemoteImpl(String url, String fileName) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final blob = html.Blob([response.bodyBytes]);
      final blobUrl = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: blobUrl)
        ..setAttribute('download', fileName)
        ..click();
      anchor.remove();
      Future.delayed(const Duration(seconds: 5), () {
        html.Url.revokeObjectUrl(blobUrl);
      });
      return;
    }
  } catch (_) {
    // Fallback ke direct anchor click bila CORS memblokir http.get
  }
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..setAttribute('target', '_blank')
    ..click();
  anchor.remove();
}

/// Web: membuka [url] langsung di tab baru — PDF/gambar tampil di viewer
/// bawaan browser, tanpa unduhan, tanpa file lokal.
Future<void> openRemoteInNewTabImpl(String url) async {
  html.window.open(url, '_blank');
}
