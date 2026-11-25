import 'dart:html' as html;

/// Navigasi langsung ke landing page HTML di web.
void navigateToWebLandingImpl() {
  try {
    html.window.location.href = '/landing/index.html';
  } catch (_) {}
}

/// Ganti entri URL pada history browser tanpa push baru.
void replaceWebUrlImpl(String path) {
  try {
    html.window.history.replaceState(null, '', path);
  } catch (_) {}
}

/// Mengambil rute web saat ini dari window.location.hash.
String getInitialWebRouteImpl() {
  try {
    final hash = html.window.location.hash; // misal "#/detail-kontrak?id=123&tab=1"
    if (hash.startsWith('#/')) {
      return hash.substring(1); // "/detail-kontrak?id=123&tab=1"
    }
    if (hash.startsWith('#')) {
      final sub = hash.substring(1);
      return sub.startsWith('/') ? sub : '/$sub';
    }
  } catch (_) {}
  return '/';
}


