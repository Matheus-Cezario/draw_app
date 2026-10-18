import 'dart:ui' as ui;

import '../document/document.dart';
import 'raster.dart';

/// Paints every visible layer (and the locked lines) onto [canvas].
/// [overLayer] lets the editor inject live content inside one layer.
void paintDocument(
  ui.Canvas canvas,
  DrawDocument doc, {
  Layer? overLayer,
  void Function(ui.Canvas)? paintOverLayer,
}) {
  for (final layer in doc.layers) {
    if (!layer.visible) continue;
    final live = identical(layer, overLayer) ? paintOverLayer : null;
    if (layer.image == null && live == null) continue;
    canvas.saveLayer(
      null,
      ui.Paint()..color = ui.Color.fromRGBO(0, 0, 0, layer.opacity),
    );
    if (layer.image != null) {
      canvas.drawImage(layer.image!, ui.Offset.zero, ui.Paint());
    }
    live?.call(canvas);
    canvas.restore();
  }
  if (doc.lines != null) {
    canvas.drawImage(doc.lines!, ui.Offset.zero, ui.Paint());
  }
}

/// Flattens the document over white paper into one image.
Future<ui.Image> flattenDocument(DrawDocument doc) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, doc.width.toDouble(), doc.height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  paintDocument(canvas, doc);
  return recorder.endRecording().toImage(doc.width, doc.height);
}

/// Small preview image for the gallery.
Future<ui.Image> thumbnail(DrawDocument doc, {int maxSide = 320}) async {
  final full = await flattenDocument(doc);
  final scale = maxSide / (doc.width > doc.height ? doc.width : doc.height);
  final w = (doc.width * scale).round(), h = (doc.height * scale).round();
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    full,
    ui.Rect.fromLTWH(0, 0, doc.width.toDouble(), doc.height.toDouble()),
    ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  return recorder.endRecording().toImage(w, h);
}

Future<List<int>> flattenedPng(DrawDocument doc) async =>
    pngFromImage(await flattenDocument(doc));
