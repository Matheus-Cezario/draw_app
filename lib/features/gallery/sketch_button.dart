import 'dart:math' as math;

import 'package:flutter/material.dart';

const Color _ink = Color(0xFF2B2350);

/// A button that looks hand drawn: wobbly double outline, offset "pencil"
/// shadow and a drawn plus sign.
class SketchButton extends StatefulWidget {
  const SketchButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFFFFD23F),
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  State<SketchButton> createState() => _SketchButtonState();
}

class _SketchButtonState extends State<SketchButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
          width: 170,
          height: 72,
          child: CustomPaint(
            painter: _SketchPainter(widget.color, _pressed),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CustomPaint(size: Size(26, 26), painter: _PlusPainter()),
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 30,
                      color: _ink,
                      fontVariations: [FontVariation('wght', 700)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded rectangle whose edge wobbles a little, like a pen stroke.
Path _wobblyRRect(Rect r, double radius, double seed, double amount) {
  final pts = <Offset>[];
  const steps = 96;
  final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
  final base = Path()..addRRect(rr);
  final metric = base.computeMetrics().first;
  for (var i = 0; i < steps; i++) {
    final t = metric.getTangentForOffset(metric.length * i / steps)!;
    final n = t.vector;
    final wobble = math.sin(i * 0.55 + seed) * amount + math.sin(i * 1.7 + seed * 2) * amount * 0.4;
    pts.add(t.position + Offset(-n.dy, n.dx) * wobble);
  }
  final path = Path()..moveTo((pts.last.dx + pts.first.dx) / 2, (pts.last.dy + pts.first.dy) / 2);
  for (var i = 0; i < pts.length; i++) {
    final next = pts[(i + 1) % pts.length];
    path.quadraticBezierTo(pts[i].dx, pts[i].dy, (pts[i].dx + next.dx) / 2, (pts[i].dy + next.dy) / 2);
  }
  return path..close();
}

class _SketchPainter extends CustomPainter {
  _SketchPainter(this.color, this.pressed);

  final Color color;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 4, size.width - 14, size.height - 16);
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Pencil shadow: the same blob, pushed down and right, filled with ink.
    final shadowShift = pressed ? const Offset(2, 3) : const Offset(5, 8);
    canvas.drawPath(
      _wobblyRRect(rect.shift(shadowShift), 24, 1.3, 1.0),
      Paint()..color = _ink,
    );
    final body = _wobblyRRect(rect, 24, 0.4, 1.1);
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(body, line);
    // Second, slightly off pass: the "I drew it twice" look.
    canvas.drawPath(
      _wobblyRRect(rect.inflate(1.5), 25, 2.2, 1.0),
      line
        ..strokeWidth = 2
        ..color = _ink.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_SketchPainter old) => old.color != color || old.pressed != pressed;
}

class _PlusPainter extends CustomPainter {
  const _PlusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(13, 3)
        ..quadraticBezierTo(14, 13, 13, 23),
      p,
    );
    canvas.drawPath(
      Path()
        ..moveTo(3, 14)
        ..quadraticBezierTo(13, 12, 23, 13),
      p,
    );
  }

  @override
  bool shouldRepaint(_PlusPainter old) => false;
}
