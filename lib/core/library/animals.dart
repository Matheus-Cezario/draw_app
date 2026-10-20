import 'dart:math' as math;
import 'dart:ui';

import 'drawing.dart';
import 'pen.dart';

void _cat(Pen p) {
  // Tail behind the body.
  p.shape(Path()
    ..moveTo(68, 90)
    ..cubicTo(94, 92, 99, 62, 83, 54)
    ..lineTo(79, 61)
    ..cubicTo(88, 66, 86, 82, 68, 82)
    ..close());
  p.oval(50, 74, 24, 22);
  p.oval(50, 78, 12, 14);
  p.oval(37, 94, 9, 5);
  p.oval(63, 94, 9, 5);
  // Ears, then head on top.
  p.poly([27, 32, 29, 8, 46, 22]);
  p.poly([73, 32, 71, 8, 54, 22]);
  p.oval(50, 40, 26, 22);
  p.poly([32, 26, 33, 17, 39, 23], fill: false);
  p.poly([68, 26, 67, 17, 61, 23], fill: false);
  p.dot(40, 38, 2.8);
  p.dot(60, 38, 2.8);
  p.solid([47, 45, 53, 45, 50, 49]);
  p.stroke(Path()
    ..moveTo(50, 49)
    ..quadraticBezierTo(46, 54, 41, 50)
    ..moveTo(50, 49)
    ..quadraticBezierTo(54, 54, 59, 50));
  p.line(22, 43, 35, 46);
  p.line(22, 50, 35, 49);
  p.line(78, 43, 65, 46);
  p.line(78, 50, 65, 49);
  p.line(44, 19, 45, 25);
  p.line(50, 18, 50, 24);
  p.line(56, 19, 55, 25);
}

void _fish(Pen p) {
  // Seaweed.
  p.shape(Path()
    ..moveTo(8, 100)
    ..cubicTo(4, 85, 16, 80, 10, 66)
    ..cubicTo(20, 78, 14, 88, 18, 100)
    ..close());
  p.shape(Path()
    ..moveTo(82, 100)
    ..cubicTo(78, 88, 90, 84, 84, 72)
    ..cubicTo(94, 84, 88, 92, 92, 100)
    ..close());
  p.poly([70, 50, 94, 30, 89, 50, 94, 70]);
  p.shape(Path()
    ..moveTo(38, 33)
    ..quadraticBezierTo(50, 12, 63, 34)
    ..close());
  p.shape(Path()
    ..moveTo(42, 67)
    ..quadraticBezierTo(50, 82, 59, 66)
    ..close());
  p.oval(48, 50, 29, 20);
  p.circle(34, 45, 4.6);
  p.dot(34, 45, 2);
  p.stroke(Path()
    ..moveTo(20, 54)
    ..quadraticBezierTo(25, 58, 30, 54));
  p.stroke(Path()
    ..moveTo(41, 38)
    ..quadraticBezierTo(35, 50, 41, 62));
  p.stroke(Path()
    ..moveTo(53, 40)
    ..quadraticBezierTo(58, 45, 53, 50)
    ..moveTo(61, 43)
    ..quadraticBezierTo(66, 48, 61, 53)
    ..moveTo(53, 54)
    ..quadraticBezierTo(58, 59, 53, 64));
  p.circle(14, 32, 4);
  p.circle(21, 19, 3);
  p.circle(10, 13, 2.2);
}

void _butterfly(Pen p) {
  for (final right in [false, true]) {
    double x(double v) => right ? 100 - v : v;
    p.shape(Path()
      ..moveTo(x(48), 46)
      ..cubicTo(x(30), 6, x(3), 22, x(14), 42)
      ..cubicTo(x(18), 52, x(38), 54, x(48), 48)
      ..close());
    p.shape(Path()
      ..moveTo(x(48), 52)
      ..cubicTo(x(30), 52, x(12), 60, x(19), 77)
      ..cubicTo(x(26), 91, x(44), 80, x(48), 58)
      ..close());
    p.circle(x(25), 33, 6);
    p.circle(x(31), 70, 5);
    p.circle(x(36), 46, 2.4);
  }
  p.oval(50, 54, 3.8, 24);
  p.circle(50, 26, 5.2);
  p.stroke(Path()
    ..moveTo(48, 22)
    ..quadraticBezierTo(42, 10, 35, 11)
    ..moveTo(52, 22)
    ..quadraticBezierTo(58, 10, 65, 11));
  p.circle(35, 11, 2);
  p.circle(65, 11, 2);
}

void _turtle(Pen p) {
  // Legs and tail behind the shell, then head.
  for (final c in const [(25.0, 33.0), (75.0, 33.0), (25.0, 71.0), (75.0, 71.0)]) {
    p.circle(c.$1, c.$2, 9);
  }
  p.poly([44, 80, 50, 96, 56, 80]);
  p.circle(50, 17, 10);
  p.dot(46, 15, 1.7);
  p.dot(54, 15, 1.7);
  p.stroke(Path()
    ..moveTo(46, 21)
    ..quadraticBezierTo(50, 24, 54, 21));
  // Shell with a hexagon pattern.
  p.circle(50, 52, 27);
  final inner = <double>[];
  for (var i = 0; i < 6; i++) {
    final a = (i * 60 - 90) * math.pi / 180;
    inner
      ..add(50 + 11 * math.cos(a))
      ..add(52 + 11 * math.sin(a));
    final o = Path()
      ..moveTo(50 + 11 * math.cos(a), 52 + 11 * math.sin(a))
      ..lineTo(50 + 27 * math.cos(a), 52 + 27 * math.sin(a));
    p.stroke(o);
  }
  p.poly(inner, fill: false);
}

const List<Drawing> animalDrawings = [
  Drawing('cat', 'Kitty', DrawingCategory.animals, _cat),
  Drawing('fish', 'Fish', DrawingCategory.animals, _fish),
  Drawing('butterfly', 'Butterfly', DrawingCategory.animals, _butterfly),
  Drawing('turtle', 'Turtle', DrawingCategory.animals, _turtle),
];
