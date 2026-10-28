/// The sections of the colouring book. Each value is named after its folder in
/// `assets/library` (see tools/build_library.py).
enum DrawingCategory {
  animals('Animals'),
  dinosaurs('Dinosaurs'),
  ocean('Ocean'),
  forest('Forest'),
  cars('Cars'),
  train('Trains'),
  city('City'),
  space('Space'),
  princess('Princesses'),
  toys('Toys'),
  plush('Plush toys'),
  food('Food');

  const DrawingCategory(this.label);
  final String label;
}

/// A ready-made colouring page: black outlines on white, shipped as a PNG.
class Drawing {
  const Drawing(this.id, this.name, this.category, this.asset);

  /// `<category>/<file name without extension>`, unique.
  final String id;
  final String name;
  final DrawingCategory category;

  /// Path of the PNG in the asset bundle.
  final String asset;
}
