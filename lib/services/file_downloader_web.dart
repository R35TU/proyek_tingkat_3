import 'dart:html' as html;

/// Web: memicu unduhan berkas dari [url] via browser.
Future<void> downloadAndOpenRemote(String url, String fileName) async {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  anchor.remove();
}

/// Web: membuka [url] langsung di tab baru — PDF/gambar tampil di viewer
/// bawaan browser, tanpa unduhan, tanpa file lokal.
Future<void> openRemoteInNewTabImpl(String url) async {
  html.window.open(url, '_blank');
}
