import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/document/document.dart';
import '../../core/storage/project_repository.dart';
import 'canvas_view.dart';
import 'editor_controller.dart';
import 'editor_toolbars.dart';
import 'layers_sheet.dart';
import 'rename_dialog.dart';

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
        title: const Text('Write something'),
        content: TextField(controller: text, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, text.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result != null) await _controller.addText(result, point);
  }

  Future<void> _rename(EditorController c) async {
    final name = await askForName(context, title: 'Name your drawing', initial: c.name);
    if (name != null) c.rename(name);
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
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    final canvas = Expanded(child: CanvasView(controller: c));

    // Colours are always on top. Tools go below the canvas in portrait and in
    // a rail on the side in landscape.
    final body = landscape
        ? Column(
            children: [
              const ColorBar(),
              Expanded(
                child: Row(
                  children: [
                    const ToolPanel(vertical: true),
                    canvas,
                  ],
                ),
              ),
            ],
          )
        : Column(
            children: [
              const ColorBar(),
              canvas,
              const ToolPanel(vertical: false),
            ],
          );

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
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _rename(c),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                const Icon(Icons.edit, size: 16),
              ],
            ),
          ),
          toolbarHeight: landscape ? 48 : kToolbarHeight,
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
                  child: const LayersSheet(),
                ),
              ),
              icon: const Icon(Icons.layers),
            ),
            IconButton(
              tooltip: 'Share',
              onPressed: _export,
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}
