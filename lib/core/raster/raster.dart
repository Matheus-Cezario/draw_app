import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Pixel helpers shared by the tools and the storage layer.

Future<ui.Image> imageFromRgba(Uint8List rgba, int width, int height) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    width,
    height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  return completer.future;
}

Future<Uint8List> rgbaFromImage(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

Future<Uint8List> pngFromImage(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> imageFromEncoded(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Renders [paint] on top of [base] (which may be null) and returns the result
/// as a new image of the given size.
Future<ui.Image> composeImage(
  ui.Image? base,
  int width,
  int height,
  void Function(ui.Canvas canvas) paint,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.saveLayer(null, ui.Paint());
  if (base != null) canvas.drawImage(base, ui.Offset.zero, ui.Paint());
  paint(canvas);
  canvas.restore();
  return recorder.endRecording().toImage(width, height);
}
