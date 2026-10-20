import 'dart:math' as math;
import 'dart:ui';

/// Draws colouring-book line art in a 100 x 100 unit square.
///
/// Every shape is filled with white before its outline is stroked, so shapes
/// drawn later hide the lines of shapes behind them (like real drawings).
/// All outlines are closed, which is what makes the bucket tool work.
class Pen {
  Pen(this.canvas);

  final Canvas canvas;

  /// Outline thickness in drawing units (1.7 of 100 = a chunky kids' line).
  static const double lineWidth = 1.7;

  static final Paint _white = Paint()..color = const Color(0xFFFFFFFF);
  static final Paint _black = Paint()..color = const Color(0xFF000000);
  static final Paint _stroke = Paint()
    ..color = const Color(0xFF000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = lineWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Outline [path]; filled with white first unless [fill] is false.
  void shape(Path path, {bool fill = true}) {
    if (fill) canvas.drawPath(path, _white);
    canvas.drawPath(path, _stroke);
  }

  void oval(double cx, double cy, double rx, double ry) =>
      shape(Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2)));

  void circle(double cx, double cy, double r) => oval(cx, cy, r, r);

  void rect(double l, double t, double r, double b, [double radius = 0]) => shape(
        Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius))),
      );

  /// Polygon from a flat list: x1, y1, x2, y2, ...
  void poly(List<double> xy, {bool fill = true, bool close = true}) {
    final path = Path()..moveTo(xy[0], xy[1]);
    for (var i = 2; i < xy.length; i += 2) {
      path.lineTo(xy[i], xy[i + 1]);
    }
    if (close) path.close();
    shape(path, fill: fill);
  }

  void line(double x1, double y1, double x2, double y2) =>
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), _stroke);

  /// Stroke only, never closed or filled (whiskers, grass, details).
  void stroke(Path path) => canvas.drawPath(path, _stroke);

  /// Small solid black dot (eyes, knobs).
  void dot(double cx, double cy, [double r = 1.8]) =>
      canvas.drawCircle(Offset(cx, cy), r, _black);

  /// Solid black polygon (noses).
  void solid(List<double> xy) {
    final path = Path()..moveTo(xy[0], xy[1]);
    for (var i = 2; i < xy.length; i += 2) {
      path.lineTo(xy[i], xy[i + 1]);
    }
    path.close();
    canvas.drawPath(path, _black);
    canvas.drawPath(path, _stroke);
  }

  /// One outline around several overlapping shapes (clouds, bushes).
  void union(List<Path> parts) {
    var merged = parts.first;
    for (final part in parts.skip(1)) {
      merged = Path.combine(PathOperation.union, merged, part);
    }
    shape(merged);
  }

  /// Draws [draw] rotated by [degrees] around ([cx], [cy]).
  void rotated(double cx, double cy, double degrees, void Function() draw) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(degrees * math.pi / 180);
    canvas.translate(-cx, -cy);
    draw();
    canvas.restore();
  }

  /// Wheel with a hub, used by cars and motorbikes.
  void wheel(double cx, double cy, double r) {
    circle(cx, cy, r);
    circle(cx, cy, r * 0.45);
  }

  static Path ovalPath(double cx, double cy, double rx, double ry) =>
      Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));

  static Path rrectPath(double l, double t, double r, double b, double radius) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)));
}
