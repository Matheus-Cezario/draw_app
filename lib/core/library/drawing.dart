import 'dart:ui';

import 'pen.dart';

enum DrawingCategory {
  animals('Animals'),
  cars('Cars'),
  motorcycles('Motorbikes'),
  houses('Houses'),
  plants('Plants');

  const DrawingCategory(this.label);
  final String label;
}

/// A ready-made colouring page, drawn in code as clean closed outlines.
class Drawing {
  const Drawing(this.id, this.name, this.category, this._draw);

  final String id;
  final String name;
  final DrawingCategory category;
  final void Function(Pen pen) _draw;

  /// Paints the line art (black on transparent) to fill [size].
  void paintLines(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    _draw(Pen(canvas));
    canvas.restore();
  }
}
