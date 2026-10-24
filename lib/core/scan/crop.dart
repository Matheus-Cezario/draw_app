import 'dart:typed_data';

import 'scan_service.dart';

/// A crop rectangle in normalised coordinates (0..1 of the picture).
class CropRect {
  const CropRect(this.left, this.top, this.right, this.bottom);

  static const CropRect full = CropRect(0, 0, 1, 1);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  bool get isFull => left <= 0 && top <= 0 && right >= 1 && bottom >= 1;

  CropRect copyWith({double? left, double? top, double? right, double? bottom}) =>
      CropRect(left ?? this.left, top ?? this.top, right ?? this.right, bottom ?? this.bottom);
}

/// Returns the part of [source] inside [crop]. Always at least 1x1 pixel.
DecodedPicture cropPicture(DecodedPicture source, CropRect crop) {
  if (crop.isFull) return source;
  final x0 = (crop.left * source.width).round().clamp(0, source.width - 1);
  final y0 = (crop.top * source.height).round().clamp(0, source.height - 1);
  final x1 = (crop.right * source.width).round().clamp(x0 + 1, source.width);
  final y1 = (crop.bottom * source.height).round().clamp(y0 + 1, source.height);
  final w = x1 - x0, h = y1 - y0;
  final out = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    final from = ((y0 + y) * source.width + x0) * 4;
    out.setRange(y * w * 4, (y + 1) * w * 4, source.rgba, from);
  }
  return DecodedPicture(out, w, h);
}

/// Returns [source] turned a quarter turn clockwise.
DecodedPicture rotatePictureClockwise(DecodedPicture source) {
  final w = source.width, h = source.height;
  final out = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final from = (y * w + x) * 4;
      final to = (x * h + (h - 1 - y)) * 4;
      out.setRange(to, to + 4, source.rgba, from);
    }
  }
  return DecodedPicture(out, h, w);
}
