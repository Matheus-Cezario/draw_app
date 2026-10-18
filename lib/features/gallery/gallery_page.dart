import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/storage/project_repository.dart';
import '../editor/editor_page.dart';
import '../editor/rename_dialog.dart';
import '../scan_preview/scan_preview_page.dart';

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

  void _showNewSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop_portrait),
              title: const Text('Blank canvas'),
              onTap: () {
                Navigator.pop(context);
                _newBlank();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Colour a picture from the gallery'),
              onTap: () {
                Navigator.pop(context);
                _importPicture(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Colour a photo of a drawing'),
              onTap: () {
                Navigator.pop(context);
                _importPicture(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My drawings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewSheet,
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: FutureBuilder<List<ProjectSummary>>(
        future: _projects,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return const Center(
              child: Text('Tap "New" to start drawing or import a picture.'),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: projects.length,
            itemBuilder: (context, i) {
              final p = projects[i];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _open(p.id),
                  onLongPress: () => _showActions(p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ColoredBox(
                          color: Colors.white,
                          child: p.thumbnail == null
                              ? const SizedBox()
                              : Image.file(
                                  p.thumbnail!,
                                  fit: BoxFit.contain,
                                  key: ValueKey(p.modified),
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
