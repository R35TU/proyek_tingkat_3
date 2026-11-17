/// Stub untuk platform yang tidak didukung (seharusnya tidak pernah terpilih).
Future<void> downloadAndOpenRemote(String url, String fileName) async {
  throw UnsupportedError('downloadAndOpenRemote tidak didukung di platform ini');
}
