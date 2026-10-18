import 'dart:ui' as ui;

import 'tool.dart';

/// Bucket: one tap fills the region under the finger.
class FillTool extends Tool {
  FillTool(super.host);

  bool _busy = false;

  // The fill runs on pointer-down so it feels instant.
  @override
  void onDown(ui.Offset point) {
    if (_busy) return;
    _busy = true;
    host.fillAt(point).whenComplete(() => _busy = false);
  }

  @override
  void onMove(ui.Offset point) {}

  @override
  Future<void> onUp() async {}
}

/// Picks the colour under the finger from the flattened drawing.
class EyedropperTool extends Tool {
  EyedropperTool(super.host);

  ui.Offset? _last;

  @override
  void onDown(ui.Offset point) => _last = point;

  @override
  void onMove(ui.Offset point) => _last = point;

  @override
  Future<void> onUp() async {
    final p = _last;
    if (p == null) return;
    _last = null;
    final doc = host.document;
    final x = p.dx.floor(), y = p.dy.floor();
    if (x < 0 || y < 0 || x >= doc.width || y >= doc.height) return;
    final rgba = await host.flattenedRgba();
    final o = (y * doc.width + x) * 4;
    host.setColor(ui.Color.fromARGB(255, rgba[o], rgba[o + 1], rgba[o + 2]));
  }
}

/// Asks the UI for a string and places it where the user tapped.
class TextTool extends Tool {
  TextTool(super.host);

  ui.Offset? _last;

  @override
  void onDown(ui.Offset point) => _last = point;

  @override
  void onMove(ui.Offset point) => _last = point;

  @override
  Future<void> onUp() async {
    final p = _last;
    _last = null;
    if (p != null) host.requestText(p);
  }
}
