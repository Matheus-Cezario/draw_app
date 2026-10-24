import 'package:flutter/material.dart';

import '../../core/library/catalog.dart';
import '../../core/library/drawing.dart';
import '../../core/library/render.dart';
import '../../core/scan/scan_pipeline.dart';
import '../../core/scan/scan_service.dart';
import '../../core/storage/project_repository.dart';
import '../../core/ui/kid_ui.dart';
import '../editor/editor_page.dart';
import '../../core/ui/app_colors.dart';
import '../../core/audio/sfx_service.dart';

/// Colour and icon of each category header.
({Color color, IconData icon}) _style(DrawingCategory c) => switch (c) {
      DrawingCategory.animals => (color: AppColors.categoryAnimals, icon: Icons.pets_rounded),
      DrawingCategory.cars => (color: AppColors.categoryCars, icon: Icons.directions_car_rounded),
      DrawingCategory.motorcycles => (color: AppColors.categoryMotorcycles, icon: Icons.two_wheeler_rounded),
      DrawingCategory.houses => (color: AppColors.categoryHouses, icon: Icons.home_rounded),
      DrawingCategory.plants => (color: AppColors.categoryPlants, icon: Icons.local_florist_rounded),
    };

/// Ready-made drawings, one row per category.
class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.repository});

  final ProjectRepository repository;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _scanner = ScanService();
  bool _busy = false;

  Future<void> _start(Drawing drawing) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picture = await renderDrawing(drawing);
      final scan = await _scanner.scan(picture, const ScanParams(gapClosing: 1));
      final doc = await widget.repository.create(name: drawing.name, scan: scan);
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EditorPage(document: doc, repository: widget.repository),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oops, could not open it. Try again!', style: kidText(16))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.board,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
        leadingWidth: 60,
        leading: Center(
          child: RoundSticker(
            icon: Icons.arrow_back_rounded,
            color: AppColors.back,
            tooltip: 'Back',
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text('Colouring book', style: kidText(24, weight: 700)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            children: [
              for (final category in DrawingCategory.values)
                _Section(category: category, onPick: _start),
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: AppColors.scrim,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.ink, width: 3),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.danger, strokeWidth: 6),
                        const SizedBox(height: 14),
                        Text('Getting your page ready...', style: kidText(18, weight: 700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.category, required this.onPick});

  final DrawingCategory category;
  final ValueChanged<Drawing> onPick;

  @override
  Widget build(BuildContext context) {
    final style = _style(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 16, 6),
              decoration: BoxDecoration(
                color: style.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.ink, width: 3),
                boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(0, 3))],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                    ),
                    child: Icon(style.icon, size: 22, color: AppColors.ink),
                  ),
                  const SizedBox(width: 8),
                  Text(category.label, style: kidText(22, weight: 700)),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: drawingsIn(category).length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, i) {
                final drawing = drawingsIn(category)[i];
                return _DrawingCard(drawing: drawing, onTap: () => onPick(drawing));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingCard extends StatelessWidget {
  const _DrawingCard({required this.drawing, required this.onTap});

  final Drawing drawing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: withTapSound(onTap),
      child: Container(
        width: 158,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink, width: 3),
          boxShadow: const [BoxShadow(color: AppColors.ink, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.hairlineSoft),
                  ),
                  child: CustomPaint(painter: _ThumbPainter(drawing)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              drawing.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: kidText(17, weight: 600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  const _ThumbPainter(this.drawing);

  final Drawing drawing;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - side) / 2, (size.height - side) / 2);
    canvas.clipRect(Rect.fromLTWH(0, 0, side, side));
    drawing.paintLines(canvas, Size(side, side));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => old.drawing != drawing;
}
