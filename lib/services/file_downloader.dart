import 'file_downloader_native.dart'
    if (dart.library.js_interop) 'file_downloader_web.dart'
    if (dart.library.html) 'file_downloader_web.dart';

/// Unduh dokumen dari [url] (mis. Cloudflare R2 / cdn.lapakdir.com) lalu buka:
/// - Native (Android/Windows) : disimpan ke penyimpanan aplikasi lalu dibuka.
/// - Web                      : memicu unduhan file via browser.
Future<void> downloadAndOpenRemote(String url, String fileName) =>
    downloadAndOpenRemoteImpl(url, fileName);

/// Web: buka [url] langsung di tab baru (viewer bawaan browser).
Future<void> openRemoteInNewTab(String url) => openRemoteInNewTabImpl(url);

/// Memastikan nama file memiliki ekstensi yang sesuai berdasarkan tipe/url.
String resolveDocFileName(String name, String type, [String? urlOrPath]) {
  if (RegExp(r'\.[a-zA-Z0-9]{2,5}$').hasMatch(name)) return name;
  if (urlOrPath != null && urlOrPath.contains('.')) {
    final clean = urlOrPath.split('?').first.split('#').first;
    final lastDot = clean.lastIndexOf('.');
    if (lastDot != -1) {
      final ext = clean.substring(lastDot);
      if (ext.length <= 6) return '$name$ext';
    }
  }
  final t = type.toUpperCase();
  if (t == 'IMG') return '$name.jpg';
  if (t == 'PDF') return '$name.pdf';
  if (t.isNotEmpty) return '$name.${type.toLowerCase()}';
  return '$name.pdf';
}

/// Menentukan apakah berkas bisa di-preview langsung di tab browser (PDF / Gambar).
bool isPreviewableInBrowser(String type, [String? urlOrPath]) {
  final t = type.toUpperCase();
  if (t == 'PDF' || t == 'IMG' || t == 'JPG' || t == 'JPEG' || t == 'PNG' || t == 'WEBP' || t == 'GIF') {
    return true;
  }
  if (urlOrPath != null && urlOrPath.contains('.')) {
    final clean = urlOrPath.split('?').first.split('#').first;
    final ext = clean.split('.').last.toLowerCase();
    if (const ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].contains(ext)) {
      return true;
    }
  }
  return false;
}
