import 'dart:async';
import 'dart:html' as html;

/// Navigasi langsung ke landing page HTML di web.
void navigateToWebLandingImpl() {
  try {
    html.window.location.href = '/landing/index.html';
  } catch (_) {}
}

/// Ganti entri URL saat ini tanpa menambah history (untuk koreksi/inisialisasi).
void replaceWebUrlImpl(String path) {
  try {
    html.window.history.replaceState(null, '', path);
  } catch (_) {}
}

/// Tambahkan entri baru ke browser history (agar tombol Back bekerja).
void pushWebUrlImpl(String path) {
  try {
    // Jangan push jika URL sudah sama.
    final current = html.window.location.hash;
    final target = path.startsWith('/#') ? path.substring(1) : path;
    if (current == target) return;
    html.window.history.pushState(null, '', path);
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

StreamSubscription<html.PopStateEvent>? _popStateSub;

/// Mendaftarkan callback yang dipanggil saat user menekan Back/Forward browser.
/// Callback menerima path baru (tanpa '#').
void listenPopStateImpl(void Function(String route) callback) {
  _popStateSub?.cancel();
  _popStateSub = html.window.onPopState.listen((event) {
    callback(getInitialWebRouteImpl());
  });
}

void disposePopStateImpl() {
  _popStateSub?.cancel();
  _popStateSub = null;
}
