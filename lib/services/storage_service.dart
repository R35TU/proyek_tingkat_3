import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service Object Storage untuk Sumopod/Cloudeka (S3-Compatible API).
///
/// Digunakan untuk menyimpan:
/// - Foto & tanda tangan laporan harian (`laporan-harian/{contractId}/{kegiatanId}/`)
/// - PDF laporan harian, mingguan, bulanan (`laporan-pdf/`)
/// - Berkas administrasi proyek / dokumen (`dokumen/`)
/// - Berkas installer APK (`apk/`)
class StorageService {
  StorageService._();

  // ─── KREDENSIAL (WAJIB lewat --dart-define, TIDAK ditulis di source) ───
  //
  // Jalankan build/run dengan:
  //   --dart-define=R2_ACCESS_KEY_ID=... --dart-define=R2_SECRET_ACCESS_KEY=...
  // atau pakai file config lokal (gitignored):
  //   --dart-define-from-file=sumopod_local.json
  //
  // Kredensial lama yang pernah di-commit sudah DI-ROTATE di Cloudflare —
  // kunci baru HANYA ada di GitHub Secrets (CI) & r2_local.json (lokal).
  static const String accessKeyId = String.fromEnvironment('R2_ACCESS_KEY_ID');
  static const String secretAccessKey =
      String.fromEnvironment('R2_SECRET_ACCESS_KEY');

  /// true bila kredensial sudah tersedia di build ini.
  static bool get hasCredentials =>
      accessKeyId.isNotEmpty && secretAccessKey.isNotEmpty;

  /// Pesan kesalahan bila kredensial belum dikonfigurasi.
  static String get _missingCredentialsMessage =>
      '[StorageService] Kredensial R2 belum dikonfigurasi. Jalankan build dengan '
      '--dart-define=R2_ACCESS_KEY_ID=... --dart-define=R2_SECRET_ACCESS_KEY=... '
      '(lokal: gunakan --dart-define-from-file=sumopod_local.json; CI: GitHub Secrets '
      'R2_ACCESS_KEY_ID & R2_SECRET_ACCESS_KEY).';

  static const String endpoint = 'kencana.basic.box.cloudeka.id';
  static const String bucket = 'tatasaka-media-rw4mpj';
  static const String region = 'kencana';
  static const String publicBaseUrl =
      'https://kencana.basic.box.cloudeka.id/tatasaka-media-rw4mpj';

  /// Menghasilkan URL publik untuk file di object storage
  static String getPublicUrl(String remotePath) {
    final cleanPath = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
    return '$publicBaseUrl/$cleanPath';
  }

  /// Bersihkan kunci objek: hanya [a-zA-Z0-9._/-] yang diizinkan.
  /// Spasi, kurung, dan karakter lain merusak URL & tanda tangan SigV4.
  /// (Nama asli tetap utuh di field `name` metadata untuk tampilan.)
  static String _safeObjectKey(String key) {
    final clean = key.startsWith('/') ? key.substring(1) : key;
    return clean.replaceAll(RegExp(r'[^a-zA-Z0-9._\-/]'), '_');
  }

  /// Sanitasi SELURUH path objek per-segment — slash pemisah folder
  /// dipertahankan, isi tiap segment dibersihkan.
  /// Contoh: `dokumen/TEST 1/SPK/laporan (1).pdf` → `dokumen/TEST_1/SPK/laporan__1_.pdf`
  static String safeObjectPath(String path) {
    final segments = path.split('/');
    final cleaned = segments
        .map((s) => s.replaceAll(RegExp(r'[^a-zA-Z0-9._\-]'), '_'))
        .where((s) => s.isNotEmpty)
        .toList();
    return cleaned.join('/');
  }

  /// Mendeteksi Content-Type (MIME) dari nama berkas atau ekstensi.
  static String detectContentType(String nameOrExt) {
    final clean = nameOrExt.split('?').first.split('#').first;
    final ext = clean.contains('.')
        ? clean.split('.').last.toLowerCase().trim()
        : clean.toLowerCase().trim();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';
      case '7z':
        return 'application/x-7z-compressed';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'img':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Mengunggah data bytes (Uint8List) langsung ke Cloudflare R2 menggunakan S3 Signature V4.
  /// Mengembalikan URL publik file yang berhasil diunggah.
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String remotePath,
    String contentType = 'application/octet-stream',
  }) async {
    if (!hasCredentials) {
      throw StateError(_missingCredentialsMessage);
    }
    final cleanKey = _safeObjectKey(remotePath);
    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = amzDate.substring(0, 8);

    final payloadHash = sha256.convert(bytes).toString();

    final method = 'PUT';
    final canonicalUri = '/$bucket/$cleanKey';
    final canonicalQuerystring = '';
    final canonicalHeaders =
        'host:$endpoint\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest =
        '$method\n$canonicalUri\n$canonicalQuerystring\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    const algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final stringToSign =
        '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

    final kDate = _hmacSha256(utf8.encode('AWS4$secretAccessKey'), dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, 's3');
    final kSigning = _hmacSha256(kService, 'aws4_request');
    final signature = _hmacSha256Hex(kSigning, stringToSign);

    final authorizationHeader =
        '$algorithm Credential=$accessKeyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    final uri = Uri.parse('https://$endpoint/$bucket/$cleanKey');
    final response = await http.put(
      uri,
      headers: {
        'Host': endpoint,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': payloadHash,
        'Authorization': authorizationHeader,
        'Content-Type': contentType,
        'Content-Length': bytes.length.toString(),
      },
      body: bytes,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('[StorageService] Sukses unggah ke R2: $cleanKey');
      return getPublicUrl(cleanKey);
    } else {
      debugPrint('[StorageService] Gagal unggah (${response.statusCode}): ${response.body}');
      throw Exception(
        'Gagal mengunggah berkas ke Cloudflare R2 (HTTP ${response.statusCode})',
      );
    }
  }

  /// Mengunggah gambar berformat base64 (misal dari ImagePicker / SignaturePad) ke R2.
  static Future<String> uploadBase64Image({
    required String base64String,
    required String remotePath,
  }) async {
    String cleanBase64 = base64String;
    String contentType = 'image/png';

    if (base64String.contains(',')) {
      final parts = base64String.split(',');
      final header = parts[0];
      cleanBase64 = parts[1];
      if (header.contains('image/jpeg') || header.contains('image/jpg')) {
        contentType = 'image/jpeg';
      } else if (header.contains('image/png')) {
        contentType = 'image/png';
      } else if (header.contains('application/pdf')) {
        contentType = 'application/pdf';
      }
    }

    final bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
    return uploadBytes(
      bytes: bytes,
      remotePath: remotePath,
      contentType: contentType,
    );
  }

  /// Hapus file dari Cloudflare R2
  static Future<bool> deleteFile(String remotePath) async {
    if (!hasCredentials) {
      debugPrint(_missingCredentialsMessage);
      return false;
    }
    final cleanKey = _safeObjectKey(remotePath);
    final now = DateTime.now().toUtc();
    final amzDate = _formatAmzDate(now);
    final dateStamp = amzDate.substring(0, 8);

    const payloadHash =
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

    final method = 'DELETE';
    final canonicalUri = '/$bucket/$cleanKey';
    final canonicalQuerystring = '';
    final canonicalHeaders =
        'host:$endpoint\nx-amz-content-sha256:$payloadHash\nx-amz-date:$amzDate\n';
    const signedHeaders = 'host;x-amz-content-sha256;x-amz-date';

    final canonicalRequest =
        '$method\n$canonicalUri\n$canonicalQuerystring\n$canonicalHeaders\n$signedHeaders\n$payloadHash';

    const algorithm = 'AWS4-HMAC-SHA256';
    final credentialScope = '$dateStamp/$region/s3/aws4_request';
    final stringToSign =
        '$algorithm\n$amzDate\n$credentialScope\n${sha256.convert(utf8.encode(canonicalRequest))}';

    final kDate = _hmacSha256(utf8.encode('AWS4$secretAccessKey'), dateStamp);
    final kRegion = _hmacSha256(kDate, region);
    final kService = _hmacSha256(kRegion, 's3');
    final kSigning = _hmacSha256(kService, 'aws4_request');
    final signature = _hmacSha256Hex(kSigning, stringToSign);

    final authorizationHeader =
        '$algorithm Credential=$accessKeyId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signature';

    final uri = Uri.parse('https://$endpoint/$bucket/$cleanKey');
    final response = await http.delete(
      uri,
      headers: {
        'Host': endpoint,
        'x-amz-date': amzDate,
        'x-amz-content-sha256': payloadHash,
        'Authorization': authorizationHeader,
      },
    );

    return response.statusCode >= 200 && response.statusCode < 300;
  }

  // ─── HELPER SIGV4 CRYPTO ───

  static List<int> _hmacSha256(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).bytes;
  }

  static String _hmacSha256Hex(List<int> key, String data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(utf8.encode(data)).toString();
  }

  static String _formatAmzDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }
}
