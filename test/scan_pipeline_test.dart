import 'dart:typed_data';

import 'package:draw_app/core/scan/scan_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

/// White canvas with helpers to draw black lines.
class Canvas8 {
  Canvas8(this.w, this.h) : rgba = Uint8List(w * h * 4)..fillRange(0, w * h * 4, 255);
  final int w, h;
  final Uint8List rgba;

  void dot(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final o = (y * w + x) * 4;
    rgba[o] = rgba[o + 1] = rgba[o + 2] = 0;
  }

  void rect(int x0, int y0, int x1, int y1, {int t = 3, List<int> gapX = const []}) {
    for (var x = x0; x <= x1; x++) {
      for (var k = 0; k < t; k++) {
        dot(x, y0 + k);
        dot(x, y1 - k);
      }
    }
    for (var y = y0; y <= y1; y++) {
      for (var k = 0; k < t; k++) {
        dot(x0 + k, y);
        dot(x1 - k, y);
      }
    }
  }

  void erase(int x0, int y0, int x1, int y1) {
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final o = (y * w + x) * 4;
        rgba[o] = rgba[o + 1] = rgba[o + 2] = 255;
      }
    }
  }
}

void main() {
  test('closed square gives inside and outside regions', () {
    final c = Canvas8(100, 100)..rect(20, 20, 79, 79);
    final r = scanLineArt(c.rgba, 100, 100);
    expect(r.regionCount, 2);
    final inside = r.regions[50 * 100 + 50];
    final outside = r.regions[5 * 100 + 5];
    expect(inside, isNot(outside));
    // Pixels on the line belong to a region (no holes in the map).
    expect(r.regions.every((v) => v > 0), isTrue);
    // Lines layer is opaque on the stroke and transparent elsewhere.
    expect(r.linesRgba[(21 * 100 + 50) * 4 + 3], greaterThan(150));
    expect(r.linesRgba[(50 * 100 + 50) * 4 + 3], 0);
  });

  test('small gap in the line does not leak', () {
    final c = Canvas8(100, 100)
      ..rect(20, 20, 79, 79)
      ..erase(45, 18, 47, 24); // 3 px gap in the top edge
    final r = scanLineArt(c.rgba, 100, 100);
    expect(r.regions[50 * 100 + 50], isNot(r.regions[5 * 100 + 5]));
  });

  test('big gap leaks', () {
    final c = Canvas8(100, 100)
      ..rect(20, 20, 79, 79)
      ..erase(30, 18, 60, 24);
    final r = scanLineArt(c.rgba, 100, 100);
    expect(r.regions[50 * 100 + 50], r.regions[5 * 100 + 5]);
  });

  test('isolated specks are ignored', () {
    final c = Canvas8(100, 100)
      ..rect(20, 20, 79, 79)
      ..dot(5, 5)
      ..dot(6, 5);
    final r = scanLineArt(c.rgba, 100, 100);
    expect(r.regionCount, 2);
    expect(r.linesRgba[(5 * 100 + 5) * 4 + 3], 0);
  });

  test('two nested shapes give three regions', () {
    final c = Canvas8(120, 120)
      ..rect(10, 10, 109, 109)
      ..rect(40, 40, 79, 79);
    final r = scanLineArt(c.rgba, 120, 120);
    expect(r.regionCount, 3);
  });
}
