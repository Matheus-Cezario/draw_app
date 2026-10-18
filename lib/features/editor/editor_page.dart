import 'dart:io';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/document/document.dart';
import '../../core/storage/project_repository.dart';
import 'canvas_view.dart';
import 'editor_controller.dart';

/// Hosts the [EditorController] and lays out the editor chrome.
class EditorPage extends StatelessWidget {
  const EditorPage({super.key, required this.document, required this.repository});

  final DrawDocument document;
  final ProjectRepository repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorController(document, repository),
      child: const _EditorScaffold(),
    );
  }
}

class _EditorScaffold extends StatefulWidget {
  const _EditorScaffold();

  @override
  State<_EditorScaffold> createState() => _EditorScaffoldState();
}

class _EditorScaffoldState extends State<_EditorScaffold> {
  late final EditorController _controller = context.read<EditorController>();

  @override
  void initState() {
    super.initState();
    _controller.onTextRequested = _askText;
  }

  Future<void> _askText(Offset point) async {
    final text = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(controller: text, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) await _controller.addText(result, point);
  }

  Future<void> _export() async {
    final bytes = await _controller.exportPng();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_controller.name}.png');
    await file.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditorController>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        await c.saveNow();
        navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(c.name),
          actions: [
            IconButton(
              tooltip: 'Undo',
              onPressed: c.canUndo ? c.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: c.canRedo ? c.redo : null,
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: 'Layers',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => ChangeNotifierProvider.value(
                  value: c,
                  child: const _LayersSheet(),
                ),
              ),
              icon: const Icon(Icons.layers),
            ),
            IconButton(
              tooltip: 'Export',
              onPressed: _export,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: CanvasView(controller: c)),
            const _BottomBar(),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  static const _tools = <(ToolType, IconData, String)>[
    (ToolType.brush, Icons.brush, 'Brush'),
    (ToolType.pencil, Icons.edit, 'Pencil'),
    (ToolType.eraser, Icons.cleaning_services, 'Eraser'),
    (ToolType.fill, Icons.format_color_fill, 'Bucket'),
    (ToolType.eyedropper, Icons.colorize, 'Eyedropper'),
    (ToolType.line, Icons.show_chart, 'Line'),
    (ToolType.rectangle, Icons.crop_square, 'Rectangle'),
    (ToolType.ellipse, Icons.circle_outlined, 'Ellipse'),
    (ToolType.text, Icons.text_fields, 'Text'),
    (ToolType.selection, Icons.highlight_alt, 'Select & move'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditorController>();
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showColorPickerDialog(
                        context,
                        c.color,
                        title: const Text('Colour'),
                        enableOpacity: false,
                      );
                      c.setColor(picked);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: scheme.outline, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.line_weight, size: 18),
                  Expanded(
                    child: Slider(
                      min: 2,
                      max: 120,
                      value: c.size.clamp(2, 120),
                      onChanged: c.setSize,
                    ),
                  ),
                  const Icon(Icons.opacity, size: 18),
                  Expanded(
                    child: Slider(
                      min: 0.05,
                      max: 1,
                      value: c.opacity,
                      onChanged: c.setOpacity,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  for (final (type, icon, label) in _tools)
                    IconButton.filledTonal(
                      isSelected: c.toolType == type,
                      tooltip: label,
                      onPressed: () => c.selectTool(type),
                      icon: Icon(icon),
                      selectedIcon: Icon(icon),
                      style: c.toolType == type
                          ? IconButton.styleFrom(
                              backgroundColor: scheme.primary,
                              foregroundColor: scheme.onPrimary,
                            )
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayersSheet extends StatelessWidget {
  const _LayersSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditorController>();
    // Show the top layer first, like most paint apps.
    final order = [for (var i = c.layers.length - 1; i >= 0; i--) i];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Layers'),
              trailing: IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Add layer',
                onPressed: c.addLayer,
              ),
            ),
            if (c.document.hasScan)
              const ListTile(
                dense: true,
                leading: Icon(Icons.lock_outline),
                title: Text('Outline (locked, always on top)'),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final i in order)
                    _LayerTile(index: i, selected: i == c.activeLayerIndex),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({required this.index, required this.selected});

  final int index;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.read<EditorController>();
    final layer = c.layers[index];
    return ListTile(
      selected: selected,
      onTap: () => c.selectLayer(index),
      leading: IconButton(
        icon: Icon(layer.visible ? Icons.visibility : Icons.visibility_off),
        onPressed: () => c.toggleLayerVisible(index),
      ),
      title: Text(layer.name),
      subtitle: Slider(
        value: layer.opacity,
        onChanged: (v) => c.setLayerOpacity(index, v),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed:
                index < c.layers.length - 1 ? () => c.moveLayer(index, index + 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: index > 0 ? () => c.moveLayer(index, index - 1) : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: c.layers.length > 1 ? () => c.removeLayer(index) : null,
          ),
        ],
      ),
    );
  }
}
