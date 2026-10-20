import 'animals.dart';
import 'buildings.dart';
import 'drawing.dart';
import 'plants.dart';
import 'vehicles.dart';

/// Every ready-made colouring page that ships with the app.
final List<Drawing> kDrawings = [
  ...animalDrawings,
  ...carDrawings,
  ...motorcycleDrawings,
  ...houseDrawings,
  ...plantDrawings,
];

List<Drawing> drawingsIn(DrawingCategory category) =>
    [for (final d in kDrawings) if (d.category == category) d];
