import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/raster/raster.dart';
import '../../core/scan/scan_pipeline.dart';
import '../../core/scan/scan_service.dart';
import '../../core/storage/project_repository.dart';
import '../editor/editor_page.dart';

/// Lets the user tune the scan and see what the bucket will treat as lines
/// and regions before the project is created.
class ScanPreviewPage extends StatefulWidget {
  const ScanPreviewPage({
    super.key,
    required this.encoded,
    required this.name,
    required this.repository,
  });

  final Uint8List encoded;
  final String name;
  final ProjectRepository repository;

  @override
  State<ScanPreviewPage> createState() => _ScanPreviewPageState();
}

class _ScanPreviewPageState extends State<ScanPreviewPage> {
  static const _service = ScanService();

  DecodedPicture? _picture;
  ScanResult? _result;
  ui.Image? _linesImage;
  ui.Image? _regionsImage;
  double _sensitivity = const ScanParams().sensitivity;
  double _gap = const ScanParams().gapClosing.toDouble();
  bool _showRegions = false;
  bool _busy = true;
  String? _error;
  Timer? _debounce;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _picture = await _service.decode(widget.encoded);
      await _scan();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not read this image.');
    }
  }

  void _scheduleScan() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _scan);
  }

  Future<void> _scan() async {
    final picture = _picture;
    if (picture == null) return;
    final generation = ++_generation;
    setState(() => _busy = true);
    final result = await _service.scan(
      picture,
      ScanParams(sensitivity: _sensitivity, gapClosing: _gap.round()),
    );
    if (!mounted || generation != _generation) return;
    final lines = await imageFromRgba(result.linesRgba, result.width, result.height);
    final regions = await imageFromRgba(
      _regionColors(result),
      result.width,
      result.height,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _result = result;
      _linesImage = lines;
      _regionsImage = regions;
      _busy = false;
    });
  }

  /// Pseudo-random pastel per region id, to visualise the segmentation.
  Uint8List _regionColors(ScanResult r) {
    final out = Uint8List(r.width * r.height * 4);
    for (var i = 0; i < r.regions.length; i++) {
      final id = r.regions[i];
      final h = (id * 2654435761) & 0xFFFFFF;
      out[i * 4] = 120 + (h & 0x7F);
      out[i * 4 + 1] = 120 + ((h >> 8) & 0x7F);
      out[i * 4 + 2] = 120 + ((h >> 16) & 0x7F);
      out[i * 4 + 3] = 255;
    }
    return out;
  }

  Future<void> _create() async {
    final result = _result;
    if (result == null) return;
    setState(() => _busy = true);
    final doc = await widget.repository.create(name: widget.name, scan: result);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EditorPage(document: doc, repository: widget.repository),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan drawing'),
        actions: [
          TextButton(
            onPressed: result == null || _busy ? null : _create,
            child: const Text('Use'),
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_linesImage != null)
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: AspectRatio(
                            aspectRatio: _linesImage!.width / _linesImage!.height,
                            child: ColoredBox(
                              color: Colors.white,
                              child: RawImage(
                                image: _showRegions ? _regionsImage : _linesImage,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      if (_busy) const CircularProgressIndicator(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (result != null)
                        Text('${result.regionCount} paintable regions found'),
                      Row(children: [
                        const SizedBox(width: 90, child: Text('Sensitivity')),
                        Expanded(
                          child: Slider(
                            min: 0.03,
                            max: 0.4,
                            value: _sensitivity,
                            onChanged: (v) {
                              setState(() => _sensitivity = v);
                              _scheduleScan();
                            },
                          ),
                        ),
                      ]),
                      Row(children: [
                        const SizedBox(width: 90, child: Text('Close gaps')),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 6,
                            divisions: 6,
                            label: _gap.round().toString(),
                            value: _gap,
                            onChanged: (v) {
                              setState(() => _gap = v);
                              _scheduleScan();
                            },
                          ),
                        ),
                      ]),
                      SwitchListTile(
                        dense: true,
                        title: const Text('Show regions'),
                        value: _showRegions,
                        onChanged: (v) => setState(() => _showRegions = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
