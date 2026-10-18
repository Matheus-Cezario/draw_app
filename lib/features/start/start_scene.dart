import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Colours of the start-screen illustration.
const Color kInk = Color(0xFF2B2350);

/// The scene is drawn in a "design space" that is 820 units tall (or wider if
/// the screen is wider than tall) and then scaled to the real screen.
///
/// Right-anchored things (house, flowers) follow [rightShift]; ground things
/// follow [bottomShift]; top things follow [topInset], so the same drawing
/// works on tablets, tall phones and landscape phones.
class StartScenePainter extends CustomPainter {
  StartScenePainter({
    required this.progress,
    required this.rightShift,
    required this.bottomShift,
    required this.topInset,
  }) : super(repaint: progress);

  /// 0 = blank page, 1 = the finished (half painted) picture.
  final Animation<double> progress;
  final double rightShift;
  final double bottomShift;
  final double topInset;

  Paint _fillPaint(Color c) => Paint()..color = c;

  Paint _inkPaint([double w = 6]) => Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// Fill + ink outline, like the SVG groups.
  void _shape(Canvas c, Path p, Color fill, {bool outline = true, double w = 6}) {
    c.drawPath(p, _fillPaint(fill));
    if (outline) c.drawPath(p, _inkPaint(w));
  }

  void _circle(Canvas c, double x, double y, double r, Color fill,
      {bool outline = true}) {
    final p = Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));
    _shape(c, p, fill, outline: outline);
  }

  void _line(Canvas c, double x1, double y1, double x2, double y2, [double w = 6]) {
    c.drawLine(Offset(x1, y1), Offset(x2, y2), _inkPaint(w));
  }

  /// Draws only the first [t] (0..1) of [path] as a thick brush stroke.
  void _brushStroke(Canvas c, Path path, double t, Color color, double width) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      c.drawPath(m.extractPath(0, m.length * t), paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final yb = bottomShift;
    final xr = rightShift;
    final ti = topInset;
    final sx = w / 1180; // horizontal stretch for the hills
    final p = Curves.easeOutCubic.transform(progress.value.clamp(0.0, 1.0));
    final done = progress.value >= 1;

    canvas.drawRect(Offset.zero & size, _fillPaint(Colors.white));

    // ---- Sky: painted from the left up to a wavy edge. ----
    final ex = 0.65 * w;
    final k = (520 + yb) / 520;
    final sky = Path()
      ..moveTo(0, 0)
      ..lineTo(ex, 0)
      ..cubicTo(ex - 35, 55 * k, ex + 30, 105 * k, ex - 18, 165 * k)
      ..cubicTo(ex - 55, 215 * k, ex + 25, 265 * k, ex - 28, 325 * k)
      ..cubicTo(ex - 65, 372 * k, ex + 5, 425 * k, ex - 42, 520 * k)
      ..lineTo(0, 520 + yb)
      ..close();
    canvas.save();
    if (!done) canvas.clipRect(Rect.fromLTRB(0, 0, (ex + 40) * p, size.height));
    canvas.drawPath(sky, _fillPaint(const Color(0xFF9ADCF7)));
    if (p > 0.9 || done) {
      _circle(canvas, ex, 70 * k, 10, const Color(0xFF9ADCF7), outline: false);
      _circle(canvas, ex + 22, 210 * k, 8, const Color(0xFF9ADCF7), outline: false);
      _circle(canvas, ex - 5, 380 * k, 12, const Color(0xFF9ADCF7), outline: false);
    }
    canvas.restore();

    // ---- Sun ----
    canvas.save();
    canvas.translate(0, ti);
    for (final r in const [
      [130, 22, 130, 42],
      [130, 198, 130, 218],
      [32, 120, 52, 120],
      [208, 120, 228, 120],
      [62, 52, 76, 66],
      [184, 174, 198, 188],
      [198, 52, 184, 66],
      [76, 174, 62, 188],
    ]) {
      _line(canvas, r[0] + 0.0, r[1] + 0.0, r[2] + 0.0, r[3] + 0.0, 7);
    }
    _circle(canvas, 130, 120, 60, const Color(0xFFFFD23F));
    canvas.drawPath(
      Path()
        ..moveTo(108, 120)
        ..quadraticBezierTo(130, 142, 152, 120),
      _inkPaint(),
    );
    canvas.drawCircle(const Offset(110, 104), 5, _fillPaint(kInk));
    canvas.drawCircle(const Offset(150, 104), 5, _fillPaint(kInk));

    // ---- Little clouds ----
    _shape(
      canvas,
      Path()
        ..moveTo(930 + xr, 170)
        ..cubicTo(905 + xr, 170, 900 + xr, 140, 925 + xr, 136)
        ..cubicTo(925 + xr, 112, 960 + xr, 106, 972 + xr, 126)
        ..cubicTo(985 + xr, 104, 1025 + xr, 110, 1022 + xr, 138)
        ..cubicTo(1048 + xr, 140, 1046 + xr, 170, 1022 + xr, 170)
        ..close(),
      Colors.white,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(330, 260)
        ..cubicTo(310, 260, 306, 236, 326, 233)
        ..cubicTo(326, 214, 354, 210, 363, 226)
        ..cubicTo(374, 208, 405, 214, 402, 236)
        ..cubicTo(422, 238, 420, 260, 402, 260)
        ..close(),
      Colors.white,
    );
    canvas.restore();

    // ---- Back hill (painted) ----
    final back = Path()
      ..moveTo(0, 540 + yb)
      ..cubicTo(200 * sx, 420 + yb, 420 * sx, 430 + yb, 620 * sx, 520 + yb)
      ..cubicTo(800 * sx, 440 + yb, 1000 * sx, 420 + yb, 1180 * sx, 500 + yb)
      ..lineTo(1180 * sx, 820 + yb)
      ..lineTo(0, 820 + yb)
      ..close();
    canvas.save();
    if (!done) canvas.clipRect(Rect.fromLTRB(0, 0, w * p, size.height));
    _shape(canvas, back, const Color(0xFF8EDB7E));
    canvas.restore();

    // ---- House ----
    canvas.save();
    canvas.translate(xr, yb);
    _shape(canvas, Path()..addRect(const Rect.fromLTWH(1028, 352, 32, 60)), Colors.white);
    _shape(canvas, Path()..addRect(const Rect.fromLTWH(882, 432, 196, 186)), Colors.white);
    _shape(
      canvas,
      Path()
        ..moveTo(858, 444)
        ..lineTo(980, 338)
        ..lineTo(1102, 444)
        ..close(),
      const Color(0xFFF26B5B),
    );
    Path rrect(double x, double y, double w, double h, double r) => Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)));
    _shape(canvas, rrect(902, 470, 44, 44, 4), const Color(0xFFFFD23F));
    _line(canvas, 924, 470, 924, 514);
    _line(canvas, 902, 492, 946, 492);
    _shape(canvas, rrect(1012, 470, 44, 44, 4), Colors.white);
    _line(canvas, 1034, 470, 1034, 514);
    _line(canvas, 1012, 492, 1056, 492);
    _shape(canvas, rrect(954, 530, 52, 88, 24), Colors.white);
    canvas.drawCircle(const Offset(994, 576), 4, _fillPaint(kInk));
    canvas.restore();

    // ---- Tree: trunk painted, crown being painted ----
    canvas.save();
    canvas.translate(0, yb);
    _shape(canvas, rrect(196, 470, 38, 150, 8), const Color(0xFFB5764A));
    const crown = [
      [160.0, 430.0, 62.0],
      [230.0, 380.0, 72.0],
      [280.0, 450.0, 58.0],
      [210.0, 470.0, 55.0],
    ];
    for (final c in crown) {
      _circle(canvas, c[0], c[1], c[2], Colors.white);
    }
    final leaves = Path();
    for (final c in crown) {
      leaves.addOval(Rect.fromCircle(center: Offset(c[0], c[1]), radius: c[2]));
    }
    canvas.save();
    canvas.clipPath(leaves);
    final lp = Curves.easeOut.transform((progress.value * 1.2).clamp(0.0, 1.0));
    _brushStroke(
      canvas,
      Path()
        ..moveTo(90, 420)
        ..cubicTo(140, 380, 190, 440, 240, 360),
      lp,
      const Color(0xFF4CC26A),
      54,
    );
    _brushStroke(
      canvas,
      Path()
        ..moveTo(110, 480)
        ..cubicTo(150, 450, 180, 500, 220, 455),
      lp,
      const Color(0xFF4CC26A),
      54,
    );
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(101, 452)
        ..arcToPoint(const Offset(172, 369), radius: const Radius.circular(62)),
      _inkPaint(),
    );
    canvas.restore();

    // ---- Front hill: white, with green brush strokes ----
    final front = Path()
      ..moveTo(0, 640 + yb)
      ..cubicTo(260 * sx, 560 + yb, 560 * sx, 580 + yb, 760 * sx, 650 + yb)
      ..cubicTo(920 * sx, 600 + yb, 1060 * sx, 600 + yb, 1180 * sx, 640 + yb)
      ..lineTo(1180 * sx, 820 + yb)
      ..lineTo(0, 820 + yb)
      ..close();
    _shape(canvas, front, Colors.white, outline: false);
    canvas.save();
    canvas.clipPath(front);
    final hp = Curves.easeInOut.transform(((progress.value - 0.1) * 1.3).clamp(0.0, 1.0));
    const green = Color(0xFF3FB55A);
    _brushStroke(
      canvas,
      Path()
        ..moveTo(-30, 650 + yb)
        ..cubicTo(120 * sx, 615 + yb, 260 * sx, 625 + yb, 420 * sx, 640 + yb),
      hp,
      green,
      80,
    );
    _brushStroke(
      canvas,
      Path()
        ..moveTo(-30, 730 + yb)
        ..cubicTo(150 * sx, 700 + yb, 330 * sx, 720 + yb, 600 * sx, 712 + yb),
      hp,
      green,
      80,
    );
    _brushStroke(
      canvas,
      Path()
        ..moveTo(-30, 805 + yb)
        ..cubicTo(140 * sx, 790 + yb, 260 * sx, 800 + yb, 380 * sx, 790 + yb),
      hp,
      green,
      70,
    );
    canvas.restore();
    canvas.drawPath(
      Path()
        ..moveTo(0, 640 + yb)
        ..cubicTo(260 * sx, 560 + yb, 560 * sx, 580 + yb, 760 * sx, 650 + yb)
        ..cubicTo(920 * sx, 600 + yb, 1060 * sx, 600 + yb, 1180 * sx, 640 + yb),
      _inkPaint(),
    );

    // ---- Flowers ----
    canvas.save();
    canvas.translate(xr, yb);
    _line(canvas, 980, 760, 980, 710);
    _circle(canvas, 980, 690, 14, Colors.white);
    _circle(canvas, 962, 704, 12, Colors.white);
    _circle(canvas, 998, 704, 12, Colors.white);
    _circle(canvas, 980, 702, 8, const Color(0xFFFFD23F));
    _line(canvas, 1090, 770, 1090, 722);
    const pink = Color(0xFFFF8FB8);
    _circle(canvas, 1090, 702, 14, pink);
    _circle(canvas, 1072, 716, 12, pink);
    _circle(canvas, 1108, 716, 12, pink);
    _circle(canvas, 1090, 714, 8, const Color(0xFFFFD23F));
    canvas.restore();

    // ---- Paint drops, palette and brush ----
    final bx = 640 + xr / 2;
    _circle(canvas, bx + 60, 760 + yb, 9, green);
    _circle(canvas, bx + 88, 738 + yb, 6, green, outline: false);
    _circle(canvas, bx + 40, 790 + yb, 5, green, outline: false);

    canvas.save();
    canvas.translate(80, 690 + yb);
    canvas.rotate(-12 * math.pi / 180);
    _shape(
      canvas,
      Path()
        ..moveTo(0, 50)
        ..cubicTo(0, -10, 90, -30, 150, 0)
        ..cubicTo(200, 25, 190, 70, 150, 70)
        ..cubicTo(120, 70, 125, 100, 95, 105)
        ..cubicTo(40, 115, 0, 95, 0, 50)
        ..close(),
      const Color(0xFFF4D7A8),
    );
    _circle(canvas, 45, 30, 14, const Color(0xFFF26B5B));
    _circle(canvas, 90, 18, 14, const Color(0xFFFFD23F));
    _circle(canvas, 135, 32, 14, green);
    _circle(canvas, 40, 74, 14, const Color(0xFF5B8CFF));
    _circle(canvas, 125, 58, 10, Colors.white);
    canvas.restore();

    canvas.save();
    canvas.translate(bx, 690 + yb);
    canvas.rotate(-38 * math.pi / 180);
    _shape(canvas, rrect(-15, -240, 30, 180, 15), const Color(0xFFFF9F43));
    _shape(canvas, rrect(-19, -70, 38, 42, 4), const Color(0xFFD3D8E0));
    _line(canvas, -19, -50, 19, -50);
    _shape(
      canvas,
      Path()
        ..moveTo(-19, -28)
        ..quadraticBezierTo(-22, 14, 0, 34)
        ..quadraticBezierTo(22, 14, 19, -28)
        ..close(),
      green,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(StartScenePainter old) =>
      old.rightShift != rightShift ||
      old.bottomShift != bottomShift ||
      old.topInset != topInset;
}

/// White cloud that carries the app name.
class TitleCloudPainter extends CustomPainter {
  const TitleCloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Path()
      ..moveTo(95, 200)
      ..cubicTo(28, 200, 18, 122, 78, 110)
      ..cubicTo(70, 46, 156, 26, 192, 70)
      ..cubicTo(216, 8, 336, 4, 360, 66)
      ..cubicTo(398, 30, 490, 46, 486, 112)
      ..cubicTo(556, 116, 560, 200, 490, 200)
      ..close();
    canvas.drawPath(cloud, Paint()..color = Colors.white);
    canvas.drawPath(
      cloud,
      Paint()
        ..color = kInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(TitleCloudPainter old) => false;
}
