/// Stub untuk platform yang tidak didukung (seharusnya tidak pernah terpilih).
Future<void> downloadAndOpenRemoteImpl(String url, String fileName) async {
  throw UnsupportedError('downloadAndOpenRemote tidak didukung di platform ini');
}

Future<void> openRemoteInNewTabImpl(String url) async {
  throw UnsupportedError('openRemoteInNewTab hanya untuk web');
}
