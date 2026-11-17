import 'dart:html' as html;

/// Web: memicu unduhan berkas dari [url] via browser.
Future<void> downloadAndOpenRemote(String url, String fileName) async {
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  anchor.remove();
}
