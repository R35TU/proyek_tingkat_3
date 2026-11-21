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
