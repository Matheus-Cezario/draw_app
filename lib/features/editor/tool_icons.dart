import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ui/app_colors.dart';
import 'editor_controller.dart';


/// Pastel tile colour behind each tool.
Color toolTileColor(ToolType type) => switch (type) {
      ToolType.brush => AppColors.toolBrush,
      ToolType.fill => AppColors.toolFill,
      ToolType.pencil => AppColors.toolPencil,
      ToolType.eraser => AppColors.toolEraser,
      ToolType.eyedropper => AppColors.toolEyedropper,
      ToolType.line => AppColors.toolLine,
      ToolType.rectangle => AppColors.toolRectangle,
      ToolType.ellipse => AppColors.toolEllipse,
      ToolType.text => AppColors.toolText,
      ToolType.selection => AppColors.toolSelection,
    };

/// A chunky, hand-drawn style icon for each tool (drawn in a 48x48 box).
class ToolIcon extends StatelessWidget {
  const ToolIcon(this.type, {super.key, this.size = 40});

  final ToolType type;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(size, size), painter: _ToolIconPainter(type));
}

class _ToolIconPainter extends CustomPainter {
  _ToolIconPainter(this.type);

  final ToolType type;

  Paint _fill(Color c) => Paint()..color = c;
  Paint get _ink => Paint()
    ..color = AppColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _shape(Canvas c, Path p, Color fill) {
    c.drawPath(p, _fill(fill));
    c.drawPath(p, _ink);
  }

  Path _rrect(double x, double y, double w, double h, double r) => Path()
    ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    switch (type) {
      case ToolType.brush:
        canvas.translate(24, 23);
        canvas.rotate(math.pi / 4);
        _shape(canvas, _rrect(-4.5, -22, 9, 24, 4.5), const Color(0xFFFF9F43));
        _shape(canvas, _rrect(-6, 1, 12, 8, 2), const Color(0xFFD3D8E0));
        _shape(
          canvas,
          Path()
            ..moveTo(-6, 9)
            ..quadraticBezierTo(-7, 19, 0, 23)
            ..quadraticBezierTo(7, 19, 6, 9)
            ..close(),
          const Color(0xFF3FB55A),
        );
      case ToolType.fill:
        // Handle, bucket body, rim and a paint drop.
        canvas.drawPath(
          Path()
            ..moveTo(12, 19)
            ..quadraticBezierTo(24, -2, 36, 19),
          _ink,
        );
        _shape(
          canvas,
          Path()
            ..moveTo(9, 19)
            ..lineTo(39, 19)
            ..lineTo(35, 43)
            ..lineTo(13, 43)
            ..close(),
          const Color(0xFF42A5F5),
        );
        _shape(canvas, _rrect(7, 14, 34, 8, 4), AppColors.artBlue);
        _shape(
          canvas,
          Path()
            ..moveTo(24, 26)
            ..quadraticBezierTo(32, 34, 24, 39)
            ..quadraticBezierTo(16, 34, 24, 26)
            ..close(),
          const Color(0xFFFF5C8A),
        );
      case ToolType.pencil:
        canvas.translate(24, 24);
        canvas.rotate(math.pi / 4);
        _shape(canvas, _rrect(-5.5, -24, 11, 6, 2), const Color(0xFFFF8FB8));
        _shape(canvas, _rrect(-5.5, -18, 11, 26, 1), AppColors.artYellow);
        canvas.drawLine(const Offset(0, -18), const Offset(0, 8), _ink..strokeWidth = 1.8);
        _shape(
          canvas,
          Path()..addPolygon(const [Offset(-5.5, 8), Offset(5.5, 8), Offset(0, 21)], true),
          const Color(0xFFF4D7A8),
        );
        canvas.drawPath(
          Path()..addPolygon(const [Offset(-2, 16), Offset(2, 16), Offset(0, 21)], true),
          _fill(AppColors.ink),
        );
      case ToolType.eraser:
        canvas.translate(24, 24);
        canvas.rotate(-math.pi / 6);
        final body = _rrect(-18, -11, 36, 22, 6);
        canvas.drawPath(body, _fill(const Color(0xFFFF8FB8)));
        canvas.save();
        canvas.clipPath(body);
        canvas.drawRect(const Rect.fromLTWH(3, -12, 16, 24), _fill(const Color(0xFF5B8CFF)));
        canvas.restore();
        canvas.drawLine(const Offset(3, -11), const Offset(3, 11), _ink);
        canvas.drawPath(body, _ink);
      case ToolType.eyedropper:
        canvas.translate(24, 24);
        canvas.rotate(math.pi / 4);
        _shape(canvas, _rrect(-6.5, -23, 13, 13, 6.5), const Color(0xFFF26B5B));
        _shape(canvas, _rrect(-9, -12, 18, 5, 2), Colors.white);
        _shape(canvas, _rrect(-5, -7, 10, 22, 3), const Color(0xFFB3E5FC));
        _shape(
          canvas,
          Path()..addPolygon(const [Offset(-3.5, 15), Offset(3.5, 15), Offset(0, 23)], true),
          const Color(0xFFB3E5FC),
        );
        canvas.drawRect(const Rect.fromLTWH(-3, 2, 6, 12), _fill(const Color(0xFF7B4DFF)));
      case ToolType.line:
        final path = Path()
          ..moveTo(8, 38)
          ..cubicTo(16, 8, 30, 46, 40, 10);
        canvas.drawPath(path, _ink..strokeWidth = 11);
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF7B4DFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5.4
            ..strokeCap = StrokeCap.round,
        );
      case ToolType.rectangle:
        _shape(canvas, _rrect(8, 8, 32, 32, 7), const Color(0xFF66BB6A));
        canvas.drawPath(
          Path()
            ..moveTo(14, 16)
            ..lineTo(22, 16),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      case ToolType.ellipse:
        _shape(
          canvas,
          Path()..addOval(const Rect.fromLTWH(7, 7, 34, 34)),
          const Color(0xFFFF7043),
        );
        canvas.drawArc(
          const Rect.fromLTWH(13, 13, 22, 22),
          math.pi * 1.05,
          math.pi * 0.45,
          false,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      case ToolType.text:
        void letter(String t, double fontSize, Offset at) {
          final stroke = TextPainter(
            text: TextSpan(
              text: t,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: fontSize,
                fontVariations: const [FontVariation('wght', 700)],
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 5
                  ..strokeJoin = StrokeJoin.round
                  ..color = AppColors.ink,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          final fill = TextPainter(
            text: TextSpan(
              text: t,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: fontSize,
                fontVariations: const [FontVariation('wght', 700)],
                color: const Color(0xFFAB47BC),
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          stroke.paint(canvas, at);
          fill.paint(canvas, at);
        }
        letter('A', 34, const Offset(4, 2));
        letter('a', 24, const Offset(25, 14));
      case ToolType.selection:
        final arms = Path()
          ..moveTo(24, 9)
          ..lineTo(24, 39)
          ..moveTo(9, 24)
          ..lineTo(39, 24);
        canvas.drawPath(arms, _ink..strokeWidth = 9.5);
        canvas.drawPath(
          arms,
          Paint()
            ..color = const Color(0xFF26C6DA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.2
            ..strokeCap = StrokeCap.round,
        );
        for (final tip in const [
          [Offset(24, 2), Offset(17, 11), Offset(31, 11)],
          [Offset(24, 46), Offset(17, 37), Offset(31, 37)],
          [Offset(2, 24), Offset(11, 17), Offset(11, 31)],
          [Offset(46, 24), Offset(37, 17), Offset(37, 31)],
        ]) {
          _shape(canvas, Path()..addPolygon(tip, true), const Color(0xFF26C6DA));
        }
    }
  }

  @override
  bool shouldRepaint(_ToolIconPainter old) => old.type != type;
}
