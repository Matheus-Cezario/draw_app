import 'dart:ui' as ui;

import '../raster/raster.dart';
import 'tool.dart';

/// Rectangular selection that can be dragged to move pixels of the active
/// layer. The moved pixels are baked when the user taps elsewhere, switches
/// tool or layer, or saves.
class SelectionTool extends Tool {
  SelectionTool(super.host);

  ui.Offset? _dragStart;
  ui.Offset? _dragNow;

  // Floating selection state.
  ui.Rect? _source; // where the pixels were lifted from
  ui.Image? _floating;
  ui.Offset _delta = ui.Offset.zero;
  bool _moving = false;
  bool _lifting = false;

  ui.Rect? get _currentRect => _source?.shift(_delta);

  @override
  void onDown(ui.Offset point) {
    if (_lifting) return;
    final rect = _currentRect;
    if (rect != null && rect.contains(point)) {
      _moving = true;
    } else {
      // Tap outside: bake what we have and start a new selection.
      finish();
      _dragStart = point;
      _dragNow = point;
    }
    _dragNow = point;
    host.requestRepaint();
  }

  ui.Offset? _lastMove;

  @override
  void onMove(ui.Offset point) {
    if (_moving) {
      final prev = _lastMove ?? _dragNow ?? point;
      _delta += point - prev;
      _lastMove = point;
      _dragNow = point;
    } else if (_dragStart != null) {
      _dragNow = point;
    }
    host.requestRepaint();
  }

  @override
  Future<void> onUp() async {
    _lastMove = null;
    if (_moving) {
      _moving = false;
      return;
    }
    final a = _dragStart, b = _dragNow;
    _dragStart = _dragNow = null;
    if (a == null || b == null) return;
    final doc = host.document;
    final rect = ui.Rect.fromPoints(a, b).intersect(
      ui.Rect.fromLTWH(0, 0, doc.width.toDouble(), doc.height.toDouble()),
    );
    final layerImage = host.activeLayer.image;
    if (rect.width < 4 || rect.height < 4 || layerImage == null) {
      host.requestRepaint();
      return;
    }
    _lifting = true;
    final snapped = ui.Rect.fromLTRB(
      rect.left.floorToDouble(),
      rect.top.floorToDouble(),
      rect.right.ceilToDouble(),
      rect.bottom.ceilToDouble(),
    );
    _floating = await composeImage(
      null,
      snapped.width.toInt(),
      snapped.height.toInt(),
      (c) {
        c.translate(-snapped.left, -snapped.top);
        c.drawImage(layerImage, ui.Offset.zero, ui.Paint());
      },
    );
    _source = snapped;
    _delta = ui.Offset.zero;
    _lifting = false;
    host.requestRepaint();
  }

  @override
  void onCancel() {
    _moving = false;
    _dragStart = _dragNow = null;
    host.requestRepaint();
  }

  @override
  Future<void> finish() async {
    final source = _source, floating = _floating;
    if (source == null || floating == null) return;
    final delta = _delta;
    _source = null;
    _floating = null;
    _delta = ui.Offset.zero;
    if (delta != ui.Offset.zero) {
      await host.commitLayer(host.activeLayer, (c) {
        _paintMoved(c, source, floating, delta);
      });
    }
    host.requestRepaint();
  }

  static void _paintMoved(
    ui.Canvas canvas,
    ui.Rect source,
    ui.Image floating,
    ui.Offset delta,
  ) {
    canvas.save();
    canvas.clipRect(source);
    canvas.drawPaint(ui.Paint()..blendMode = ui.BlendMode.clear);
    canvas.restore();
    canvas.drawImage(floating, source.topLeft + delta, ui.Paint());
  }

  @override
  void paintLive(ui.Canvas canvas) {
    final source = _source, floating = _floating;
    if (source != null && floating != null) {
      _paintMoved(canvas, source, floating, _delta);
    }
  }

  @override
  void paintOverlay(ui.Canvas canvas, double scale) {
    final rect = _currentRect ??
        (_dragStart != null && _dragNow != null
            ? ui.Rect.fromPoints(_dragStart!, _dragNow!)
            : null);
    if (rect == null) return;
    final stroke = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5 / scale
      ..color = const ui.Color(0xFF1E88E5);
    canvas.drawRect(rect, stroke);
    canvas.drawRect(
      rect,
      ui.Paint()..color = const ui.Color(0x151E88E5),
    );
  }
}
