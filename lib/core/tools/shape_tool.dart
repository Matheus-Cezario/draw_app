import 'dart:ui' as ui;

import 'tool.dart';

enum ShapeKind { line, rectangle, ellipse }

/// Draws a line, rectangle or ellipse from the drag start to the drag end.
class ShapeTool extends Tool {
  ShapeTool(super.host, this.kind);

  final ShapeKind kind;
  ui.Offset? _start;
  ui.Offset? _end;
  ({ui.Offset a, ui.Offset b})? _baking;

  @override
  void onDown(ui.Offset point) {
    _start = point;
    _end = point;
    host.requestRepaint();
  }

  @override
  void onMove(ui.Offset point) {
    _end = point;
    host.requestRepaint();
  }

  @override
  Future<void> onUp() async {
    final a = _start, b = _end;
    if (a == null || b == null) return;
    _start = _end = null;
    final paint = _paint();
    _baking = (a: a, b: b);
    await host.commitLayer(host.activeLayer, (c) => _draw(c, a, b, paint));
    _baking = null;
    host.requestRepaint();
  }

  @override
  void onCancel() {
    _start = _end = null;
    host.requestRepaint();
  }

  ui.Paint _paint() => ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round
    ..strokeWidth = host.size
    ..isAntiAlias = true
    ..color = host.color.withValues(alpha: host.opacity);

  void _draw(ui.Canvas canvas, ui.Offset a, ui.Offset b, ui.Paint paint) {
    switch (kind) {
      case ShapeKind.line:
        canvas.drawLine(a, b, paint);
      case ShapeKind.rectangle:
        canvas.drawRect(ui.Rect.fromPoints(a, b), paint);
      case ShapeKind.ellipse:
        canvas.drawOval(ui.Rect.fromPoints(a, b), paint);
    }
  }

  @override
  void paintLive(ui.Canvas canvas) {
    final a = _start ?? _baking?.a, b = _end ?? _baking?.b;
    if (a != null && b != null) _draw(canvas, a, b, _paint());
  }
}
