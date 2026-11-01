import 'package:flutter/material.dart';

/// CleanTextFormField adalah TextFormField khusus yang:
/// 1. Otomatis menyembunyikan hintText saat kolom mendapatkan fokus (diklik / dipencet),
///    sehingga kursor tidak bertumpuk dengan teks petunjuk/placeholder.
/// 2. Menampilkan kembali hintText saat kolom kehilangan fokus (unfocused) dan masih kosong.
/// 3. Menjamin tampilan hintText tidak kontras berlebihan (abu-abu lembut & tidak bold),
///    meskipun style teks input diatur bold/hitam pekat.
class CleanTextFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool readOnly;
  final bool isBold;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;

  const CleanTextFormField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.hintStyle,
    this.style,
    this.decoration,
    this.readOnly = false,
    this.isBold = false,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.focusNode,
    this.validator,
  });

  @override
  State<CleanTextFormField> createState() => _CleanTextFormFieldState();
}

class _CleanTextFormFieldState extends State<CleanTextFormField> {
  FocusNode? _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant CleanTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  void _handleFocusChange() {
    if (_effectiveFocusNode.hasFocus != _isFocused) {
      if (mounted) {
        setState(() {
          _isFocused = _effectiveFocusNode.hasFocus;
        });
      }
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Saat kolom mendapatkan fokus (dipencet), hilangkan hintText agar bersih
    final effectiveHint = _isFocused ? null : widget.hintText;

    const defaultHintStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: Color(0xFF9CA3AF), // Abu-abu netral lembut (Tailwind Gray 400), tidak menusuk mata
    );

    final baseDec = widget.decoration ??
        InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: widget.readOnly ? const Color(0xFFF3F4F6) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1F2937), width: 1.5),
          ),
        );

    final inputWidget = TextFormField(
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
      readOnly: widget.readOnly,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: widget.style ??
          TextStyle(
            fontSize: 13,
            fontWeight: widget.isBold ? FontWeight.w600 : FontWeight.normal,
            color: widget.readOnly ? const Color(0xFF4B5563) : const Color(0xFF111827),
          ),
      decoration: baseDec.copyWith(
        hintText: effectiveHint,
        hintStyle: widget.hintStyle ?? defaultHintStyle,
      ),
    );

    if (widget.label != null && widget.label!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          inputWidget,
        ],
      );
    }

    return inputWidget;
  }
}
