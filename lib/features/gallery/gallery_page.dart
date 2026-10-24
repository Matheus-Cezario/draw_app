import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/audio/sfx_service.dart';
import '../../core/storage/project_repository.dart';
import '../../core/ui/kid_ui.dart';
import '../editor/editor_page.dart';
import '../editor/rename_dialog.dart';
import '../scan_preview/scan_preview_page.dart';
import '../settings/settings_page.dart';
import '../library/library_page.dart';
import 'new_drawing_sheet.dart';
import 'paper_card.dart';
import 'sketch_button.dart';
import '../../core/ui/app_colors.dart';


/// Lists saved projects and starts new ones.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.repository});

  final ProjectRepository repository;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late Future<List<ProjectSummary>> _projects = widget.repository.list();

  void _reload() {
    final projects = widget.repository.list();
    setState(() {
      _projects = projects;
    });
  }

  Future<void> _open(String id) async {
    final doc = await widget.repository.load(id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorPage(document: doc, repository: widget.repository),
      ),
    );
    _reload();
  }

  Future<void> _newBlank() async {
    final doc = await widget.repository.create(name: 'Untitled');
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditorPage(document: doc, repository: widget.repository),
      ),
    );
    _reload();
  }

  Future<void> _importPicture(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPreviewPage(
          encoded: bytes,
          name: picked.name.split('.').first,
          repository: widget.repository,
        ),
      ),
    );
    _reload();
  }

  Future<void> _showActions(ProjectSummary project) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'rename') {
      final name = await askForName(
        context,
        title: 'Name your drawing',
        initial: project.name,
      );
      if (name != null && name.trim().isNotEmpty) {
        await widget.repository.rename(project.id, name.trim());
        _reload();
      }
    } else if (action == 'delete') {
      await _confirmDelete(project);
    }
  }

  Future<void> _confirmDelete(ProjectSummary project) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${project.name}"?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.repository.delete(project.id);
      _reload();
    }
  }

  Future<void> _showNewSheet() async {
    final choice = await showNewDrawingSheet(context);
    if (!mounted) return;
    switch (choice) {
      case NewChoice.book:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LibraryPage(repository: widget.repository)),
        );
        _reload();
      case NewChoice.blank:
        await _newBlank();
      case NewChoice.gallery:
        await _importPicture(ImageSource.gallery);
      case NewChoice.camera:
        await _importPicture(ImageSource.camera);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.board,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: RoundSticker(
              icon: Icons.settings_rounded,
              color: AppColors.appBar,
              tooltip: 'Settings',
              onTap: withTapSound(() => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              )),
            ),
          ),
        ],
        title: const Text(
          'My drawings',
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 32,
            color: AppColors.cream,
            fontVariations: [FontVariation('wght', 700)],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SketchButton(label: 'New', onTap: _showNewSheet),
      body: FutureBuilder<List<ProjectSummary>>(
        future: _projects,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.ink));
          }
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Tap "New" to start drawing!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 24,
                    color: AppColors.ink,
                    fontVariations: [FontVariation('wght', 600)],
                  ),
                ),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 28,
              crossAxisSpacing: 24,
              childAspectRatio: 0.74,
            ),
            itemCount: projects.length,
            itemBuilder: (context, i) {
              final p = projects[i];
              return PaperCard(
                project: p,
                onTap: () => _open(p.id),
                onLongPress: () => _showActions(p),
                onDelete: () => _confirmDelete(p),
              );
            },
          );
        },
      ),
    );
  }
}
