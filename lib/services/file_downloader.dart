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
