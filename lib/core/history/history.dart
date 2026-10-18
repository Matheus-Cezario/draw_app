import 'dart:ui' as ui;

/// One undoable pixel edit on a layer (Command pattern, decision D7).
class HistoryEntry {
  HistoryEntry({required this.layerId, required this.before, required this.after});

  final String layerId;
  final ui.Image? before;
  final ui.Image? after;
}

/// Bounded undo/redo stacks.
class History {
  History({this.limit = 40});

  final int limit;
  final List<HistoryEntry> _undo = [];
  final List<HistoryEntry> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(HistoryEntry entry) {
    _undo.add(entry);
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
  }

  HistoryEntry? popUndo() {
    if (_undo.isEmpty) return null;
    final entry = _undo.removeLast();
    _redo.add(entry);
    return entry;
  }

  HistoryEntry? popRedo() {
    if (_redo.isEmpty) return null;
    final entry = _redo.removeLast();
    _undo.add(entry);
    return entry;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
