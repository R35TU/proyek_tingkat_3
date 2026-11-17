import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'clean_text_form_field.dart';

/// Widget Kanvas Tanda Tangan Digital interaktif
class SignaturePadWidget extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController roleController;
  final String? initialSignatureBase64;
  final ValueChanged<String?> onSignatureChanged;

  const SignaturePadWidget({
    super.key,
    required this.nameController,
    required this.roleController,
    this.initialSignatureBase64,
    required this.onSignatureChanged,
  });

  @override
  State<SignaturePadWidget> createState() => SignaturePadWidgetState();
}

class SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<List<Offset>> _strokes = [];
  String? _currentSignatureBase64;
  bool _isReSigning = false;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentSignatureBase64 = widget.initialSignatureBase64;
  }

  @override
  void didUpdateWidget(covariant SignaturePadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSignatureBase64 != oldWidget.initialSignatureBase64) {
      setState(() {
        _currentSignatureBase64 = widget.initialSignatureBase64;
      });
    }
  }

  bool get hasSignature =>
      (_currentSignatureBase64 != null && _currentSignatureBase64!.isNotEmpty) ||
      _strokes.isNotEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
      _currentSignatureBase64 = null;
      _isReSigning = true;
    });
    widget.onSignatureChanged(null);
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
      _exportStrokes();
    }
  }

  Future<void> _exportStrokes() async {
    if (_strokes.isEmpty) {
      _currentSignatureBase64 = null;
      widget.onSignatureChanged(null);
      setState(() {});
      return;
    }

    final RenderBox? box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size ?? const Size(360, 150);
    final width = size.width > 0 ? size.width : 360.0;
    final height = size.height > 0 ? size.height : 150.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    final painter = _SignaturePainter(strokes: _strokes);
    painter.paint(canvas, Size(width, height));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      final b64 = 'data:image/png;base64,${base64Encode(byteData.buffer.asUint8List())}';
      _currentSignatureBase64 = b64;
      widget.onSignatureChanged(b64);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final showExisting =
        _currentSignatureBase64 != null &&
        _currentSignatureBase64!.isNotEmpty &&
        !_isReSigning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Data Penandatangan (Nama & Jabatan)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CleanTextFormField(
                controller: widget.nameController,
                label: 'Nama Penandatangan *',
                hintText: 'Contoh: MISWANTO',
                isBold: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CleanTextFormField(
                controller: widget.roleController,
                label: 'Posisi / Jabatan *',
                hintText: 'Contoh: Inspector',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Kanvas Tanda Tangan
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            const Text(
              'Tanda Tangan Digital',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                letterSpacing: 0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasSignature ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: hasSignature ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: hasSignature ? const Color(0xFF059669) : const Color(0xFF9CA3AF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      hasSignature ? 'Tersedia' : 'Belum TTD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: hasSignature ? const Color(0xFF047857) : const Color(0xFF6B7280),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (!showExisting && _strokes.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: undo,
                    icon: const Icon(Icons.undo, size: 14, color: Color(0xFF4B5563)),
                    label: const Text('Urungkan', style: TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: clear,
                    icon: const Icon(Icons.refresh, size: 14, color: Color(0xFFEF4444)),
                    label: const Text('Hapus', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Display existing signature or interactive canvas
        if (showExisting)
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Stack(
              children: [
                Center(
                  child: _buildSignatureImage(_currentSignatureBase64!),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isReSigning = true;
                        _strokes.clear();
                      });
                    },
                    icon: const Icon(Icons.edit_outlined, size: 13, color: Colors.white),
                    label: const Text('Tanda Tangan Ulang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            key: _canvasKey,
            width: double.infinity,
            height: 150,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _strokes.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFFD1D5DB),
                width: _strokes.isNotEmpty ? 1.5 : 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Baseline guide line
                Positioned(
                  bottom: 34,
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 1,
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                if (_strokes.isEmpty)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Goreskan tanda tangan di sini menggunakan sentuhan / mouse',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),

                // Touch / Pan Gesture Detector
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    setState(() {
                      _strokes.add([details.localPosition]);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      if (_strokes.isNotEmpty) {
                        _strokes.last.add(details.localPosition);
                      }
                    });
                  },
                  onPanEnd: (_) {
                    _exportStrokes();
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(strokes: _strokes),
                    size: Size.infinite,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSignatureImage(String b64) {
    if (b64.startsWith('http')) {
      return Image.network(b64, fit: BoxFit.contain, height: 130);
    }
    try {
      String clean = b64;
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      final bytes = base64Decode(clean.trim());
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        height: 130,
      );
    } catch (_) {
      return const Center(
        child: Text('Tanda tangan tersimpan', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.8
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.4, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }

      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);
      for (int i = 1; i < stroke.length; i++) {
        final p0 = stroke[i - 1];
        final p1 = stroke[i];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
