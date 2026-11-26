import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_navigation_stub.dart'
    if (dart.library.js_interop) 'web_navigation_web.dart'
    if (dart.library.html) 'web_navigation_web.dart';

/// Buka landing page HTML (lapakdir.com/landing/index.html) saat di web.
void navigateToWebLanding() {
  if (kIsWeb) {
    navigateToWebLandingImpl();
  }
}

/// Ganti URL browser tanpa menambah entri history (untuk inisialisasi/koreksi).
void replaceWebUrl(String path) {
  if (kIsWeb) {
    replaceWebUrlImpl(path);
  }
}

/// Tambahkan entri baru ke browser history (agar tombol Back bekerja).
void pushWebUrl(String path) {
  if (kIsWeb) {
    pushWebUrlImpl(path);
  }
}

/// Ambil rute hash browser saat ini di web.
String getInitialWebRoute() {
  if (kIsWeb) {
    return getInitialWebRouteImpl();
  }
  return '/';
}

/// Mendaftarkan listener popstate browser (Back/Forward button).
void listenPopState(void Function(String route) callback) {
  if (kIsWeb) {
    listenPopStateImpl(callback);
  }
}

/// Hapus listener popstate.
void disposePopState() {
  if (kIsWeb) {
    disposePopStateImpl();
  }
}
