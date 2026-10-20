import 'dart:math' as math;
import 'dart:ui';

import 'drawing.dart';
import 'pen.dart';

void _sunflower(Pen p) {
  // Leaves and stem, then petals around the face.
  p.shape(Path()
    ..moveTo(47, 80)
    ..quadraticBezierTo(30, 64, 20, 72)
    ..quadraticBezierTo(30, 88, 47, 84)
    ..close());
  p.shape(Path()
    ..moveTo(53, 70)
    ..quadraticBezierTo(70, 54, 80, 62)
    ..quadraticBezierTo(70, 76, 53, 74)
    ..close());
  p.rect(47, 44, 53, 98, 2);
  for (var i = 0; i < 12; i++) {
    p.rotated(50, 30, i * 30.0, () => p.oval(50, 10, 6, 11));
  }
  p.circle(50, 30, 13);
  for (var i = 0; i < 7; i++) {
    final a = i * 2.4;
    final r = 1.6 + i * 1.4;
    p.dot(50 + r * math.cos(a), 30 + r * math.sin(a), 1.2);
  }
  p.line(30, 98, 70, 98);
}

void _appleTree(Pen p) {
  // Trunk with two branches.
  p.shape(Path()
    ..moveTo(43, 98)
    ..lineTo(46, 60)
    ..lineTo(34, 46)
    ..lineTo(38, 42)
    ..lineTo(48, 52)
    ..lineTo(50, 40)
    ..lineTo(55, 40)
    ..lineTo(54, 52)
    ..lineTo(64, 42)
    ..lineTo(68, 46)
    ..lineTo(55, 60)
    ..lineTo(58, 98)
    ..close());
  p.union([
    Pen.ovalPath(28, 40, 17, 15),
    Pen.ovalPath(50, 26, 20, 17),
    Pen.ovalPath(72, 40, 17, 15),
    Pen.ovalPath(38, 56, 16, 13),
    Pen.ovalPath(62, 56, 16, 13),
    Pen.ovalPath(50, 44, 22, 18),
  ]);
  for (final c in const [(34.0, 40.0), (56.0, 28.0), (68.0, 48.0), (46.0, 54.0), (24.0, 52.0), (76.0, 32.0)]) {
    p.circle(c.$1, c.$2, 4.4);
    p.line(c.$1, c.$2 - 4.4, c.$1 + 1.5, c.$2 - 7);
  }
  p.line(20, 98, 80, 98);
  p.stroke(Path()
    ..moveTo(10, 98)
    ..lineTo(12, 92)
    ..lineTo(14, 98)
    ..moveTo(86, 98)
    ..lineTo(88, 91)
    ..lineTo(90, 98));
}

void _cactus(Pen p) {
  p.union([
    Pen.rrectPath(42, 20, 58, 76, 8),
    Pen.rrectPath(24, 40, 35, 66, 5.5),
    Pen.rrectPath(24, 58, 48, 66, 4),
    Pen.rrectPath(65, 30, 76, 56, 5.5),
    Pen.rrectPath(52, 48, 76, 56, 4),
  ]);
  for (final s in const [(46.0, 34.0), (54.0, 44.0), (47.0, 56.0), (53.0, 68.0), (29.0, 48.0), (70.0, 40.0)]) {
    p.line(s.$1 - 1.5, s.$2, s.$1 + 1.5, s.$2 - 2);
  }
  // Little flower on top.
  for (var i = 0; i < 5; i++) {
    p.rotated(50, 15, i * 72.0, () => p.oval(50, 10.5, 2.6, 3.6));
  }
  p.circle(50, 15, 2.2);
  p.shape(Path()
    ..moveTo(30, 78)
    ..lineTo(70, 78)
    ..lineTo(65, 98)
    ..lineTo(35, 98)
    ..close());
  p.rect(28, 72, 72, 80, 2);
  p.line(36, 88, 64, 88);
}

void _tulips(Pen p) {
  void tulip(double cx, double top, double stemBottom) {
    // Stem and leaf first, then the flower.
    p.rect(cx - 1.8, top + 14, cx + 1.8, stemBottom, 1);
    p.shape(Path()
      ..moveTo(cx, stemBottom)
      ..quadraticBezierTo(cx - 14, stemBottom - 18, cx - 12, stemBottom - 36)
      ..quadraticBezierTo(cx + 1, stemBottom - 24, cx, stemBottom)
      ..close());
    p.shape(Path()
      ..moveTo(cx - 11, top)
      ..lineTo(cx - 5, top + 7)
      ..lineTo(cx, top - 3)
      ..lineTo(cx + 5, top + 7)
      ..lineTo(cx + 11, top)
      ..quadraticBezierTo(cx + 14, top + 20, cx, top + 24)
      ..quadraticBezierTo(cx - 14, top + 20, cx - 11, top)
      ..close());
    p.stroke(Path()
      ..moveTo(cx, top + 9)
      ..lineTo(cx, top + 22));
  }

  tulip(24, 30, 92);
  tulip(76, 34, 92);
  tulip(50, 18, 92);
  p.line(10, 92, 90, 92);
}

const List<Drawing> plantDrawings = [
  Drawing('sunflower', 'Sunflower', DrawingCategory.plants, _sunflower),
  Drawing('apple_tree', 'Apple tree', DrawingCategory.plants, _appleTree),
  Drawing('cactus', 'Cactus', DrawingCategory.plants, _cactus),
  Drawing('tulips', 'Tulips', DrawingCategory.plants, _tulips),
];
