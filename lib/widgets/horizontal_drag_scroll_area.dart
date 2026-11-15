import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class HorizontalDragScrollArea extends StatefulWidget {
  const HorizontalDragScrollArea({super.key, required this.child});

  final Widget child;

  @override
  State<HorizontalDragScrollArea> createState() =>
      _HorizontalDragScrollAreaState();
}

class _HorizontalDragScrollAreaState extends State<HorizontalDragScrollArea> {
  static const double _dragThreshold = 5.0;

  Offset? _pointerDownPosition;
  int? _activePointer;
  bool _isDragging = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.mouse ||
        (event.buttons & kPrimaryMouseButton) == 0) {
      return;
    }

    _activePointer = event.pointer;
    _pointerDownPosition = event.position;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activePointer != event.pointer ||
        _pointerDownPosition == null ||
        _isDragging) {
      return;
    }

    final delta = event.position - _pointerDownPosition!;
    if (delta.dx.abs() <= _dragThreshold || delta.dx.abs() <= delta.dy.abs()) {
      return;
    }

    setState(() {
      _isDragging = true;
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    if (_activePointer != event.pointer) return;

    _activePointer = null;
    _pointerDownPosition = null;
    if (_isDragging) {
      setState(() {
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scrollBehavior = ScrollConfiguration.of(context);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        gestureSettings: const DeviceGestureSettings(touchSlop: _dragThreshold),
      ),
      child: ScrollConfiguration(
        behavior: scrollBehavior.copyWith(
          dragDevices: {...scrollBehavior.dragDevices, PointerDeviceKind.mouse},
          scrollbars: false,
        ),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerEnd,
          onPointerCancel: _handlePointerEnd,
          child: MouseRegion(
            cursor: _isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
