import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Stub – should never be called directly.
/// Use [savePdfPlatform] from the correct conditional import.
Future<void> savePdfPlatform({
  required BuildContext context,
  required Uint8List bytes,
  required String fileName,
}) async {
  throw UnsupportedError('Platform not supported');
}
