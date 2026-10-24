import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/raster/compositor.dart';
import 'editor_controller.dart';
import '../../core/ui/app_colors.dart';

/// Draws the document and turns pointer events into tool calls.
///
/// One finger (or a stylus/mouse) draws; two fingers pan and zoom; the mouse
/// wheel zooms on desktop.
class CanvasView extends StatefulWidget {
  const CanvasView({super.key, required this.controller});

  final EditorController controller;

  @override
  State<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends State<CanvasView> {
  final Map<int, Offset> _pointers = {};
  double _scale = 1;
  Offset _offset = Offset.zero;
  Size? _fittedFor;
  bool _drawing = false;

  EditorController get _c => widget.controller;

  void _fit(Size viewport) {
    if (_fittedFor == viewport) return;
    _fittedFor = viewport;
    final doc = _c.document;
    _scale = math.min(viewport.width / doc.width, viewport.height / doc.height) * 0.95;
    _offset = Offset(
      (viewport.width - doc.width * _scale) / 2,
      (viewport.height - doc.height * _scale) / 2,
    );
  }

  Offset _toDoc(Offset local) => (local - _offset) / _scale;

  void _down(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1) {
      _drawing = true;
      _c.tool.onDown(_toDoc(e.localPosition));
    } else if (_drawing) {
      // A second finger landed: this is a pan/zoom, not a stroke.
      _drawing = false;
      _c.tool.onCancel();
    }
  }

  void _move(PointerMoveEvent e) {
    final previous = Map<int, Offset>.of(_pointers);
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_drawing && _pointers.length == 1) {
      _c.tool.onMove(_toDoc(e.localPosition));
    } else if (_pointers.length >= 2) {
      final ids = _pointers.keys.take(2).toList();
      final p0 = previous[ids[0]]!, p1 = previous[ids[1]]!;
      final q0 = _pointers[ids[0]]!, q1 = _pointers[ids[1]]!;
      final oldDist = (p0 - p1).distance;
      final newDist = (q0 - q1).distance;
      if (oldDist < 1) return;
      final newScale = (_scale * newDist / oldDist).clamp(0.05, 40.0);
      final oldCenter = (p0 + p1) / 2, newCenter = (q0 + q1) / 2;
      setState(() {
        _offset = newCenter - (oldCenter - _offset) * (newScale / _scale);
        _scale = newScale;
      });
    }
  }

  void _up(PointerEvent e) {
    final wasDrawing = _drawing && _pointers.length == 1;
    _pointers.remove(e.pointer);
    if (wasDrawing) {
      _drawing = false;
      if (e is PointerCancelEvent) {
        _c.tool.onCancel();
      } else {
        _c.tool.onUp();
      }
    }
    if (_pointers.isEmpty) _drawing = false;
  }

  void _signal(PointerSignalEvent e) {
    if (e is! PointerScrollEvent) return;
    final factor = math.exp(-e.scrollDelta.dy / 300);
    final newScale = (_scale * factor).clamp(0.05, 40.0);
    setState(() {
      _offset = e.localPosition - (e.localPosition - _offset) * (newScale / _scale);
      _scale = newScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _fit(constraints.biggest);
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _down,
        onPointerMove: _move,
        onPointerUp: _up,
        onPointerCancel: _up,
        onPointerSignal: _signal,
        child: ClipRect(
          child: CustomPaint(
            size: Size.infinite,
            painter: _DocumentPainter(_c, _scale, _offset),
          ),
        ),
      );
    });
  }
}

class _DocumentPainter extends CustomPainter {
  _DocumentPainter(this.controller, this.scale, this.offset)
      : super(repaint: Listenable.merge([controller, controller.repaint]));

  final EditorController controller;
  final double scale;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final doc = controller.document;
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.canvasBackdrop);
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);
    final page = Rect.fromLTWH(0, 0, doc.width.toDouble(), doc.height.toDouble());
    canvas.drawShadow(Path()..addRect(page), const Color(0xFF000000), 6 / scale, false);
    canvas.drawRect(page, Paint()..color = Colors.white);
    canvas.clipRect(page);
    paintDocument(
      canvas,
      doc,
      overLayer: controller.activeLayer,
      paintOverLayer: (c) {
        controller.tool.paintLive(c);
        controller.paintFillSpread(c, controller.activeLayer);
      },
    );
    controller.tool.paintOverlay(canvas, scale);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DocumentPainter old) =>
      old.scale != scale || old.offset != offset || old.controller != controller;
}
