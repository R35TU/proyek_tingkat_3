import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service Object Storage untuk Cloudflare R2 (S3-Compatible API).
///
/// Digunakan untuk menyimpan:
/// - Foto & tanda tangan laporan harian (`laporan-harian/{contractId}/{kegiatanId}/`)
/// - PDF laporan harian, mingguan, bulanan (`laporan-pdf/`)
/// - Berkas administrasi proyek / dokumen (`dokumen/`)
/// - Berkas installer APK (`apk/`)
class StorageService {
  StorageService._();

  static const String accessKeyId = '567c333e5455296bbed937215bd7a41a';
  static const String secretAccessKey =
      '33ff3f872e12c1ee2e1d26cfee8ff54283a54efcc6b12d3c59e3d1ac0cd25127';
  static const String endpoint =
      'ee37555d28507d9000c5c226461a5ca0.r2.cloudflarestorage.com';
  static const String bucket = 'lapakdir-media';
  static const String region = 'auto';
  static const String publicBaseUrl =
      'https://pub-8e92a1d103164d3182dd4796ffe1ce9a.r2.dev';

  /// Menghasilkan URL publik untuk file di bucket R2
  static String getPublicUrl(String remotePath) {
    final cleanPath = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
    return '$publicBaseUrl/$cleanPath';
  }

  /// Mengunggah data bytes (Uint8List) langsung ke Cloudflare R2 menggunakan S3 Signature V4.
  /// Mengembalikan URL publik file yang berhasil diunggah.
  static Future<String> uploadBytes({
    required Uint8List bytes,
    required String remotePath,
    String contentType = 'application/octet-stream',
  }) async {
    final cleanKey = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
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
    final cleanKey = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
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
