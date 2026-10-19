import 'dart:typed_data';

import 'package:draw_app/core/scan/crop.dart';
import 'package:draw_app/core/scan/scan_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// 4x4 picture where pixel (x, y) has red = x and green = y.
DecodedPicture _grid() {
  final rgba = Uint8List(4 * 4 * 4);
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      final o = (y * 4 + x) * 4;
      rgba[o] = x;
      rgba[o + 1] = y;
      rgba[o + 3] = 255;
    }
  }
  return DecodedPicture(rgba, 4, 4);
}

void main() {
  test('full crop returns the same picture', () {
    final p = _grid();
    expect(identical(cropPicture(p, CropRect.full), p), isTrue);
  });

  test('crops the bottom-right quarter', () {
    final out = cropPicture(_grid(), const CropRect(0.5, 0.5, 1, 1));
    expect(out.width, 2);
    expect(out.height, 2);
    // First pixel of the result is source pixel (2, 2).
    expect(out.rgba[0], 2);
    expect(out.rgba[1], 2);
    // Last pixel is source pixel (3, 3).
    expect(out.rgba[3 * 4], 3);
    expect(out.rgba[3 * 4 + 1], 3);
  });

  test('never produces an empty picture', () {
    final out = cropPicture(_grid(), const CropRect(0.5, 0.5, 0.5, 0.5));
    expect(out.width, greaterThanOrEqualTo(1));
    expect(out.height, greaterThanOrEqualTo(1));
  });
}
