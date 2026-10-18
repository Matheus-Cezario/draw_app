import 'dart:math' as math;
import 'dart:typed_data';

/// Parameters of the line-art scan.
class ScanParams {
  const ScanParams({
    this.sensitivity = 0.12,
    this.gapClosing = 2,
    this.minSpeckArea = 6,
    this.minRegionArea = 12,
  });

  /// How much darker than its neighbourhood a pixel must be to count as a
  /// line (0.03 = very sensitive … 0.4 = only strong lines).
  final double sensitivity;

  /// Radius (px) used to seal small gaps in the lines before the regions are
  /// computed. Does not change the visible lines.
  final int gapClosing;

  /// Isolated dark blobs smaller than this are treated as noise.
  final int minSpeckArea;

  /// Enclosed areas smaller than this are merged into the surrounding lines.
  final int minRegionArea;
}

/// Result of scanning an image. All buffers are `width * height` long.
class ScanResult {
  ScanResult({
    required this.width,
    required this.height,
    required this.linesRgba,
    required this.regions,
    required this.regionCount,
  });

  final int width;
  final int height;

  /// Black lines with alpha, transparent elsewhere (RGBA, 4 bytes / pixel).
  final Uint8List linesRgba;

  /// Region id (1..regionCount) of every pixel. Pixels that lie on a line are
  /// assigned to the nearest region, so the map has no holes.
  final Int32List regions;
  final int regionCount;
}

/// Turns an RGBA picture of a drawing into a line layer and a region map.
///
/// Pure Dart on raw bytes so it can run in an isolate and be unit tested.
ScanResult scanLineArt(
  Uint8List rgba,
  int width,
  int height, [
  ScanParams params = const ScanParams(),
]) {
  final n = width * height;
  final gray = _toGray(rgba, n);
  final otsu = _otsu(gray);
  final local = _localMean(gray, width, height);

  // 1. Line mask: clearly dark, or darker than the local neighbourhood.
  final mask = Uint8List(n);
  final veryDark = otsu * 0.6;
  final k = 1 - params.sensitivity;
  for (var i = 0; i < n; i++) {
    final g = gray[i];
    if (g < veryDark || (g < otsu && g < local[i] * k)) mask[i] = 1;
  }

  // 2. Drop isolated specks.
  final labels = Int32List(n);
  final stack = Int32List(n);
  final speckAreas = _label(mask, 1, width, height, labels, stack, eight: true);
  for (var i = 0; i < n; i++) {
    if (mask[i] == 1 && speckAreas[labels[i]] < params.minSpeckArea) {
      mask[i] = 0;
    }
  }

  // 3. Line layer (soft alpha so the strokes keep a smooth edge).
  var ink = 255;
  for (var i = 0; i < n; i++) {
    if (mask[i] == 1 && gray[i] < ink) ink = gray[i];
  }
  final span = math.max(1, otsu - ink);
  final lines = Uint8List(n * 4);
  for (var i = 0; i < n; i++) {
    if (mask[i] == 0) continue;
    final a = ((otsu - gray[i]) * 255 ~/ span).clamp(170, 255);
    lines[i * 4 + 3] = a;
  }

  // 4. Seal gaps, then segment the free space into regions.
  final sealed = params.gapClosing > 0
      ? _dilate(mask, width, height, params.gapClosing)
      : mask;
  labels.fillRange(0, n, 0);
  final areas = _label(sealed, 0, width, height, labels, stack, eight: false);

  // Regions that are too small become part of the line; the rest get
  // compact ids.
  final remap = Int32List(areas.length);
  var count = 0;
  for (var id = 1; id < areas.length; id++) {
    if (areas[id] >= params.minRegionArea) remap[id] = ++count;
  }
  for (var i = 0; i < n; i++) {
    labels[i] = labels[i] == 0 ? 0 : remap[labels[i]];
  }

  // 5. Give line pixels to the nearest region (multi-source BFS).
  if (count > 0) _growRegions(labels, width, height, stack);

  return ScanResult(
    width: width,
    height: height,
    linesRgba: lines,
    regions: labels,
    regionCount: count,
  );
}

Uint8List _toGray(Uint8List rgba, int n) {
  final gray = Uint8List(n);
  for (var i = 0; i < n; i++) {
    final o = i * 4;
    final a = rgba[o + 3];
    // Composite over white so transparent PNGs behave like paper.
    final r = (rgba[o] * a + 255 * (255 - a)) ~/ 255;
    final g = (rgba[o + 1] * a + 255 * (255 - a)) ~/ 255;
    final b = (rgba[o + 2] * a + 255 * (255 - a)) ~/ 255;
    gray[i] = (r * 299 + g * 587 + b * 114) ~/ 1000;
  }
  return gray;
}

int _otsu(Uint8List gray) {
  final hist = List<int>.filled(256, 0);
  for (final g in gray) {
    hist[g]++;
  }
  final total = gray.length;
  var sumAll = 0;
  for (var t = 0; t < 256; t++) {
    sumAll += t * hist[t];
  }
  var sumB = 0, wB = 0;
  var best = 0.0, threshold = 128;
  for (var t = 0; t < 256; t++) {
    wB += hist[t];
    if (wB == 0) continue;
    final wF = total - wB;
    if (wF == 0) break;
    sumB += t * hist[t];
    final mB = sumB / wB;
    final mF = (sumAll - sumB) / wF;
    final between = wB * wF * (mB - mF) * (mB - mF);
    if (between > best) {
      best = between;
      threshold = t;
    }
  }
  // Keep the threshold in a sane band so near-blank pages don't turn grey
  // paper into lines.
  return threshold.clamp(60, 215);
}

/// Mean of a (2r+1)² window using an integral image.
Float32List _localMean(Uint8List gray, int w, int h) {
  final r = math.max(8, math.max(w, h) ~/ 32);
  final iw = w + 1;
  final integral = Float64List(iw * (h + 1));
  for (var y = 0; y < h; y++) {
    var row = 0.0;
    for (var x = 0; x < w; x++) {
      row += gray[y * w + x];
      integral[(y + 1) * iw + x + 1] = integral[y * iw + x + 1] + row;
    }
  }
  final out = Float32List(w * h);
  for (var y = 0; y < h; y++) {
    final y0 = math.max(0, y - r), y1 = math.min(h, y + r + 1);
    for (var x = 0; x < w; x++) {
      final x0 = math.max(0, x - r), x1 = math.min(w, x + r + 1);
      final sum = integral[y1 * iw + x1] -
          integral[y0 * iw + x1] -
          integral[y1 * iw + x0] +
          integral[y0 * iw + x0];
      out[y * w + x] = sum / ((x1 - x0) * (y1 - y0));
    }
  }
  return out;
}

/// Square dilation by [r] pixels (separable).
Uint8List _dilate(Uint8List src, int w, int h, int r) {
  final tmp = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (src[y * w + x] == 0) continue;
      final x0 = math.max(0, x - r), x1 = math.min(w - 1, x + r);
      for (var xx = x0; xx <= x1; xx++) {
        tmp[y * w + xx] = 1;
      }
    }
  }
  final out = Uint8List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (tmp[y * w + x] == 0) continue;
      final y0 = math.max(0, y - r), y1 = math.min(h - 1, y + r);
      for (var yy = y0; yy <= y1; yy++) {
        out[yy * w + x] = 1;
      }
    }
  }
  return out;
}

/// Labels connected components of pixels equal to [target]. Label 0 is left
/// for everything else. Returns areas indexed by label (index 0 unused).
Int32List _label(
  Uint8List mask,
  int target,
  int w,
  int h,
  Int32List labels,
  Int32List stack, {
  required bool eight,
}) {
  final areas = <int>[0];
  for (var start = 0; start < w * h; start++) {
    if (mask[start] != target || labels[start] != 0) continue;
    final id = areas.length;
    var area = 0;
    var sp = 0;
    stack[sp++] = start;
    labels[start] = id;
    while (sp > 0) {
      final p = stack[--sp];
      area++;
      final x = p % w, y = p ~/ w;
      for (var dy = -1; dy <= 1; dy++) {
        final yy = y + dy;
        if (yy < 0 || yy >= h) continue;
        for (var dx = -1; dx <= 1; dx++) {
          if ((dx == 0 && dy == 0) || (!eight && dx != 0 && dy != 0)) continue;
          final xx = x + dx;
          if (xx < 0 || xx >= w) continue;
          final q = yy * w + xx;
          if (mask[q] == target && labels[q] == 0) {
            labels[q] = id;
            stack[sp++] = q;
          }
        }
      }
    }
    areas.add(area);
  }
  return Int32List.fromList(areas);
}

/// Floods region ids into pixels that are still 0, nearest region first.
void _growRegions(Int32List labels, int w, int h, Int32List queue) {
  var head = 0, tail = 0;
  for (var i = 0; i < labels.length; i++) {
    if (labels[i] != 0) queue[tail++] = i;
  }
  while (head < tail) {
    final p = queue[head++];
    final id = labels[p];
    final x = p % w, y = p ~/ w;
    void visit(int q) {
      if (labels[q] == 0) {
        labels[q] = id;
        queue[tail++] = q;
      }
    }

    if (x > 0) visit(p - 1);
    if (x < w - 1) visit(p + 1);
    if (y > 0) visit(p - w);
    if (y < h - 1) visit(p + w);
  }
}
