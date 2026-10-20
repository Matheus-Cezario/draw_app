import 'package:draw_app/core/library/catalog.dart';
import 'package:draw_app/core/library/drawing.dart';
import 'package:draw_app/core/library/render.dart';
import 'package:draw_app/core/scan/scan_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every category has drawings and ids are unique', () {
    for (final category in DrawingCategory.values) {
      expect(drawingsIn(category), isNotEmpty, reason: category.label);
    }
    final ids = kDrawings.map((d) => d.id).toSet();
    expect(ids.length, kDrawings.length);
  });

  testWidgets('every drawing scans into paintable closed regions', (tester) async {
    await tester.runAsync(() async {
      for (final drawing in kDrawings) {
        final picture = await renderDrawing(drawing, side: 600);
        final scan = scanLineArt(
          picture.rgba,
          picture.width,
          picture.height,
          const ScanParams(gapClosing: 1),
        );
        expect(scan.regionCount, greaterThanOrEqualTo(5), reason: drawing.id);

        // The outside must be a different region from the inside of the
        // drawing, i.e. outlines are closed (no leaking into everything).
        final counts = <int, int>{};
        for (final id in scan.regions) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
        final biggest = counts.values.reduce((a, b) => a > b ? a : b);
        expect(biggest / scan.regions.length, lessThan(0.9), reason: '${drawing.id} leaks');
      }
    });
  });
}
