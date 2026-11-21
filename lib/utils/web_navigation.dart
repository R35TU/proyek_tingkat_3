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

/// Ganti URL browser tanpa menambah entri tumpukan riwayat (mencegah loop back).
void replaceWebUrl(String path) {
  if (kIsWeb) {
    replaceWebUrlImpl(path);
  }
}


