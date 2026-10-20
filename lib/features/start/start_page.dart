import 'package:flutter/material.dart';

import '../../core/storage/project_repository.dart';
import '../gallery/gallery_page.dart';
import 'start_scene.dart';

/// First screen: a half-painted picture, the app name on a cloud and one big
/// round Play button.
class StartPage extends StatefulWidget {
  const StartPage({super.key, required this.repository});

  final ProjectRepository repository;

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with SingleTickerProviderStateMixin {
  late final AnimationController _paint = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..forward();

  bool _pressed = false;

  @override
  void dispose() {
    _paint.dispose();
    super.dispose();
  }

  void _play() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GalleryPage(repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth, h = constraints.maxHeight;
        // Design space: 820 units on the short side.
        final unit = (w < h ? w : h) / 820;
        final dw = w / unit, dh = h / unit;
        final bottomShift = dh - 820; // >= 0
        final rightShift = dw - 1180;
        final topInset = media.padding.top / unit;
        final playY = 435 + bottomShift * 0.4 + topInset * 0.5;

        return FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(
            width: dw,
            height: dh,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: StartScenePainter(
                      progress: _paint,
                      rightShift: rightShift,
                      bottomShift: bottomShift,
                      topInset: topInset,
                    ),
                  ),
                ),
                Positioned(
                  left: (dw - 580) / 2,
                  top: 20 + topInset,
                  width: 580,
                  height: 230,
                  child: const _TitleCloud(),
                ),
                Positioned(
                  left: dw / 2 - 95,
                  top: playY - 95,
                  child: _PlayButton(
                    pressed: _pressed,
                    onPressedChanged: (v) => setState(() => _pressed = v),
                    onTap: _play,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _TitleCloud extends StatelessWidget {
  const _TitleCloud();

  static const _letters = 'Color Fun';
  static const _colors = [
    Color(0xFFE0452F),
    Color(0xFFD06A00),
    Color(0xFF2E9E4F),
    Color(0xFF1F7FD1),
    Color(0xFF8A3FD1),
    Color(0xFFE0452F),
    Color(0xFFD06A00),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: TitleCloudPainter())),
        Positioned(
          left: 0,
          right: 0,
          top: 74,
          child: Text.rich(
            TextSpan(
              children: [
                for (var i = 0; i < _letters.length; i++)
                  TextSpan(
                    text: _letters[i],
                    style: TextStyle(color: _colors[i % _colors.length]),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 80,
              height: 1,
              letterSpacing: 1,
              fontVariations: [FontVariation('wght', 700)],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.pressed,
    required this.onPressedChanged,
    required this.onTap,
  });

  final bool pressed;
  final ValueChanged<bool> onPressedChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play',
      child: GestureDetector(
        onTapDown: (_) => onPressedChanged(true),
        onTapCancel: () => onPressedChanged(false),
        onTapUp: (_) => onPressedChanged(false),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          transform: Matrix4.translationValues(0, pressed ? 6 : 0, 0),
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF2543D),
            border: Border.all(color: kInk, width: 8),
            boxShadow: [
              BoxShadow(color: kInk, offset: Offset(0, pressed ? 4 : 12)),
            ],
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.only(left: 14),
              child: CustomPaint(size: Size(84, 92), painter: _TrianglePainter()),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final tri = Path()
      ..moveTo(10, 8)
      ..lineTo(76, 46)
      ..lineTo(10, 84)
      ..close();
    canvas.drawPath(tri, Paint()..color = Colors.white);
    canvas.drawPath(
      tri,
      Paint()
        ..color = kInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => false;
}
