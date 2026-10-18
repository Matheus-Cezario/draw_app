import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/raster/raster.dart';
import '../../core/scan/scan_pipeline.dart';
import '../../core/scan/scan_service.dart';
import '../../core/storage/project_repository.dart';
import '../../core/ui/kid_ui.dart';
import '../gallery/sketch_button.dart';
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
  static const _sensitivityOptions = [
    ('Few', 0.25),
    ('Normal', 0.12),
    ('Many', 0.06),
  ];
  static const _gapOptions = [
    ('No', 0.0),
    ('A little', 2.0),
    ('Some', 4.0),
    ('A lot', 6.0),
  ];

  DecodedPicture? _picture;
  ScanResult? _result;
  ui.Image? _linesImage;
  ui.Image? _regionsImage;
  double _sensitivity = const ScanParams().sensitivity;
  double _gap = 0; // "No": gaps are only closed when asked for
  bool _showRegions = true;
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

  Widget _preview() {
    final image = _showRegions ? _regionsImage : _linesImage;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (image != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: AspectRatio(
              aspectRatio: image.width / image.height,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kKidInk, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(3, 6)),
                  ],
                ),
                child: RawImage(image: image, fit: BoxFit.contain),
              ),
            ),
          ),
        if (_busy)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: kKidInk, width: 3),
            ),
            child: const CircularProgressIndicator(color: Color(0xFFF2543D), strokeWidth: 6),
          ),
      ],
    );
  }

  Widget _panel(bool canUse) {
    final result = _result;
    return Container(
      decoration: const BoxDecoration(
        color: kKidCream,
        border: Border(
          top: BorderSide(color: kKidInk, width: 3),
          left: BorderSide(color: kKidInk, width: 3),
        ),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  result == null ? 'Looking for lines...' : '${result.regionCount} places to paint!',
                  style: kidText(22, weight: 700),
                ),
              ),
              const SizedBox(height: 12),
              Text('How many lines?', style: kidText(16, weight: 600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (label, value) in _sensitivityOptions)
                    StickerChoice(
                      label: label,
                      selected: _sensitivity == value,
                      color: const Color(0xFFCE93D8),
                      onTap: () {
                        setState(() => _sensitivity = value);
                        _scheduleScan();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Close small gaps?', style: kidText(16, weight: 600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final (label, value) in _gapOptions)
                    StickerChoice(
                      label: label,
                      selected: _gap == value,
                      color: const Color(0xFF80DEEA),
                      onTap: () {
                        setState(() => _gap = value);
                        _scheduleScan();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              StickerChoice(
                label: _showRegions ? 'Showing colours' : 'Show colours',
                icon: Icons.palette_rounded,
                selected: _showRegions,
                color: const Color(0xFFFFAB91),
                onTap: () => setState(() => _showRegions = !_showRegions),
              ),
              const SizedBox(height: 16),
              Center(
                child: Opacity(
                  opacity: canUse ? 1 : 0.5,
                  child: SketchButton(
                    label: "Let's go!",
                    showPlus: false,
                    width: 230,
                    color: const Color(0xFF66D17A),
                    onTap: canUse ? _create : () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final canUse = _result != null && !_busy;

    final Widget body;
    if (_error != null) {
      body = Center(child: Text(_error!, style: kidText(22, weight: 700)));
    } else if (landscape) {
      body = Row(
        children: [
          Expanded(child: _preview()),
          SizedBox(width: 360, child: _panel(canUse)),
        ],
      );
    } else {
      body = Column(
        children: [
          Expanded(child: _preview()),
          _panel(canUse),
        ],
      );
    }

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
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        title: Text('Check your picture', style: kidText(22, weight: 700)),
      ),
      body: body,
    );
  }
}
