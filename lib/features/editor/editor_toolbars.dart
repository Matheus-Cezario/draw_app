import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'editor_controller.dart';

/// Fixed palette: kids pick from big colours instead of sliders. Ordered in
/// pairs (light on top, strong below) so a two-row bar groups similar hues.
const List<Color> kPalette = [
  Color(0xFFFFFFFF), Color(0xFF000000), // white, black
  Color(0xFFE0E0E0), Color(0xFF757575), // greys
  Color(0xFFFFCDD2), Color(0xFFE53935), // red
  Color(0xFFF48FB1), Color(0xFFD81B60), // pink
  Color(0xFFFFCCBC), Color(0xFFFF7043), // coral
  Color(0xFFFFE0B2), Color(0xFFFB8C00), // orange
  Color(0xFFFFF59D), Color(0xFFFDD835), // yellow
  Color(0xFFDCEDC8), Color(0xFF9CCC65), // light green
  Color(0xFF81C784), Color(0xFF2E7D32), // green
  Color(0xFFB2EBF2), Color(0xFF00ACC1), // turquoise
  Color(0xFF90CAF9), Color(0xFF1E88E5), // blue
  Color(0xFF9FA8DA), Color(0xFF283593), // dark blue
  Color(0xFFE1BEE7), Color(0xFF8E24AA), // purple
  Color(0xFFD7CCC8), Color(0xFF6D4C41), // brown
  Color(0xFFFFD6B0), Color(0xFFD7A86E), // skin / sand
];

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
    final scheme = Theme.of(context).colorScheme;
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final rows = landscape ? 1 : 2;
    const cell = 52.0;

    Widget dot(Color swatch) {
      final selected = swatch == c.color;
      return GestureDetector(
        onTap: () => c.setColor(swatch),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: selected ? 46 : 38,
            height: selected ? 46 : 38,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 4 : 1.5,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: scheme.surfaceContainer,
      child: SizedBox(
        height: cell * rows + 8,
        child: GridView.count(
          scrollDirection: Axis.horizontal,
          crossAxisCount: rows,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          padding: const EdgeInsets.all(4),
          children: [for (final swatch in kPalette) dot(swatch)],
        ),
      ),
    );
  }
}

class _ToolInfo {
  const _ToolInfo(this.type, this.icon, this.label);
  final ToolType type;
  final IconData icon;
  final String label;
}

const _tools = <_ToolInfo>[
  _ToolInfo(ToolType.brush, Icons.brush, 'Brush'),
  _ToolInfo(ToolType.fill, Icons.format_color_fill, 'Paint'),
  _ToolInfo(ToolType.pencil, Icons.edit, 'Pencil'),
  _ToolInfo(ToolType.eraser, Icons.cleaning_services, 'Eraser'),
  _ToolInfo(ToolType.eyedropper, Icons.colorize, 'Pick'),
  _ToolInfo(ToolType.line, Icons.show_chart, 'Line'),
  _ToolInfo(ToolType.rectangle, Icons.crop_square, 'Square'),
  _ToolInfo(ToolType.ellipse, Icons.circle_outlined, 'Circle'),
  _ToolInfo(ToolType.text, Icons.text_fields, 'Text'),
  _ToolInfo(ToolType.selection, Icons.highlight_alt, 'Move'),
];

/// Brush sizes + tools. Horizontal strip below the canvas in portrait, a
/// vertical rail on the side in landscape.
class ToolPanel extends StatelessWidget {
  const ToolPanel({super.key, required this.vertical});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditorController>();
    final scheme = Theme.of(context).colorScheme;

    final sizes = [
      if (toolUsesSize(c.toolType))
        for (final size in kSizes)
        _SizeButton(
          size: size,
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
      return Material(
        color: scheme.surfaceContainer,
        child: SizedBox(
          width: 150,
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              if (sizes.isNotEmpty) ...[
                Wrap(alignment: WrapAlignment.center, children: sizes),
                const Divider(),
              ],
              Wrap(alignment: WrapAlignment.center, children: tools),
            ],
          ),
        ),
      );
    }
    return Material(
      color: scheme.surfaceContainer,
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
              height: 76,
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
    required this.selected,
    required this.onTap,
  });

  final double size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dot = 8 + size / 80 * 28; // 8..36 px preview
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 3 : 1,
          ),
        ),
        child: Center(
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: scheme.onSurface,
              shape: BoxShape.circle,
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
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 68,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              info.icon,
              size: 30,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
            Text(
              info.label,
              style: TextStyle(
                fontSize: 11,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
