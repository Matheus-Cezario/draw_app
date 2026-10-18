import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'editor_controller.dart';

/// Layer opacity choices (instead of a slider).
const List<double> kLayerOpacities = [1.0, 0.6, 0.3];

class LayersSheet extends StatelessWidget {
  const LayersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<EditorController>();
    // Show the top layer first, like most paint apps.
    final order = [for (var i = c.layers.length - 1; i >= 0; i--) i];
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Layers'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, size: 32),
                tooltip: 'Add layer',
                onPressed: c.addLayer,
              ),
            ),
            if (c.document.hasScan)
              const ListTile(
                dense: true,
                leading: Icon(Icons.lock_outline),
                title: Text('Outline (always on top)'),
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
      subtitle: Wrap(
        spacing: 6,
        children: [
          for (final o in kLayerOpacities)
            ChoiceChip(
              label: Text('${(o * 100).round()}%'),
              selected: layer.opacity == o,
              onSelected: (_) => c.setLayerOpacity(index, o),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: index < c.layers.length - 1
                ? () => c.moveLayer(index, index + 1)
                : null,
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
