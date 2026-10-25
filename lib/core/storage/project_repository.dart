import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../document/document.dart';
import '../raster/compositor.dart';
import '../raster/raster.dart';
import '../scan/scan_pipeline.dart';

/// What the gallery needs to show a project.
class ProjectSummary {
  ProjectSummary({
    required this.id,
    required this.name,
    required this.modified,
    this.thumbnail,
  });

  final String id;
  final String name;
  final DateTime modified;
  /// PNG bytes of the preview. Bytes (not a file path) so a re-saved drawing
  /// can never be shown from a stale image cache entry.
  final Uint8List? thumbnail;
}

/// Stores each project as a folder on disk (decision D9):
/// `meta.json`, `layer_<id>.png`, `lines.png`, `regions.bin`, `thumb.png`.
class ProjectRepository {
  static const _uuid = Uuid();

  Future<Directory> _root() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/projects');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _dirOf(String id) async =>
      Directory('${(await _root()).path}/$id');

  Future<List<ProjectSummary>> list() async {
    final root = await _root();
    final result = <ProjectSummary>[];
    await for (final entity in root.list()) {
      if (entity is! Directory) continue;
      final meta = File('${entity.path}/meta.json');
      if (!await meta.exists()) continue;
      try {
        final json = jsonDecode(await meta.readAsString()) as Map;
        final thumb = File('${entity.path}/thumb.png');
        result.add(ProjectSummary(
          id: json['id'] as String,
          name: json['name'] as String,
          modified: DateTime.parse(json['modified'] as String),
          thumbnail: await thumb.exists() ? await thumb.readAsBytes() : null,
        ));
      } catch (_) {
        // Skip unreadable projects instead of breaking the whole gallery.
      }
    }
    result.sort((a, b) => b.modified.compareTo(a.modified));
    return result;
  }

  /// How many projects exist, without reading their thumbnails.
  Future<int> count() async {
    var total = 0;
    await for (final entity in (await _root()).list()) {
      if (entity is Directory && await File('${entity.path}/meta.json').exists()) {
        total++;
      }
    }
    return total;
  }

  /// Creates a blank project, or a scanned one when [scan] is given.
  Future<DrawDocument> create({
    required String name,
    int width = 1200,
    int height = 1600,
    ScanResult? scan,
  }) async {
    final doc = DrawDocument(
      id: _uuid.v4(),
      name: name,
      width: scan?.width ?? width,
      height: scan?.height ?? height,
      layers: [Layer(id: _uuid.v4(), name: 'Color 1')],
    );
    if (scan != null) {
      doc.lines = await imageFromRgba(scan.linesRgba, scan.width, scan.height);
      doc.regions = scan.regions;
      doc.regionCount = scan.regionCount;
    }
    await save(doc, writeStatic: true);
    return doc;
  }

  Future<void> save(DrawDocument doc, {bool writeStatic = false}) async {
    final dir = await _dirOf(doc.id);
    if (!await dir.exists()) await dir.create(recursive: true);

    for (final layer in doc.layers) {
      final file = File('${dir.path}/layer_${layer.id}.png');
      if (layer.image == null) {
        if (await file.exists()) await file.delete();
      } else if (layer.dirty || !await file.exists()) {
        await file.writeAsBytes(await pngFromImage(layer.image!));
      }
      layer.dirty = false;
    }
    // Remove files of layers that no longer exist.
    final keep = {for (final l in doc.layers) 'layer_${l.id}.png'};
    await for (final e in dir.list()) {
      final name = e.uri.pathSegments.last;
      if (name.startsWith('layer_') && !keep.contains(name)) {
        await e.delete();
      }
    }

    if (writeStatic) {
      if (doc.lines != null) {
        await File('${dir.path}/lines.png')
            .writeAsBytes(await pngFromImage(doc.lines!));
      }
      if (doc.regions != null) {
        final r = doc.regions!;
        await File('${dir.path}/regions.bin').writeAsBytes(
          r.buffer.asUint8List(r.offsetInBytes, r.lengthInBytes),
        );
      }
    }

    final thumb = await thumbnail(doc);
    await File('${dir.path}/thumb.png').writeAsBytes(await pngFromImage(thumb));

    await File('${dir.path}/meta.json').writeAsString(jsonEncode({
      'id': doc.id,
      'name': doc.name,
      'width': doc.width,
      'height': doc.height,
      'regionCount': doc.regionCount,
      'modified': DateTime.now().toIso8601String(),
      'layers': [
        for (final l in doc.layers)
          {
            'id': l.id,
            'name': l.name,
            'visible': l.visible,
            'opacity': l.opacity,
          },
      ],
    }));
  }

  Future<DrawDocument> load(String id) async {
    final dir = await _dirOf(id);
    final json =
        jsonDecode(await File('${dir.path}/meta.json').readAsString()) as Map;
    final layers = <Layer>[];
    for (final raw in (json['layers'] as List).cast<Map>()) {
      final layer = Layer(
        id: raw['id'] as String,
        name: raw['name'] as String,
        visible: raw['visible'] as bool,
        opacity: (raw['opacity'] as num).toDouble(),
      );
      final file = File('${dir.path}/layer_${layer.id}.png');
      if (await file.exists()) {
        layer.image = await imageFromEncoded(await file.readAsBytes());
        layer.dirty = false;
      }
      layers.add(layer);
    }
    final doc = DrawDocument(
      id: json['id'] as String,
      name: json['name'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      layers: layers,
      regionCount: json['regionCount'] as int,
    );
    final lines = File('${dir.path}/lines.png');
    if (await lines.exists()) {
      doc.lines = await imageFromEncoded(await lines.readAsBytes());
    }
    final regions = File('${dir.path}/regions.bin');
    if (await regions.exists()) {
      final bytes = await regions.readAsBytes();
      doc.regions = Int32List.sublistView(bytes);
    }
    return doc;
  }

  Future<void> rename(String id, String name) async {
    final file = File('${(await _dirOf(id)).path}/meta.json');
    final json = jsonDecode(await file.readAsString()) as Map;
    json['name'] = name;
    await file.writeAsString(jsonEncode(json));
  }

  Future<void> delete(String id) async {
    final dir = await _dirOf(id);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
