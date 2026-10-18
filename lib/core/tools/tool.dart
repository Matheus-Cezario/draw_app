import 'dart:typed_data';
import 'dart:ui' as ui;

import '../document/document.dart';

/// What a tool is allowed to ask of the editor (the "view model" side).
///
/// Tools depend on this narrow interface instead of the concrete controller so
/// they stay testable and the dependency arrow keeps pointing inward.
abstract interface class ToolHost {
  DrawDocument get document;
  Layer get activeLayer;
  ui.Color get color;
  double get size;
  double get opacity;

  void setColor(ui.Color color);

  /// Asks the view to redraw (cheap; used while dragging).
  void requestRepaint();

  /// Bakes [paint] into [layer] and records an undo step.
  Future<void> commitLayer(Layer layer, void Function(ui.Canvas) paint);

  /// Fills the region (or flat colour area) under [point] on the active layer.
  Future<void> fillAt(ui.Offset point);

  /// Flattened picture of everything visible, as RGBA bytes.
  Future<Uint8List> flattenedRgba();

  /// Asks the UI for a text string to place at [point].
  void requestText(ui.Offset point);
}

/// Strategy interface for every drawing tool (decision D8).
///
/// Coordinates are always in document pixels.
abstract class Tool {
  Tool(this.host);
  final ToolHost host;

  void onDown(ui.Offset point);
  void onMove(ui.Offset point);
  Future<void> onUp();

  /// Abandons the gesture in progress (e.g. a second finger landed).
  void onCancel() {}

  /// Commits any pending state (floating selection, ...). Called before the
  /// tool or active layer changes and before saving.
  Future<void> finish() async {}

  /// Painted *inside* the active layer, so it can erase (`BlendMode.clear`).
  /// The very same code is used to bake the result, which keeps the live
  /// preview and the final pixels identical.
  void paintLive(ui.Canvas canvas) {}

  /// Painted above all layers (selection outline, shape guides...).
  void paintOverlay(ui.Canvas canvas, double scale) {}
}
