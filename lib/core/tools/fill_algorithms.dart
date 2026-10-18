import 'dart:typed_data';

/// Paints every pixel of region [regionId] with the colour (r, g, b, a).
///
/// Returns the number of pixels written.
int fillRegion(
  Uint8List rgba,
  Int32List regions,
  int regionId,
  int r,
  int g,
  int b,
  int a,
) {
  var count = 0;
  for (var i = 0; i < regions.length; i++) {
    if (regions[i] != regionId) continue;
    final o = i * 4;
    rgba[o] = r;
    rgba[o + 1] = g;
    rgba[o + 2] = b;
    rgba[o + 3] = a;
    count++;
  }
  return count;
}

/// Classic scanline-free flood fill with colour tolerance, used on blank
/// canvases where there is no region map.
///
/// [reference] is the picture that decides what is "the same colour" (usually
/// the flattened drawing); the result is written to [target].
int floodFillTolerance({
  required Uint8List reference,
  required Uint8List target,
  required int width,
  required int height,
  required int startX,
  required int startY,
  required int r,
  required int g,
  required int b,
  required int a,
  int tolerance = 32,
}) {
  final start = (startY * width + startX) * 4;
  final sr = reference[start], sg = reference[start + 1];
  final sb = reference[start + 2], sa = reference[start + 3];

  bool matches(int index) {
    final o = index * 4;
    return (reference[o] - sr).abs() <= tolerance &&
        (reference[o + 1] - sg).abs() <= tolerance &&
        (reference[o + 2] - sb).abs() <= tolerance &&
        (reference[o + 3] - sa).abs() <= tolerance;
  }

  final visited = Uint8List(width * height);
  final stack = Int32List(width * height);
  var sp = 0, count = 0;
  stack[sp++] = startY * width + startX;
  visited[startY * width + startX] = 1;
  while (sp > 0) {
    final p = stack[--sp];
    final o = p * 4;
    target[o] = r;
    target[o + 1] = g;
    target[o + 2] = b;
    target[o + 3] = a;
    count++;
    final x = p % width, y = p ~/ width;
    void push(int q) {
      if (visited[q] == 0 && matches(q)) {
        visited[q] = 1;
        stack[sp++] = q;
      }
    }

    if (x > 0) push(p - 1);
    if (x < width - 1) push(p + 1);
    if (y > 0) push(p - width);
    if (y < height - 1) push(p + width);
  }
  return count;
}
