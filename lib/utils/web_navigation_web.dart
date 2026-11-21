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

/// Tambah entri riwayat browser agar tombol Back browser/device memicu navigasi internal.
void pushWebHistoryImpl(String path) {
  try {
    html.window.history.pushState({'route': path}, '', path);
  } catch (_) {}
}

