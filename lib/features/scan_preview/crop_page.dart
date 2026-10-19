import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/raster/raster.dart';
import '../../core/scan/crop.dart';
import '../../core/scan/scan_service.dart';
import '../../core/ui/kid_ui.dart';
import '../gallery/sketch_button.dart';

enum _Grab { none, move, topLeft, topRight, bottomLeft, bottomRight, left, right, top, bottom }

/// Full-screen cropping: drag the corners, the sides, or the inside of the
/// box. Returns the chosen [CropRect], or null when the user goes back.
class CropPage extends StatefulWidget {
  const CropPage({super.key, required this.picture, required this.initial});

  final DecodedPicture picture;
  final CropRect initial;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  static const double _minSize = 0.1;
  static const double _cornerReach = 40;
  static const double _edgeReach = 24;

  late CropRect _crop = widget.initial;
  ui.Image? _image;
  _Grab _grab = _Grab.none;

  @override
  void initState() {
    super.initState();
    imageFromRgba(widget.picture.rgba, widget.picture.width, widget.picture.height)
        .then((image) {
      if (mounted) setState(() => _image = image);
    });
  }

  Rect _fitted(Size area) {
    final iw = widget.picture.width.toDouble(), ih = widget.picture.height.toDouble();
    final scale = (area.width / iw) < (area.height / ih) ? area.width / iw : area.height / ih;
    final w = iw * scale, h = ih * scale;
    return Rect.fromLTWH((area.width - w) / 2, (area.height - h) / 2, w, h);
  }

  Rect _screenCrop(Rect img) => Rect.fromLTRB(
        img.left + _crop.left * img.width,
        img.top + _crop.top * img.height,
        img.left + _crop.right * img.width,
        img.top + _crop.bottom * img.height,
      );

  _Grab _hitTest(Offset p, Rect r) {
    final corners = {
      _Grab.topLeft: r.topLeft,
      _Grab.topRight: r.topRight,
      _Grab.bottomLeft: r.bottomLeft,
      _Grab.bottomRight: r.bottomRight,
    };
    _Grab best = _Grab.none;
    var bestDistance = _cornerReach;
    corners.forEach((grab, corner) {
      final d = (corner - p).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = grab;
      }
    });
    if (best != _Grab.none) return best;

    final withinX = p.dx >= r.left && p.dx <= r.right;
    final withinY = p.dy >= r.top && p.dy <= r.bottom;
    if (withinY && (p.dx - r.left).abs() <= _edgeReach) return _Grab.left;
    if (withinY && (p.dx - r.right).abs() <= _edgeReach) return _Grab.right;
    if (withinX && (p.dy - r.top).abs() <= _edgeReach) return _Grab.top;
    if (withinX && (p.dy - r.bottom).abs() <= _edgeReach) return _Grab.bottom;
    if (r.contains(p)) return _Grab.move;
    return _Grab.none;
  }

  void _drag(Offset delta, Rect img) {
    final dx = delta.dx / img.width, dy = delta.dy / img.height;
    var c = _crop;
    double clampLeft(double v) => v.clamp(0.0, c.right - _minSize);
    double clampRight(double v) => v.clamp(c.left + _minSize, 1.0);
    double clampTop(double v) => v.clamp(0.0, c.bottom - _minSize);
    double clampBottom(double v) => v.clamp(c.top + _minSize, 1.0);

    switch (_grab) {
      case _Grab.none:
        return;
      case _Grab.move:
        final mx = dx.clamp(-c.left, 1 - c.right);
        final my = dy.clamp(-c.top, 1 - c.bottom);
        c = CropRect(c.left + mx, c.top + my, c.right + mx, c.bottom + my);
      case _Grab.left:
        c = c.copyWith(left: clampLeft(c.left + dx));
      case _Grab.right:
        c = c.copyWith(right: clampRight(c.right + dx));
      case _Grab.top:
        c = c.copyWith(top: clampTop(c.top + dy));
      case _Grab.bottom:
        c = c.copyWith(bottom: clampBottom(c.bottom + dy));
      case _Grab.topLeft:
        c = c.copyWith(left: clampLeft(c.left + dx), top: clampTop(c.top + dy));
      case _Grab.topRight:
        c = c.copyWith(right: clampRight(c.right + dx), top: clampTop(c.top + dy));
      case _Grab.bottomLeft:
        c = c.copyWith(left: clampLeft(c.left + dx), bottom: clampBottom(c.bottom + dy));
      case _Grab.bottomRight:
        c = c.copyWith(right: clampRight(c.right + dx), bottom: clampBottom(c.bottom + dy));
    }
    setState(() => _crop = c);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kKidBoard,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFD23F),
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: kKidInk, width: 3)),
        leadingWidth: 60,
        leading: Center(
          child: RoundSticker(
            icon: Icons.arrow_back_rounded,
            color: const Color(0xFF1E88E5),
            tooltip: 'Back',
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text('Cut your picture', style: kidText(22, weight: 700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(builder: (context, constraints) {
                final area = constraints.biggest;
                final img = _fitted(area);
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => _grab = _hitTest(d.localPosition, _screenCrop(img)),
                  onPanUpdate: (d) => _drag(d.delta, img),
                  onPanEnd: (_) => _grab = _Grab.none,
                  child: CustomPaint(
                    size: area,
                    painter: _CropPainter(_image, img, _screenCrop(img)),
                  ),
                );
              }),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: kKidCream,
              border: Border(top: BorderSide(color: kKidInk, width: 3)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StickerChoice(
                      label: 'Whole picture',
                      icon: Icons.crop_free_rounded,
                      selected: _crop.isFull,
                      color: const Color(0xFFFFAB91),
                      onTap: () => setState(() => _crop = CropRect.full),
                    ),
                    SketchButton(
                      label: 'Done',
                      showPlus: false,
                      width: 150,
                      color: const Color(0xFF66D17A),
                      onTap: () => Navigator.of(context).pop(_crop),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropPainter extends CustomPainter {
  _CropPainter(this.image, this.imageRect, this.crop);

  final ui.Image? image;
  final Rect imageRect;
  final Rect crop;

  @override
  void paint(Canvas canvas, Size size) {
    // Picture on a white "paper" with an ink outline.
    canvas.drawRect(imageRect, Paint()..color = Colors.white);
    final img = image;
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        imageRect,
        Paint()..filterQuality = FilterQuality.medium,
      );
    }
    canvas.drawRect(
      imageRect,
      Paint()
        ..color = kKidInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Dim what will be cut away.
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(imageRect), Path()..addRect(crop)),
      Paint()..color = const Color(0x99000000),
    );

    // Frame: white line with an ink edge, plus thirds.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    for (var i = 1; i < 3; i++) {
      final x = crop.left + crop.width * i / 3, y = crop.top + crop.height * i / 3;
      canvas.drawLine(Offset(x, crop.top), Offset(x, crop.bottom), grid);
      canvas.drawLine(Offset(crop.left, y), Offset(crop.right, y), grid);
    }
    canvas.drawRect(
      crop,
      Paint()
        ..color = kKidInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawRect(
      crop,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );

    // Big round handles on the corners and the middle of each side.
    final handles = [
      crop.topLeft,
      crop.topRight,
      crop.bottomLeft,
      crop.bottomRight,
    ];
    for (final p in handles) {
      canvas.drawCircle(p, 15, Paint()..color = const Color(0xFFFFD23F));
      canvas.drawCircle(
        p,
        15,
        Paint()
          ..color = kKidInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }
    for (final p in [crop.centerLeft, crop.centerRight, crop.topCenter, crop.bottomCenter]) {
      canvas.drawCircle(p, 9, Paint()..color = Colors.white);
      canvas.drawCircle(
        p,
        9,
        Paint()
          ..color = kKidInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.imageRect != imageRect || old.crop != crop;
}
