# Architecture

All code, comments, identifiers and documentation are written in **English**.

## Pattern: feature-first MVVM (Model – View – ViewModel)

We follow **MVVM** with a **feature-first** folder layout, plus the
**Repository** pattern for persistence and the **Command** pattern for undo/redo
and the **Strategy** pattern for drawing tools.

| Layer | Responsibility | Where | Flutter mapping |
|-------|----------------|-------|-----------------|
| Model | Plain data + pure logic, no Flutter widgets | `lib/core/document`, `lib/core/scan` | Dart classes |
| ViewModel | UI state and user intents, no widgets/`BuildContext` | `lib/features/*/…_controller.dart` | `ChangeNotifier` exposed via `provider` |
| View | Widgets that render state and forward events | `lib/features/*/…_page.dart`, `…_view.dart` | `StatelessWidget` / small `StatefulWidget` |
| Repository | Hides storage details from ViewModels | `lib/core/storage` | `ProjectRepository` |

Rules:
1. Views never touch storage, isolates or pixel buffers; they call ViewModel methods.
2. ViewModels never import `package:flutter/widgets.dart` widgets (only `dart:ui` types such as `Image`/`Color`).
3. `core/` never imports from `features/`. Dependencies point inward: `features -> core`.
4. The scan pipeline (`core/scan/scan_pipeline.dart`) is pure Dart on raw bytes: runs in an isolate and is unit tested without Flutter.

## Folder layout
```
lib/
  main.dart, app.dart          bootstrap, theme, providers
  core/
    document/                  DrawDocument, Layer (models)
    scan/                      scan_pipeline (pure), scan_service (decode + isolate)
    raster/                    pixel helpers (ui.Image <-> bytes, compositing)
    tools/                     Tool strategies (brush, eraser, fill, ...)
    history/                   undo/redo commands
    storage/                   ProjectRepository (files on disk)
  features/
    gallery/                   project list, new project, import
    scan_preview/              tune scan sensitivity before creating a project
    editor/                    EditorController (ViewModel), canvas, panels
test/
```

## Key flows
- **Import**: gallery -> picker -> `ScanService.scan` (isolate) -> preview page (sliders re-run the scan) -> `ProjectRepository.create` -> editor.
- **Draw**: canvas view forwards pointer events to the active `Tool`; the tool mutates the controller's live stroke; on release the stroke is rasterized into the layer image and a history command is pushed.
- **Fill**: `FillTool` reads the region id under the finger from `DrawDocument.regions` and paints that region's pixels on the active layer.
