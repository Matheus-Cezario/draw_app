import 'dart:ui' as ui;

import 'tool.dart';

/// Shared behaviour of the freehand tools: collect points, draw a smoothed
/// path. Subclasses only decide how the stroke looks.
abstract class StrokeTool extends Tool {
  StrokeTool(super.host);

  final List<ui.Offset> _points = [];
  Future<void>? _pendingCommit;

  /// Builds the paint used for the current stroke.
  ui.Paint buildPaint();

  @override
  void onDown(ui.Offset point) {
    _points
      ..clear()
      ..add(point);
    host.requestRepaint();
  }

  @override
  void onMove(ui.Offset point) {
    _points.add(point);
    host.requestRepaint();
  }

  @override
  Future<void> onUp() async {
    if (_points.isEmpty) return;
    final layer = host.activeLayer;
    final snapshot = List<ui.Offset>.of(_points);
    final paint = buildPaint();
    _points.clear();
    // Keep painting the stroke live until the baked image replaces it.
    _baking = (snapshot, paint);
    final commit = host.commitLayer(layer, (c) => _draw(c, snapshot, paint));
    _pendingCommit = commit;
    await commit;
    if (identical(_pendingCommit, commit)) _baking = null;
    host.requestRepaint();
  }

  (List<ui.Offset>, ui.Paint)? _baking;

  @override
  void onCancel() {
    _points.clear();
    host.requestRepaint();
  }

  @override
  void paintLive(ui.Canvas canvas) {
    if (_points.isNotEmpty) {
      _draw(canvas, _points, buildPaint());
    } else if (_baking != null) {
      _draw(canvas, _baking!.$1, _baking!.$2);
    }
  }

  static void _draw(ui.Canvas canvas, List<ui.Offset> pts, ui.Paint paint) {
    if (pts.length < 3) {
      final fill = ui.Paint()
        ..color = paint.color
        ..blendMode = paint.blendMode
        ..maskFilter = paint.maskFilter;
      final p = pts.first;
      canvas.drawCircle(p, paint.strokeWidth / 2, fill);
      if (pts.length == 2) {
        canvas.drawCircle(pts.last, paint.strokeWidth / 2, fill);
        canvas.drawLine(pts.first, pts.last, paint);
      }
      return;
    }
    final path = ui.Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(path, paint);
  }
}

ui.Paint _basePaint(ToolHost host, double width) => ui.Paint()
  ..style = ui.PaintingStyle.stroke
  ..strokeCap = ui.StrokeCap.round
  ..strokeJoin = ui.StrokeJoin.round
  ..strokeWidth = width
  ..isAntiAlias = true;

/// Soft, wide brush.
class BrushTool extends StrokeTool {
  BrushTool(super.host);

  @override
  ui.Paint buildPaint() => _basePaint(host, host.size)
    ..color = host.color.withValues(alpha: host.opacity)
    ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, host.size * 0.12);
}

/// Hard-edged, thinner stroke with a slight transparency, like graphite.
class PencilTool extends StrokeTool {
  PencilTool(super.host);

  @override
  ui.Paint buildPaint() => _basePaint(host, (host.size * 0.4).clamp(1, 200))
    ..color = host.color.withValues(alpha: host.opacity * 0.85);
}

/// Clears pixels of the active layer.
class EraserTool extends StrokeTool {
  EraserTool(super.host);

  @override
  ui.Paint buildPaint() => _basePaint(host, host.size)
    ..blendMode = ui.BlendMode.clear
    ..color = const ui.Color(0xFF000000);
}
