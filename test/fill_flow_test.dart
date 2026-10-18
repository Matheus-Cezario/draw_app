import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:draw_app/core/document/document.dart';
import 'package:draw_app/core/raster/raster.dart';
import 'package:draw_app/core/scan/scan_pipeline.dart';
import 'package:draw_app/core/storage/project_repository.dart';
import 'package:draw_app/features/editor/editor_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository extends ProjectRepository {
  @override
  Future<void> save(DrawDocument doc, {bool writeStatic = false}) async {}
}

void main() {
  testWidgets('bucket fills a scanned region and undo restores it',
      (tester) async {
    await tester.runAsync(() async {
      const size = 100;
      final rgba = Uint8List(size * size * 4)..fillRange(0, size * size * 4, 255);
      for (var i = 20; i < 80; i++) {
        for (final (x, y) in [(i, 20), (i, 79), (20, i), (79, i)]) {
          for (var k = 0; k < 3; k++) {
            for (final (dx, dy) in [(k, 0), (0, k), (-k, 0), (0, -k)]) {
              final o = ((y + dy) * size + x + dx) * 4;
              rgba[o] = rgba[o + 1] = rgba[o + 2] = 0;
            }
          }
        }
      }
      final scan = scanLineArt(rgba, size, size);
      final doc = DrawDocument(
        id: 't',
        name: 't',
        width: size,
        height: size,
        layers: [Layer(id: 'l', name: 'l')],
        lines: await imageFromRgba(scan.linesRgba, size, size),
        regions: scan.regions,
        regionCount: scan.regionCount,
      );
      final c = EditorController(doc, _FakeRepository());

      await c.fillAt(const ui.Offset(50, 50));
      var pixels = await rgbaFromImage(doc.layers.first.image!);
      int alphaAt(int x, int y) => pixels[(y * size + x) * 4 + 3];
      expect(alphaAt(50, 50), 255);
      expect(alphaAt(22, 22), 255, reason: 'fill reaches the line (no halo)');
      expect(alphaAt(5, 5), 0, reason: 'outside region untouched');

      await c.undo();
      expect(doc.layers.first.image, isNull);
      c.dispose();
    });
  });
}
