import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Cache LRU terikat untuk hasil decode base64 gambar & tanda tangan agar
/// rebuild widget tidak mengulang `base64Decode` maupun mengganti identitas `Uint8List`.
class ImageMemoryCache {
  static const int _maxEntries = 80;
  static final LinkedHashMap<String, Uint8List> _cache =
      LinkedHashMap<String, Uint8List>();

  /// Mengembalikan byte gambar ter-cache untuk data URI / string base64 [source],
  /// atau `null` bila format tidak valid.
  static Uint8List? decodeBase64(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return null;

    final existing = _cache.remove(trimmed);
    if (existing != null) {
      // Perbarui urutan LRU agar entri aktif tetap di cache.
      _cache[trimmed] = existing;
      return existing;
    }

    try {
      final commaIdx = trimmed.indexOf(',');
      final payload =
          commaIdx != -1 ? trimmed.substring(commaIdx + 1).trim() : trimmed;
      final bytes = base64Decode(payload);
      if (_cache.length >= _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[trimmed] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

/// Membangun widget gambar (URL jaringan atau base64) dengan cache decode memori
/// dan batas resolusi decode opsional ([cacheWidth]/[cacheHeight]) untuk menekan RAM & jank.
Widget buildCachedImageWidget(
  String source, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  int? cacheWidth,
  int? cacheHeight,
  Widget? errorWidget,
}) {
  final fallback =
      errorWidget ??
      const Center(
        child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
      );

  if (source.startsWith('http')) {
    return Image.network(
      source,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  final bytes = ImageMemoryCache.decodeBase64(source);
  if (bytes == null) {
    return errorWidget ??
        const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        );
  }

  return Image.memory(
    bytes,
    fit: fit,
    width: width,
    height: height,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    gaplessPlayback: true,
    errorBuilder: (context, error, stackTrace) => fallback,
  );
}
