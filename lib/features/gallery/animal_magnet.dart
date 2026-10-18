import 'package:flutter/material.dart';

const Color _ink = Color(0xFF2B2350);

enum Animal { cat, dog, bunny, panda, frog, pig }

/// Picks an animal and a tilt from a project id. Stable across runs (we do not
/// use `String.hashCode`, which has no stability guarantee).
int stableHash(String text) {
  var h = 17;
  for (final unit in text.codeUnits) {
    h = (h * 31 + unit) & 0x7FFFFFFF;
  }
  return h;
}

Animal animalFor(String id) => Animal.values[(stableHash(id) ~/ 7) % Animal.values.length];

/// Tilt in radians, between about -5 and +5 degrees, never exactly flat.
double tiltFor(String id) {
  const degrees = [-4.5, 3.0, -2.0, 5.0, -5.0, 2.5, 4.0, -3.0, 1.5, -1.5];
  return degrees[stableHash(id) % degrees.length] * 3.14159265 / 180;
}

/// A round, fridge-magnet style animal face.
class AnimalMagnet extends StatelessWidget {
  const AnimalMagnet({super.key, required this.animal, this.size = 64});

  final Animal animal;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AnimalPainter(animal),
    );
  }
}

class _AnimalPainter extends CustomPainter {
  _AnimalPainter(this.animal);

  final Animal animal;

  Paint _fill(Color c) => Paint()..color = c;
  Paint get _line => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _shape(Canvas c, Path p, Color color) {
    c.drawPath(p, _fill(color));
    c.drawPath(p, _line);
  }

  Path _oval(double cx, double cy, double rx, double ry) =>
      Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2));

  Path _tri(Offset a, Offset b, Offset c) => Path()..addPolygon([a, b, c], true);

  void _eyes(Canvas c, {double y = 33, double dx = 9}) {
    c.drawCircle(Offset(32 - dx, y), 3, _fill(_ink));
    c.drawCircle(Offset(32 + dx, y), 3, _fill(_ink));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 64);

    // Soft shadow so it reads as a magnet lying on the paper.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(33, 59), width: 40, height: 7),
      _fill(const Color(0x33000000)),
    );

    switch (animal) {
      case Animal.cat:
        _shape(canvas, _tri(const Offset(10, 28), const Offset(12, 4), const Offset(28, 16)), const Color(0xFFFFB547));
        _shape(canvas, _tri(const Offset(54, 28), const Offset(52, 4), const Offset(36, 16)), const Color(0xFFFFB547));
        _shape(canvas, _oval(32, 36, 24, 21), const Color(0xFFFFB547));
        _eyes(canvas);
        _shape(canvas, _tri(const Offset(28, 40), const Offset(36, 40), const Offset(32, 45)), const Color(0xFFFF7A9A));
        for (final s in [-1.0, 1.0]) {
          canvas.drawLine(Offset(32 + s * 14, 42), Offset(32 + s * 24, 40), _line..strokeWidth = 2);
          canvas.drawLine(Offset(32 + s * 14, 46), Offset(32 + s * 24, 48), _line..strokeWidth = 2);
        }
      case Animal.dog:
        _shape(canvas, _oval(10, 30, 8, 15), const Color(0xFF8B5E3C));
        _shape(canvas, _oval(54, 30, 8, 15), const Color(0xFF8B5E3C));
        _shape(canvas, _oval(32, 34, 22, 22), const Color(0xFFD9A066));
        _shape(canvas, _oval(32, 43, 12, 9), const Color(0xFFF5DDB8));
        _eyes(canvas, y: 30);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(32, 40), width: 11, height: 8),
          _fill(_ink),
        );
      case Animal.bunny:
        _shape(canvas, _oval(21, 12, 6.5, 14), Colors.white);
        _shape(canvas, _oval(43, 12, 6.5, 14), Colors.white);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(21, 13), width: 6, height: 17),
          _fill(const Color(0xFFFFB3C7)),
        );
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(43, 13), width: 6, height: 17),
          _fill(const Color(0xFFFFB3C7)),
        );
        _shape(canvas, _oval(32, 38, 21, 19), Colors.white);
        _eyes(canvas, y: 36, dx: 8);
        _shape(canvas, _tri(const Offset(29, 42), const Offset(35, 42), const Offset(32, 46)), const Color(0xFFFF7A9A));
      case Animal.panda:
        _shape(canvas, _oval(12, 14, 8, 8), _ink);
        _shape(canvas, _oval(52, 14, 8, 8), _ink);
        _shape(canvas, _oval(32, 36, 23, 21), Colors.white);
        canvas.drawPath(_oval(22, 33, 6, 8), _fill(_ink));
        canvas.drawPath(_oval(42, 33, 6, 8), _fill(_ink));
        canvas.drawCircle(const Offset(23, 33), 2, _fill(Colors.white));
        canvas.drawCircle(const Offset(41, 33), 2, _fill(Colors.white));
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(32, 43), width: 9, height: 6),
          _fill(_ink),
        );
      case Animal.frog:
        _shape(canvas, _oval(32, 40, 25, 18), const Color(0xFF7BD35B));
        for (final x in [20.0, 44.0]) {
          _shape(canvas, _oval(x, 20, 9, 9), const Color(0xFF7BD35B));
          canvas.drawCircle(Offset(x, 20), 5, _fill(Colors.white));
          canvas.drawCircle(Offset(x, 20), 2.5, _fill(_ink));
        }
        canvas.drawPath(
          Path()
            ..moveTo(20, 42)
            ..quadraticBezierTo(32, 54, 44, 42),
          _line,
        );
        canvas.drawCircle(const Offset(28, 36), 1.4, _fill(_ink));
        canvas.drawCircle(const Offset(36, 36), 1.4, _fill(_ink));
      case Animal.pig:
        _shape(canvas, _tri(const Offset(12, 26), const Offset(14, 6), const Offset(28, 17)), const Color(0xFFFF8FAE));
        _shape(canvas, _tri(const Offset(52, 26), const Offset(50, 6), const Offset(36, 17)), const Color(0xFFFF8FAE));
        _shape(canvas, _oval(32, 36, 23, 21), const Color(0xFFFFA9C2));
        _eyes(canvas, y: 30);
        _shape(canvas, _oval(32, 42, 11, 8), const Color(0xFFFF7A9F));
        canvas.drawCircle(const Offset(28, 42), 1.8, _fill(_ink));
        canvas.drawCircle(const Offset(36, 42), 1.8, _fill(_ink));
    }
  }

  @override
  bool shouldRepaint(_AnimalPainter old) => old.animal != animal;
}
