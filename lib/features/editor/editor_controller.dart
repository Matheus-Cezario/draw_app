import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/document/document.dart';
import '../../core/history/history.dart';
import '../../core/raster/compositor.dart';
import '../../core/raster/raster.dart';
import '../../core/storage/project_repository.dart';
import '../../core/tools/fill_algorithms.dart';
import '../../core/tools/selection_tool.dart';
import '../../core/tools/shape_tool.dart';
import '../../core/tools/simple_tools.dart';
import '../../core/tools/stroke_tools.dart';
import '../../core/tools/tool.dart';

enum ToolType {
  brush,
  pencil,
  eraser,
  fill,
  eyedropper,
  line,
  rectangle,
  ellipse,
  text,
  selection,
}

/// ViewModel of the editor screen (MVVM, decision D2).
///
/// Owns the document, the active tool and the history. Widgets read state from
/// here and call its methods; they never touch pixels or storage.
class EditorController extends ChangeNotifier implements ToolHost {
  EditorController(this._document, this._repository) {
    _tool = _createTool(_toolType);
  }

  static const _uuid = Uuid();

  final DrawDocument _document;
  final ProjectRepository _repository;
  final History _history = History();

  /// Fires on every live-stroke update; the canvas listens to this instead of
  /// the whole controller so dragging does not rebuild the widget tree.
  final ValueNotifier<int> repaint = ValueNotifier(0);

  ToolType _toolType = ToolType.brush;
  late Tool _tool;
  int _activeLayerIndex = 0;
  ui.Color _color = const ui.Color(0xFFE53935);
  double _size = 24;
  double _opacity = 1;
  Timer? _saveTimer;
  bool _disposed = false;

  /// Set by the UI to answer [requestText].
  void Function(ui.Offset point)? onTextRequested;

  // ---- ToolHost ---------------------------------------------------------

  @override
  DrawDocument get document => _document;
  @override
  Layer get activeLayer => _document.layers[_activeLayerIndex];
  @override
  ui.Color get color => _color;
  @override
  double get size => _size;
  @override
  double get opacity => _opacity;

  @override
  void setColor(ui.Color color) {
    _color = color;
    notifyListeners();
  }

  @override
  void requestRepaint() => repaint.value++;

  @override
  void requestText(ui.Offset point) => onTextRequested?.call(point);

  @override
  Future<Uint8List> flattenedRgba() async =>
      rgbaFromImage(await flattenDocument(_document));

  @override
  Future<void> commitLayer(Layer layer, void Function(ui.Canvas) paint) async {
    final before = layer.image;
    final after = await composeImage(
      before,
      _document.width,
      _document.height,
      paint,
    );
    _history.push(HistoryEntry(layerId: layer.id, before: before, after: after));
    _setLayerImage(layer, after);
  }

  @override
  Future<void> fillAt(ui.Offset point) async {
    final x = point.dx.floor(), y = point.dy.floor();
    final w = _document.width, h = _document.height;
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final layer = activeLayer;
    final bytes = layer.image == null
        ? Uint8List(w * h * 4)
        : Uint8List.fromList(await rgbaFromImage(layer.image!));
    final c = _color;
    final r = (c.r * 255).round(), g = (c.g * 255).round();
    final b = (c.b * 255).round(), a = (_opacity * 255).round();

    final regions = _document.regions;
    if (regions != null) {
      // Scanned drawing: paint the whole region (decision D4).
      fillRegion(bytes, regions, regions[y * w + x], r, g, b, a);
    } else {
      final reference = await flattenedRgba();
      floodFillTolerance(
        reference: reference,
        target: bytes,
        width: w,
        height: h,
        startX: x,
        startY: y,
        r: r,
        g: g,
        b: b,
        a: a,
      );
    }
    final before = layer.image;
    final after = await imageFromRgba(bytes, w, h);
    _history.push(HistoryEntry(layerId: layer.id, before: before, after: after));
    _setLayerImage(layer, after);
  }

  // ---- State read by the UI --------------------------------------------

  ToolType get toolType => _toolType;
  Tool get tool => _tool;
  int get activeLayerIndex => _activeLayerIndex;
  List<Layer> get layers => _document.layers;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  String get name => _document.name;

  // ---- Intents -----------------------------------------------------------

  Future<void> selectTool(ToolType type) async {
    await _tool.finish();
    _toolType = type;
    _tool = _createTool(type);
    notifyListeners();
  }

  void setSize(double value) {
    _size = value;
    notifyListeners();
  }

  void setOpacity(double value) {
    _opacity = value;
    notifyListeners();
  }

  Future<void> selectLayer(int index) async {
    await _tool.finish();
    _activeLayerIndex = index;
    notifyListeners();
  }

  void addLayer() {
    _document.layers.insert(
      _activeLayerIndex + 1,
      Layer(id: _uuid.v4(), name: 'Color ${_document.layers.length + 1}'),
    );
    _activeLayerIndex++;
    _changed();
  }

  void removeLayer(int index) {
    if (_document.layers.length <= 1) return;
    _document.layers.removeAt(index);
    if (_activeLayerIndex >= _document.layers.length) {
      _activeLayerIndex = _document.layers.length - 1;
    }
    _history.clear();
    _changed();
  }

  void moveLayer(int from, int to) {
    final layer = _document.layers.removeAt(from);
    _document.layers.insert(to, layer);
    _activeLayerIndex = to;
    _changed();
  }

  void toggleLayerVisible(int index) {
    layers[index].visible = !layers[index].visible;
    _changed();
  }

  void setLayerOpacity(int index, double value) {
    layers[index].opacity = value;
    _changed();
  }

  Future<void> addText(String text, ui.Offset at) async {
    if (text.trim().isEmpty) return;
    final color = _color;
    final fontSize = _size * 1.6;
    await commitLayer(activeLayer, (canvas) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle())
        ..pushStyle(ui.TextStyle(color: color, fontSize: fontSize))
        ..addText(text);
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 4000));
      canvas.drawParagraph(paragraph, at);
    });
  }

  Future<void> undo() async {
    await _tool.finish();
    final entry = _history.popUndo();
    if (entry == null) return;
    _applyEntry(entry, entry.before);
  }

  Future<void> redo() async {
    final entry = _history.popRedo();
    if (entry == null) return;
    _applyEntry(entry, entry.after);
  }

  /// Flattened PNG of the whole drawing for export.
  Future<Uint8List> exportPng() async {
    await _tool.finish();
    return Uint8List.fromList(await flattenedPng(_document));
  }

  Future<void> saveNow() async {
    _saveTimer?.cancel();
    await _tool.finish();
    await _repository.save(_document);
  }

  // ---- Internals ---------------------------------------------------------

  void _applyEntry(HistoryEntry entry, ui.Image? image) {
    final match = _document.layers.where((l) => l.id == entry.layerId);
    if (match.isEmpty) return;
    _setLayerImage(match.first, image);
  }

  void _setLayerImage(Layer layer, ui.Image? image) {
    layer.image = image;
    layer.dirty = true;
    _changed();
  }

  void _changed() {
    notifyListeners();
    requestRepaint();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () {
      if (!_disposed) _repository.save(_document);
    });
  }

  Tool _createTool(ToolType type) => switch (type) {
        ToolType.brush => BrushTool(this),
        ToolType.pencil => PencilTool(this),
        ToolType.eraser => EraserTool(this),
        ToolType.fill => FillTool(this),
        ToolType.eyedropper => EyedropperTool(this),
        ToolType.line => ShapeTool(this, ShapeKind.line),
        ToolType.rectangle => ShapeTool(this, ShapeKind.rectangle),
        ToolType.ellipse => ShapeTool(this, ShapeKind.ellipse),
        ToolType.text => TextTool(this),
        ToolType.selection => SelectionTool(this),
      };

  @override
  void dispose() {
    _disposed = true;
    _saveTimer?.cancel();
    repaint.dispose();
    super.dispose();
  }
}
