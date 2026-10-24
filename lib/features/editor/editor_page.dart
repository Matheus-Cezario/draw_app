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
import '../../core/ui/app_colors.dart';

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
          backgroundColor: AppColors.appBar,
          surfaceTintColor: Colors.transparent,
          shape: const Border(bottom: BorderSide(color: AppColors.ink, width: 3)),
          toolbarHeight: landscape ? 52 : 64,
          leadingWidth: 54,
          leading: Center(
            child: _RoundAction(
              icon: Icons.arrow_back_rounded,
              color: AppColors.back,
              tooltip: 'Back',
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
          titleSpacing: 4,
          title: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _rename(c),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    c.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 22,
                      color: AppColors.ink,
                      fontVariations: [FontVariation('wght', 700)],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_rounded, size: 18, color: AppColors.ink),
              ],
            ),
          ),
          actions: [
            _RoundAction(
              icon: Icons.undo_rounded,
              color: const Color(0xFFFF7043),
              tooltip: 'Undo',
              onTap: c.canUndo ? c.undo : null,
            ),
            _RoundAction(
              icon: Icons.redo_rounded,
              color: const Color(0xFFFF7043),
              tooltip: 'Redo',
              onTap: c.canRedo ? c.redo : null,
            ),
            _RoundAction(
              icon: Icons.layers_rounded,
              color: const Color(0xFF8E24AA),
              tooltip: 'Layers',
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.cream,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  side: BorderSide(color: AppColors.ink, width: 3),
                ),
                builder: (_) => ChangeNotifierProvider.value(
                  value: c,
                  child: const LayersSheet(),
                ),
              ),
            ),
            _RoundAction(
              icon: Icons.ios_share_rounded,
              color: AppColors.confirm,
              tooltip: 'Share',
              onTap: _export,
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: SafeArea(top: false, child: body),
      ),
    );
  }
}

/// Round, sticker-like action button for the top bar. Greyed out when
/// [onTap] is null.
class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? color : AppColors.disabled,
              border: Border.all(color: AppColors.ink, width: 3),
              boxShadow: enabled
                  ? const [BoxShadow(color: AppColors.ink, offset: Offset(0, 3))]
                  : null,
            ),
            child: Icon(
              icon,
              size: 21,
              color: enabled ? Colors.white : AppColors.disabledText,
            ),
          ),
        ),
      ),
    );
  }
}
