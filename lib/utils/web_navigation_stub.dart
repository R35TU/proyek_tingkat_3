/// Implementasi stub untuk platform non-web.
void navigateToWebLandingImpl() {}

void replaceWebUrlImpl(String path) {}

void pushWebUrlImpl(String path) {}

String getInitialWebRouteImpl() => '/';

void listenPopStateImpl(void Function(String route) callback) {}

void disposePopStateImpl() {}
