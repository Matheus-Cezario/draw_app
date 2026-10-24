import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ui/kid_ui.dart';
import '../../core/ui/app_colors.dart';

enum NewChoice { book, blank, gallery, camera }

/// Asks how to start a new drawing. Returns null when dismissed.
Future<NewChoice?> showNewDrawingSheet(BuildContext context) {
  return showModalBottomSheet<NewChoice>(
    context: context,
    // Lets the sheet use the full height, so it fits when the phone is on its
    // side (the default limit is 9/16 of the screen).
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      side: BorderSide(color: AppColors.ink, width: 3),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New drawing', style: kidText(28, weight: 700)),
            const SizedBox(height: 4),
            Text('What do you want to colour?', style: kidText(16, weight: 500)),
            const SizedBox(height: 16),
            _BookTile(onTap: () => Navigator.pop(context, NewChoice.book)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OptionTile(
                    label: 'Blank page',
                    color: AppColors.tileBlank,
                    painter: const _BlankPagePainter(),
                    onTap: () => Navigator.pop(context, NewChoice.blank),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionTile(
                    label: 'A picture',
                    color: AppColors.tilePicture,
                    painter: const _PicturePainter(),
                    onTap: () => Navigator.pop(context, NewChoice.gallery),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionTile(
                    label: 'Take photo',
                    color: AppColors.tileCamera,
                    painter: const _CameraPainter(),
                    onTap: () => Navigator.pop(context, NewChoice.camera),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/// Wide tile that opens the ready-made colouring book.
class _BookTile extends StatelessWidget {
  const _BookTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.tileBook,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ink, width: 3),
          boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            CustomPaint(size: const Size(64, 64), painter: const _BookPainter()),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Colouring book', style: kidText(22, weight: 700)),
                  Text('Animals, cars, houses and more!', style: kidText(14, weight: 500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 34, color: AppColors.ink),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.color,
    required this.painter,
    required this.onTap,
  });

  final String label;
  final Color color;
  final CustomPainter painter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ink, width: 3),
          boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(0, 5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(size: const Size(64, 64), painter: painter),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: kidText(16, weight: 700)),
          ],
        ),
      ),
    );
  }
}

Paint _ink([double w = 3]) => Paint()
  ..color = AppColors.ink
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _shape(Canvas c, Path p, Color fill) {
  c.drawPath(p, Paint()..color = fill);
  c.drawPath(p, _ink());
}

Path _rr(double x, double y, double w, double h, double r) => Path()
  ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)));

class _BlankPagePainter extends CustomPainter {
  const _BlankPagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Sheet with a folded corner, a squiggle and a star.
    _shape(
      canvas,
      Path()
        ..moveTo(14, 6)
        ..lineTo(40, 6)
        ..lineTo(52, 18)
        ..lineTo(52, 58)
        ..lineTo(14, 58)
        ..close(),
      Colors.white,
    );
    _shape(
      canvas,
      Path()
        ..moveTo(40, 6)
        ..lineTo(40, 18)
        ..lineTo(52, 18)
        ..close(),
      const Color(0xFFE0E0E0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(21, 44)
        ..cubicTo(26, 30, 31, 52, 45, 36),
      Paint()
        ..color = const Color(0xFFFF7043)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final star = Path();
    const cx = 27.0, cy = 24.0;
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 7.0 : 3.2;
      final a = -1.5708 + i * 0.6283;
      final pt = Offset(cx + r * math.cos(a), cy + r * math.sin(a));
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    star.close();
    _shape(canvas, star, AppColors.artYellow);
  }

  @override
  bool shouldRepaint(_BlankPagePainter old) => false;
}

class _PicturePainter extends CustomPainter {
  const _PicturePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final frame = _rr(6, 12, 52, 40, 7);
    canvas.drawPath(frame, Paint()..color = const Color(0xFF9ADCF7));
    canvas.save();
    canvas.clipPath(frame);
    canvas.drawPath(
      Path()
        ..moveTo(0, 52)
        ..lineTo(20, 30)
        ..lineTo(34, 46)
        ..lineTo(44, 36)
        ..lineTo(64, 56)
        ..lineTo(64, 64)
        ..lineTo(0, 64)
        ..close(),
      Paint()..color = const Color(0xFF66BB6A),
    );
    canvas.restore();
    canvas.drawCircle(const Offset(44, 24), 6, Paint()..color = AppColors.artYellow);
    canvas.drawCircle(const Offset(44, 24), 6, _ink(2.5));
    canvas.drawPath(frame, _ink());
  }

  @override
  bool shouldRepaint(_PicturePainter old) => false;
}

class _CameraPainter extends CustomPainter {
  const _CameraPainter();

  @override
  void paint(Canvas canvas, Size size) {
    _shape(canvas, _rr(20, 10, 24, 12, 4), const Color(0xFF8E24AA));
    _shape(canvas, _rr(5, 17, 54, 38, 10), const Color(0xFFF26B5B));
    canvas.drawCircle(const Offset(32, 36), 13, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(32, 36), 13, _ink());
    canvas.drawCircle(const Offset(32, 36), 7, Paint()..color = const Color(0xFF42A5F5));
    canvas.drawCircle(const Offset(32, 36), 7, _ink(2.5));
    canvas.drawCircle(const Offset(28, 32), 2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(51, 25), 3, Paint()..color = AppColors.artYellow);
  }

  @override
  bool shouldRepaint(_CameraPainter old) => false;
}

class _BookPainter extends CustomPainter {
  const _BookPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Open book: two pages, a spine, a drawn star and rainbow stripes.
    final left = Path()
      ..moveTo(32, 16)
      ..quadraticBezierTo(18, 8, 4, 14)
      ..lineTo(4, 54)
      ..quadraticBezierTo(18, 48, 32, 56)
      ..close();
    final right = Path()
      ..moveTo(32, 16)
      ..quadraticBezierTo(46, 8, 60, 14)
      ..lineTo(60, 54)
      ..quadraticBezierTo(46, 48, 32, 56)
      ..close();
    _shape(canvas, left, Colors.white);
    _shape(canvas, right, Colors.white);
    final stripe = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    const colors = [Color(0xFFF26B5B), AppColors.artYellow, Color(0xFF42A5F5)];
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(Offset(40, 24.0 + i * 7), Offset(55, 22.0 + i * 7), stripe..color = colors[i]);
    }
    canvas.drawCircle(const Offset(18, 30), 6, Paint()..color = AppColors.artYellow);
    canvas.drawCircle(const Offset(18, 30), 6, _ink(2.5));
    canvas.drawPath(
      Path()
        ..moveTo(10, 44)
        ..quadraticBezierTo(18, 38, 26, 44),
      _ink(2.5),
    );
  }

  @override
  bool shouldRepaint(_BookPainter old) => false;
}
