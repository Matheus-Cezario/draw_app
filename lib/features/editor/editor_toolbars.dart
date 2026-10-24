import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'editor_controller.dart';
import 'tool_icons.dart';
import '../../core/ui/app_colors.dart';
import '../../core/audio/sfx_service.dart';

/// Brush sizes offered to the child (document pixels).
const List<double> kSizes = [8, 22, 44, 80];

/// Tools whose result depends on the brush size.
bool toolUsesSize(ToolType type) => switch (type) {
      ToolType.fill || ToolType.eyedropper || ToolType.selection => false,
      _ => true,
    };

/// Big colour dots, always shown at the top of the editor: two rows in
/// portrait, one row in landscape (where height is scarce).
class ColorBar extends StatelessWidget {
  const ColorBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditorController>();
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final rows = landscape ? 1 : 2;
    const cell = 52.0;

    Widget dot(Color swatch) {
      final selected = swatch == c.color;
      return GestureDetector(
        onTap: withTapSound(() => c.setColor(swatch)),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: selected ? 3.5 : 2.5),
              boxShadow: selected
                  ? const [
                      BoxShadow(color: Colors.white, spreadRadius: 2.5),
                      BoxShadow(color: AppColors.ink, spreadRadius: 5),
                    ]
                  : null,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: SizedBox(
        height: cell * rows + 8,
        child: GridView.count(
          scrollDirection: Axis.horizontal,
          crossAxisCount: rows,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          padding: const EdgeInsets.all(4),
          children: [for (final swatch in AppColors.swatches) dot(swatch)],
        ),
      ),
    );
  }
}

class _ToolInfo {
  const _ToolInfo(this.type, this.label);
  final ToolType type;
  final String label;
}

const _tools = <_ToolInfo>[
  _ToolInfo(ToolType.brush, 'Brush'),
  _ToolInfo(ToolType.fill, 'Paint'),
  _ToolInfo(ToolType.pencil, 'Pencil'),
  _ToolInfo(ToolType.eraser, 'Eraser'),
  _ToolInfo(ToolType.eyedropper, 'Pick'),
  _ToolInfo(ToolType.line, 'Line'),
  _ToolInfo(ToolType.rectangle, 'Square'),
  _ToolInfo(ToolType.ellipse, 'Circle'),
  _ToolInfo(ToolType.selection, 'Move'),
];


/// Brush sizes + tools. Horizontal strip below the canvas in portrait, a
/// vertical rail on the side in landscape.
class ToolPanel extends StatelessWidget {
  const ToolPanel({super.key, required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditorController>();

    final sizes = [
      if (toolUsesSize(c.toolType))
        for (final size in kSizes)
          _SizeButton(
            size: size,
            color: c.color,
            selected: c.size == size,
            onTap: () => c.setSize(size),
          ),
    ];
    final tools = [
      for (final t in _tools)
        _ToolButton(
          info: t,
          selected: c.toolType == t.type,
          onTap: () => c.selectTool(t.type),
        ),
    ];

    if (vertical) {
      return Container(
        width: 156,
        decoration: const BoxDecoration(
          color: AppColors.panel,
          border: Border(right: BorderSide(color: AppColors.ink, width: 3)),
        ),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            if (sizes.isNotEmpty) ...[
              Wrap(alignment: WrapAlignment.center, children: sizes),
              const SizedBox(height: 6),
            ],
            Wrap(alignment: WrapAlignment.center, children: tools),
          ],
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.panel,
        border: Border(top: BorderSide(color: AppColors.ink, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sizes.isNotEmpty)
              SizedBox(
                height: 56,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: sizes),
              ),
            SizedBox(
              height: 86,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: tools,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.size,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final double size;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dot = 8 + size / 80 * 26; // 8..34 px preview, in the chosen colour
    return GestureDetector(
      onTap: withTapSound(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? AppColors.cream : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.ink, width: selected ? 3.5 : 2),
          boxShadow: selected
              ? const [BoxShadow(color: AppColors.ink, offset: Offset(0, 3))]
              : null,
        ),
        child: Center(
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  final _ToolInfo info;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: withTapSound(onTap),
      child: AnimatedScale(
        scale: selected ? 1.08 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 66,
          height: 74,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: toolTileColor(info.type),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.ink, width: selected ? 4 : 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(0, selected ? 5 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToolIcon(info.type, size: 40),
              Text(
                info.label,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 12,
                  color: AppColors.ink,
                  fontVariations: [FontVariation('wght', 600)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
