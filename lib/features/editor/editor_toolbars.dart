import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'editor_controller.dart';
import 'tool_icons.dart';

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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: kEditorInk, width: selected ? 3.5 : 2.5),
              boxShadow: selected
                  ? const [
                      BoxShadow(color: Colors.white, spreadRadius: 2.5),
                      BoxShadow(color: kEditorInk, spreadRadius: 5),
                    ]
                  : null,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF3C4),
        border: Border(bottom: BorderSide(color: kEditorInk, width: 3)),
      ),
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
  _ToolInfo(ToolType.text, 'Text'),
  _ToolInfo(ToolType.selection, 'Move'),
];

const Color _panelColor = Color(0xFFE6DCFF);

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
          color: _panelColor,
          border: Border(right: BorderSide(color: kEditorInk, width: 3)),
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
        color: _panelColor,
        border: Border(top: BorderSide(color: kEditorInk, width: 3)),
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
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF3C4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kEditorInk, width: selected ? 3.5 : 2),
          boxShadow: selected
              ? const [BoxShadow(color: kEditorInk, offset: Offset(0, 3))]
              : null,
        ),
        child: Center(
          child: Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: kEditorInk, width: 2),
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
      onTap: onTap,
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
            border: Border.all(color: kEditorInk, width: selected ? 4 : 2.5),
            boxShadow: [
              BoxShadow(
                color: kEditorInk,
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
                  color: kEditorInk,
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
