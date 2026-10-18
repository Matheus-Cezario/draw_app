# Decision log

Each entry: what we decided, and why.

## D1. Flutter, mobile first
Single codebase for iOS and Android; the project was already a Flutter project. Desktop/web targets stay enabled for fast development but are not prioritized.

## D2. MVVM + feature-first + `provider` + `ChangeNotifier`
Chosen over BLoC/Riverpod because the app has one dominant stateful screen (the editor); `ChangeNotifier` is the smallest thing that cleanly separates UI from logic, needs no code generation, and is easy to unit test. Feature-first folders keep editor, gallery and scan code from tangling.

## D3. Scan runs 100% on device, in Dart, in an isolate
Offline, free, private (no image upload), no backend to maintain. An isolate keeps the UI responsive during a multi-megapixel scan. A server/AI approach can be added later behind the same `ScanService` interface.

## D4. Region map instead of pixel flood fill for the bucket
A plain colour flood fill leaks through any gap and leaves a light halo along anti-aliased edges. Instead we precompute, once per image, a map `pixel -> region id`:
- line mask via Otsu + local-mean adaptive threshold (handles photos with uneven lighting);
- the mask is dilated by a few pixels only to *compute regions*, which seals small gaps without changing the visible lines;
- line pixels are then assigned to the nearest region (multi-source BFS), so a fill reaches right up to the line and nothing is left white;
- tiny regions (< `minRegionArea`) are merged into the lines to avoid dust-sized fills.
A tap becomes an O(region) paint with no leaking and no halo.

## D5. Lines live in their own locked layer above the colour layers
The user can never paint over the outline, and fills do not need to be undone around the lines. The line layer is black with alpha, so colour shows through smooth edges.

## D6. Raster layers as `ui.Image`, strokes rasterized on release
`ui.Image` is immutable and GPU-backed, so undo is just swapping to the previous image (cheap, no diffing). Live strokes are drawn as vector paths over the layer during the drag, then baked on pointer-up. Fill is the only operation that needs raw pixels (read bytes, write region, decode back).

## D7. Command pattern for history
Each edit stores `(layer, before, after)` images; undo/redo swap them. Capped at 40 steps to bound memory. Layer structure changes (add/remove/reorder) are not undoable in v1 to keep scope manageable.

## D8. Strategy pattern for tools
Every tool implements one `Tool` interface (`onDown/onMove/onUp`, optional `paintOverlay`). Adding a tool means adding a class, not editing a switch in the canvas.

## D9. Repository pattern for storage
`ProjectRepository` saves each project as a folder (`meta.json`, per-layer PNGs, `lines.png`, `regions.bin`, thumbnail). ViewModels depend on the interface, so storage can change (database, cloud) without touching UI.

## D10. Scan input capped at ~1600 px on the long side
Bounds memory (regions are `Int32List`, 4 bytes/pixel) and scan time, and is plenty for a phone screen. Export uses the same resolution.

## D11. Constant stroke width (no pressure) in v1
Keeps the stroke pipeline simple and deterministic; pressure-sensitive width is a planned polish item.

## D12. Tests target pure logic
The scan pipeline is pure Dart and covered by synthetic-image tests (closed shape, small gap sealed, big gap leaks, speck removal, nested shapes).
