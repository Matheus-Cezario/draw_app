import 'dart:typed_data';
import 'dart:ui' as ui;

/// A raster layer. [image] is null while the layer is still empty.
class Layer {
  Layer({
    required this.id,
    required this.name,
    this.image,
    this.visible = true,
    this.opacity = 1.0,
  });

  final String id;
  String name;
  ui.Image? image;
  bool visible;
  double opacity;

  /// True when [image] changed since it was last written to disk.
  bool dirty = true;
}

/// The model of a drawing: colour layers (bottom to top) plus an optional
/// locked line layer and region map produced by the scan.
class DrawDocument {
  DrawDocument({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.layers,
    this.lines,
    this.regions,
    this.regionCount = 0,
  });

  final String id;
  String name;
  final int width;
  final int height;
  final List<Layer> layers;

  /// Locked outline drawn above every colour layer (scanned drawings only).
  ui.Image? lines;

  /// Region id per pixel (`width * height`), or null for a blank canvas.
  Int32List? regions;
  int regionCount;

  bool get hasScan => regions != null;
}
