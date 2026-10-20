import 'dart:math' as math;
import 'dart:ui';

import 'drawing.dart';
import 'pen.dart';

// ---------------------------------------------------------------- Cars ----

void _car(Pen p) {
  p.rect(8, 52, 92, 74, 9);
  p.shape(Path()
    ..moveTo(23, 52)
    ..lineTo(31, 33)
    ..quadraticBezierTo(33, 28, 39, 28)
    ..lineTo(62, 28)
    ..quadraticBezierTo(68, 28, 72, 33)
    ..lineTo(80, 52)
    ..close());
  p.poly([30, 50, 36, 34, 48, 34, 48, 50]);
  p.poly([53, 50, 53, 34, 63, 34, 71, 50]);
  p.line(50, 52, 50, 70);
  p.line(54, 58, 60, 58);
  p.oval(88, 59, 3, 4.5);
  p.rect(8, 57, 13, 64, 2);
  p.wheel(28, 76, 10);
  p.wheel(72, 76, 10);
  // Sun-ray style road line.
  p.line(4, 92, 96, 92);
}

void _bus(Pen p) {
  p.rect(5, 32, 95, 74, 8);
  for (var i = 0; i < 5; i++) {
    p.rect(10.0 + i * 14, 39, 21.0 + i * 14, 52, 2);
  }
  p.rect(80, 36, 92, 72, 3);
  p.rect(83, 40, 89, 54, 1.5);
  p.line(5, 61, 95, 61);
  p.circle(93, 66, 2.5);
  p.circle(9, 66, 2.5);
  p.rect(30, 24, 50, 32, 2);
  p.wheel(25, 77, 10);
  p.wheel(72, 77, 10);
  p.line(4, 92, 96, 92);
}

void _truck(Pen p) {
  // Exhaust smoke.
  p.circle(60, 30, 4);
  p.circle(56, 22, 3.2);
  p.circle(61, 15, 2.6);
  p.rect(58, 31, 62, 44, 1);
  p.rect(6, 34, 54, 70, 3);
  for (final x in const [18.0, 30.0, 42.0]) {
    p.line(x, 34, x, 70);
  }
  p.poly([58, 42, 73, 42, 85, 57, 94, 57, 94, 74, 58, 74]);
  p.poly([62, 46, 71, 46, 79, 57, 62, 57]);
  p.rect(6, 69, 94, 76, 2);
  p.rect(91, 62, 95, 68, 1);
  p.wheel(22, 79, 9);
  p.wheel(46, 79, 9);
  p.wheel(78, 79, 9);
  p.line(4, 93, 96, 93);
}

void _raceCar(Pen p) {
  // Rear wing.
  p.rect(3, 34, 21, 39, 1.5);
  p.line(10, 39, 10, 54);
  p.shape(Path()
    ..moveTo(5, 66)
    ..lineTo(5, 55)
    ..quadraticBezierTo(8, 50, 24, 49)
    ..lineTo(40, 36)
    ..quadraticBezierTo(46, 32, 56, 36)
    ..lineTo(63, 46)
    ..lineTo(86, 50)
    ..quadraticBezierTo(95, 53, 95, 66)
    ..close());
  p.poly([42, 47, 48, 39, 56, 39, 60, 47]);
  p.circle(44, 58, 6.2);
  p.line(44, 54, 44, 62);
  p.line(26, 66, 36, 66);
  p.line(52, 66, 82, 66);
  p.wheel(26, 68, 11);
  p.wheel(74, 68, 11);
  p.line(4, 92, 96, 92);
}

// --------------------------------------------------------- Motorbikes ----

void _scooter(Pen p) {
  // Front column and handlebar.
  p.poly([69, 30, 74, 30, 82, 70, 77, 70]);
  p.line(63, 27, 82, 25);
  p.circle(62, 27, 2.2);
  p.circle(80, 33, 5);
  p.shape(Path()
    ..moveTo(15, 62)
    ..quadraticBezierTo(13, 46, 29, 44)
    ..lineTo(50, 44)
    ..lineTo(55, 58)
    ..lineTo(70, 62)
    ..lineTo(68, 74)
    ..lineTo(22, 74)
    ..quadraticBezierTo(13, 74, 15, 62)
    ..close());
  p.rect(20, 36, 52, 45, 4.5);
  p.circle(13, 54, 2.2);
  p.shape(Path()
    ..moveTo(62, 74)
    ..quadraticBezierTo(80, 52, 94, 74)
    ..close());
  p.wheel(24, 78, 12);
  p.wheel(80, 78, 12);
  p.line(4, 94, 96, 94);
}

void _sportBike(Pen p) {
  // Fork first (the fairing covers its top), then body, then wheels.
  p.poly([72, 46, 77, 44, 87, 74, 82, 77]);
  p.rect(6, 62, 38, 68, 3);
  p.rect(36, 60, 62, 74, 4);
  // Tail section, then tank and fairing on top of it.
  p.shape(Path()
    ..moveTo(9, 54)
    ..quadraticBezierTo(13, 45, 30, 45)
    ..lineTo(44, 47)
    ..lineTo(42, 60)
    ..lineTo(11, 60)
    ..close());
  p.shape(Path()
    ..moveTo(30, 47)
    ..quadraticBezierTo(46, 31, 66, 38)
    ..lineTo(81, 49)
    ..quadraticBezierTo(86, 58, 76, 61)
    ..lineTo(38, 62)
    ..close());
  p.poly([64, 38, 72, 25, 77, 43]);
  p.circle(76, 52, 3.6);
  p.line(40, 47, 56, 45);
  p.wheel(24, 78, 13);
  p.wheel(80, 78, 13);
  p.line(4, 95, 96, 95);
}

void _chopper(Pen p) {
  // Long front fork, high handlebars.
  p.poly([60, 46, 64, 43, 84, 73, 80, 77]);
  p.stroke(Path()
    ..moveTo(60, 42)
    ..quadraticBezierTo(58, 22, 74, 20));
  p.circle(75, 20, 2.4);
  p.circle(68, 41, 4.5);
  p.shape(Path()
    ..moveTo(30, 52)
    ..quadraticBezierTo(44, 36, 62, 44)
    ..lineTo(60, 58)
    ..lineTo(32, 60)
    ..close());
  p.shape(Path()
    ..moveTo(8, 54)
    ..quadraticBezierTo(20, 46, 34, 50)
    ..lineTo(34, 58)
    ..lineTo(8, 60)
    ..close());
  p.rect(34, 60, 58, 72, 3);
  p.wheel(20, 77, 15);
  p.wheel(86, 78, 11);
  p.line(4, 94, 96, 94);
}

void _dirtBike(Pen p) {
  // Fork and handlebar, tall number plate, knobby tyres.
  p.poly([68, 40, 73, 38, 85, 74, 80, 77]);
  p.line(62, 33, 80, 30);
  p.rect(36, 56, 58, 70, 3);
  p.shape(Path()
    ..moveTo(8, 50)
    ..lineTo(34, 44)
    ..lineTo(38, 55)
    ..lineTo(12, 57)
    ..close());
  p.shape(Path()
    ..moveTo(32, 42)
    ..quadraticBezierTo(48, 32, 64, 40)
    ..lineTo(60, 57)
    ..lineTo(34, 57)
    ..close());
  p.circle(75, 46, 6.5);
  p.dot(75, 46, 1.4);
  p.wheel(22, 78, 13);
  p.wheel(80, 78, 13);
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6;
    for (final c in const [(22.0, 78.0), (80.0, 78.0)]) {
      p.line(c.$1 + 13 * math.cos(a), c.$2 + 13 * math.sin(a),
          c.$1 + 15.5 * math.cos(a), c.$2 + 15.5 * math.sin(a));
    }
  }
  p.shape(Path()
    ..moveTo(70, 66)
    ..quadraticBezierTo(80, 55, 91, 66)
    ..close());
  p.line(4, 95, 96, 95);
}

const List<Drawing> carDrawings = [
  Drawing('car', 'Little car', DrawingCategory.cars, _car),
  Drawing('bus', 'School bus', DrawingCategory.cars, _bus),
  Drawing('truck', 'Truck', DrawingCategory.cars, _truck),
  Drawing('race_car', 'Race car', DrawingCategory.cars, _raceCar),
];

const List<Drawing> motorcycleDrawings = [
  Drawing('scooter', 'Scooter', DrawingCategory.motorcycles, _scooter),
  Drawing('sport_bike', 'Sport bike', DrawingCategory.motorcycles, _sportBike),
  Drawing('chopper', 'Chopper', DrawingCategory.motorcycles, _chopper),
  Drawing('dirt_bike', 'Dirt bike', DrawingCategory.motorcycles, _dirtBike),
];
