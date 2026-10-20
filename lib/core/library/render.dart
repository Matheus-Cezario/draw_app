import 'dart:ui' as ui;

import '../raster/raster.dart';
import '../scan/scan_service.dart';
import 'drawing.dart';

/// Rasterises a ready-made drawing (black lines on white) so it goes through
/// the very same scan as a photographed picture.
Future<DecodedPicture> renderDrawing(Drawing drawing, {int side = 1200}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final size = ui.Size(side.toDouble(), side.toDouble());
  canvas.drawRect(ui.Offset.zero & size, ui.Paint()..color = const ui.Color(0xFFFFFFFF));
  drawing.paintLines(canvas, size);
  final image = await recorder.endRecording().toImage(side, side);
  final rgba = await rgbaFromImage(image);
  image.dispose();
  return DecodedPicture(rgba, side, side);
}
