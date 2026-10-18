import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One piece of the picture: an outline that gets filled with colour.
class _Piece {
  const _Piece(this.path, this.color);

  /// Builds the shape in a unit square (0..1 on both axes).
  final Path Function() path;
  final Color color;
}

Path _rect(double l, double t, double r, double b) =>
    Path()..addRect(Rect.fromLTRB(l, t, r, b));

/// The unit square is stretched to a 4:3 frame, so the vertical radius is
/// scaled by 4/3 to keep circles round.
Path _circle(double cx, double cy, double r) => Path()
  ..addOval(Rect.fromCenter(
    center: Offset(cx, cy),
    width: r * 2,
    height: r * 2 * 4 / 3,
  ));

Path _poly(List<Offset> pts) => Path()..addPolygon(pts, true);

final List<_Piece> _pieces = [
  _Piece(() => _rect(0, 0, 1, 0.68), const Color(0xFF81D4FA)), // sky
  _Piece(() => _circle(0.82, 0.2, 0.09), const Color(0xFFFFD54F)), // sun
  _Piece(() => _rect(0, 0.68, 1, 1), const Color(0xFF9CCC65)), // grass
  _Piece(() => _rect(0.28, 0.42, 0.62, 0.8), const Color(0xFFFFB74D)), // house
  _Piece(
    () => _poly(const [Offset(0.24, 0.43), Offset(0.45, 0.22), Offset(0.66, 0.43)]),
    const Color(0xFFE53935),
  ), // roof
  _Piece(() => _rect(0.40, 0.58, 0.50, 0.8), const Color(0xFF8D6E63)), // door
  _Piece(() => _rect(0.54, 0.5, 0.6, 0.58), const Color(0xFF4FC3F7)), // window
  _Piece(() => _rect(0.8, 0.5, 0.84, 0.8), const Color(0xFF795548)), // trunk
  _Piece(() => _circle(0.82, 0.44, 0.12), const Color(0xFF2E7D32)), // crown
  _Piece(() => _circle(0.12, 0.84, 0.035), const Color(0xFFEC407A)), // flower
  _Piece(() => _circle(0.2, 0.9, 0.035), const Color(0xFFAB47BC)), // flower
];

/// A framed picture that paints itself, piece by piece, until it is colourful.
class PaintingAnimation extends StatelessWidget {
  const PaintingAnimation({super.key, required this.progress});

  /// 0 = empty outlines, 1 = fully painted.
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF8D6E63), width: 10),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(painter: _PicturePainter(progress)),
        ),
      ),
    );
  }
}

class _PicturePainter extends CustomPainter {
  _PicturePainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final n = _pieces.length;
    final t = progress.value * n;
    canvas.save();
    canvas.scale(size.width, size.height);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 / size.width
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF37474F);

    Offset? brushAt;
    Color? brushColor;

    for (var i = 0; i < n; i++) {
      final piece = _pieces[i];
      final path = piece.path();
      final local = (t - i).clamp(0.0, 1.0);
      if (local > 0) {
        final bounds = path.getBounds();
        final reveal = Curves.easeInOut.transform(local);
        canvas.save();
        canvas.clipPath(path);
        // Wipe left to right, like a stroke of paint.
        canvas.drawRect(
          Rect.fromLTRB(
            bounds.left,
            bounds.top,
            bounds.left + bounds.width * reveal,
            bounds.bottom,
          ),
          Paint()..color = piece.color,
        );
        canvas.restore();
        if (local < 1) {
          final wobble = math.sin(local * math.pi * 6) * bounds.height * 0.25;
          brushAt = Offset(
            bounds.left + bounds.width * reveal,
            bounds.center.dy + wobble,
          );
          brushColor = piece.color;
        }
      }
      canvas.drawPath(path, outline);
    }

    if (brushAt != null) _paintBrush(canvas, brushAt, brushColor!, size);
    canvas.restore();
  }

  void _paintBrush(Canvas canvas, Offset tip, Color color, Size size) {
    final unit = 1 / size.width;
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.scale(unit, unit * size.width / size.height);
    canvas.rotate(-0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -64, 10, 50), const Radius.circular(5)),
      Paint()..color = const Color(0xFFFF8F00),
    );
    canvas.drawRect(const Rect.fromLTWH(-6, -16, 12, 8), Paint()..color = const Color(0xFFB0BEC5));
    canvas.drawPath(
      Path()
        ..moveTo(-6, -8)
        ..quadraticBezierTo(-8, 4, 0, 10)
        ..quadraticBezierTo(8, 4, 6, -8)
        ..close(),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PicturePainter old) => false;
}
