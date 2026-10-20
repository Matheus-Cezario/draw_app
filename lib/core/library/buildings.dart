import 'dart:math' as math;
import 'dart:ui';

import 'drawing.dart';
import 'pen.dart';

void _house(Pen p) {
  // Sun.
  p.circle(14, 14, 8);
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    p.line(14 + 11.5 * math.cos(a), 14 + 11.5 * math.sin(a), 14 + 15.5 * math.cos(a), 14 + 15.5 * math.sin(a));
  }
  p.rect(62, 22, 72, 46, 1);
  p.circle(69, 15, 3.2);
  p.circle(73, 8, 2.6);
  p.rect(24, 46, 76, 90, 1);
  p.poly([17, 48, 50, 20, 83, 48]);
  p.rect(44, 62, 58, 90, 7);
  p.dot(54.5, 77, 1.2);
  for (final x in const [30.0, 60.0]) {
    p.rect(x, 54, x + 11, 65, 1);
    p.line(x + 5.5, 54, x + 5.5, 65);
    p.line(x, 59.5, x + 11, 59.5);
  }
  p.line(4, 90, 96, 90);
  p.stroke(Path()
    ..moveTo(8, 90)
    ..lineTo(10, 85)
    ..lineTo(12, 90)
    ..moveTo(86, 90)
    ..lineTo(88, 84)
    ..lineTo(90, 90));
}

void _tallHouse(Pen p) {
  p.rect(26, 34, 74, 90, 1);
  p.poly([19, 36, 50, 10, 81, 36]);
  p.circle(50, 25, 5.5);
  p.line(26, 62, 74, 62);
  for (final x in const [32.0, 58.0]) {
    p.rect(x, 41, x + 10, 54, 1);
    p.line(x + 5, 41, x + 5, 54);
  }
  p.rect(32, 68, 42, 80, 1);
  p.rect(56, 66, 70, 90, 6);
  p.dot(66, 79, 1.2);
  p.rect(28, 56, 48, 60, 1);
  p.line(4, 90, 96, 90);
  p.line(20, 90, 20, 82);
  p.line(80, 90, 80, 82);
}

void _castle(Pen p) {
  // Towers.
  p.rect(12, 48, 30, 90, 1);
  p.rect(70, 48, 88, 90, 1);
  p.poly([10, 48, 21, 26, 32, 48]);
  p.poly([68, 48, 79, 26, 90, 48]);
  p.line(21, 26, 21, 14);
  p.poly([21, 14, 32, 18, 21, 22]);
  p.line(79, 26, 79, 14);
  p.poly([79, 14, 68, 18, 79, 22]);
  p.rect(18, 56, 24, 66, 3);
  p.rect(76, 56, 82, 66, 3);
  // Keep with battlements.
  p.shape(Path()
    ..moveTo(32, 90)
    ..lineTo(32, 34)
    ..lineTo(39, 34)
    ..lineTo(39, 41)
    ..lineTo(46, 41)
    ..lineTo(46, 34)
    ..lineTo(54, 34)
    ..lineTo(54, 41)
    ..lineTo(61, 41)
    ..lineTo(61, 34)
    ..lineTo(68, 34)
    ..lineTo(68, 90)
    ..close());
  p.shape(Path()
    ..moveTo(43, 90)
    ..lineTo(43, 72)
    ..quadraticBezierTo(50, 60, 57, 72)
    ..lineTo(57, 90)
    ..close());
  p.rect(47, 48, 53, 58, 3);
  p.line(4, 90, 96, 90);
}

void _barn(Pen p) {
  // Silo behind the barn.
  p.rect(82, 42, 94, 90, 1);
  p.shape(Path()
    ..moveTo(82, 42)
    ..quadraticBezierTo(88, 28, 94, 42)
    ..close());
  p.shape(Path()
    ..moveTo(14, 90)
    ..lineTo(14, 52)
    ..lineTo(27, 31)
    ..lineTo(73, 31)
    ..lineTo(86, 52)
    ..lineTo(86, 90)
    ..close());
  p.rect(35, 56, 65, 90, 1);
  p.line(35, 56, 65, 90);
  p.line(65, 56, 35, 90);
  p.rect(43, 38, 57, 49, 1);
  p.line(50, 38, 50, 49);
  p.line(4, 90, 96, 90);
}

const List<Drawing> houseDrawings = [
  Drawing('house', 'Sunny house', DrawingCategory.houses, _house),
  Drawing('tall_house', 'Big house', DrawingCategory.houses, _tallHouse),
  Drawing('castle', 'Castle', DrawingCategory.houses, _castle),
  Drawing('barn', 'Farm barn', DrawingCategory.houses, _barn),
];
