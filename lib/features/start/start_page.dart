import 'package:flutter/material.dart';

import '../../core/storage/project_repository.dart';
import '../gallery/gallery_page.dart';
import 'painting_animation.dart';

/// First screen: a picture paints itself and a big Play button leads home.
class StartPage extends StatefulWidget {
  const StartPage({super.key, required this.repository});

  final ProjectRepository repository;

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with SingleTickerProviderStateMixin {
  late final AnimationController _paint = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..forward();

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
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final picture = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _AppTitle(),
          const SizedBox(height: 16),
          PaintingAnimation(progress: _paint),
        ],
      ),
    );
    final playArea = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Let's colour!",
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5E35B1),
              ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
            onPressed: _play,
            style: FilledButton.styleFrom(
              minimumSize: const Size(220, 80),
              textStyle: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              backgroundColor: const Color(0xFF43A047),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 44),
            label: const Text('Play'),
          ),
      ],
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF8E1), Color(0xFFE1F5FE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: landscape
                ? Row(
                    children: [
                      Expanded(child: picture),
                      Expanded(child: Center(child: playArea)),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [picture, const SizedBox(height: 16), playArea],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// The app name, in a rounded, playful font (bundled, works offline).
class _AppTitle extends StatelessWidget {
  const _AppTitle();

  static const _letters = 'DrawApp';
  static const _colors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFFEC407A),
  ];

  @override
  Widget build(BuildContext context) {
    return FittedBox(
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
        style: const TextStyle(
          fontFamily: 'Fredoka',
          fontSize: 64,
          fontVariations: [FontVariation('wght', 700)],
          shadows: [Shadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 4)],
        ),
      ),
    );
  }
}
