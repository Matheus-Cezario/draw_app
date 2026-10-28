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

## D13. Kid-first controls: fixed choices instead of sliders
Young children struggle with precise drags. Brush size is 4 big buttons, layer opacity is 3 chips, scan tuning is chip groups, and colours are a fixed palette of 32 big dots (two rows in portrait, one in landscape, light/strong pairs per hue). The free HSV picker was removed.

## D14. Size buttons only for tools that use size
Bucket, eyedropper and move ignore brush size, so their size buttons are hidden (`toolUsesSize`) to avoid controls that do nothing.

## D15. Layout follows orientation
Colours stay on top. Portrait: tools strip below the canvas. Landscape: tools in a side rail, so the canvas keeps its height.

## D16. Own colour UI instead of `flex_color_picker`
The package's `ColorCodeField` threw "No MaterialLocalizations found" on this Flutter version. A fixed palette is also simpler for kids, so the dependency was dropped.

## D17. Bundled rounded font (Fredoka, OFL) for the title
Bundled instead of fetched at runtime so the app works offline and has no network dependency.

## D18. Start screen with a self-painting picture
A short animation (a framed scene painted piece by piece) and one big, still Play button. The button does not pulse, so it stays easy to tap.

## D19. Renaming
Tap the title in the editor, or long-press a drawing in the gallery. Names are stored in `meta.json`.

## D20. Cropping is our own screen, applied before the scan
A native cropper package would need per-platform setup and would not match the playful look. `CropPage` lets the child drag corners, sides or the whole box; it returns a normalised `CropRect`. The crop is always applied to the *original* decoded picture (never to an already cropped one), so the child can re-crop or go back to the whole picture without losing quality. Cropping happens before `scanLineArt`, so the line layer and the region map have the cropped size. `cropPicture` is pure Dart and unit tested.

## D21. App name: Color Fun
Short, easy for children to say and spell, and it works in English and Portuguese. Changed in the app title, the start screen, the iOS display name, the Android label and the web manifest. The application id and iOS bundle id are now `com.mcezario.colorfun`. Android release builds are signed with a private upload key kept outside the repo (`~/.android-keys/colorfun/`, referenced by the git-ignored `android/key.properties`); without that file the build falls back to the debug key.

## D22. Ready-made drawings are generated pictures, bundled as grey-scale PNGs
(Replaces the first version, which drew 20 vector pages in code with a `Pen` helper.) The colouring book has 12 categories (animals, dinosaurs, ocean, forest, cars, trains, city, space, princesses, toys, plush toys, food), 10 pages each. The pictures are made with Gemini (black outlines on white, no colour, closed shapes) and live as sources in `assets/draw_lib/<category>/NN_name.png`, which is not bundled.
- `tools/build_library.py` turns them into what the app ships: `assets/library/<category>/NN_name.png` (grey-scale, long side 1280 px, a levels curve removes paper noise, 16 grey levels, about 50 kB each), the generated `lib/core/library/catalog.dart` and the asset folders in `pubspec.yaml`. Display names (English) come from `tools/library_names.json`. Run it again after adding or changing pictures.
- A page is loaded from the bundle and goes through the very same scan as a photo (`loadDrawing` -> `ScanService.decode` -> `scanLineArt`), so there is one code path. `test/library_test.dart` scans every page and fails if the outlines leak.
- Why PNGs now: the vector pages looked like hand-made shapes, and cute, varied pages are much cheaper to produce with an image model than to write as code. The cost is binary assets (about 6 MB for 115 pages) instead of a small repo.

## D23. Categories on one screen
The "Colouring book" screen shows one row per category (coloured header, horizontally scrolling paper cards) instead of tabs, so a child sees everything by scrolling in one direction and each category is recognisable by colour and icon.

## D24. Free plan with ads, Plus subscription through Google Play
Free: up to 3 drawings at the same time, no PNG export, banner and occasional interstitial ads. Subscribers ("Color Fun Plus", `premium_monthly` / `premium_yearly`): everything, no ads. Android only for now.
- **Identity is the Play purchase token**; the app has no accounts. After a purchase or restore the app sends the token to a separate, generic backend (`subs-backend` repo, Cloud Run + Firestore) that validates it with the Play Developer API, acknowledges it and answers `{active, entitlements, expiresAt}`. The same backend serves other apps: each app is a Firestore document mapping product ids to entitlements.
- `EntitlementService` (`lib/core/billing/`) caches the last answer and keeps premium for 3 days past the known expiry when the backend is unreachable, so a subscriber is never locked out by bad connectivity. A definite "inactive" answer revokes at once.
- The limits are plain functions in `plan_limits.dart`. The drawing limit is checked in one place, the gallery's "New" sheet, because every way of creating a drawing starts there. Deleting drawings frees slots; someone who already has more than 3 keeps them but cannot add more.
- The app is for children: ads use `AgeRestrictedTreatment.child`, rating G and non-personalised requests, and the `AD_ID` permission is removed from the manifest. Ads are never shown while drawing; the interstitial appears only when returning to the gallery, every third time.
- Build-time config (`--dart-define`): `SUBS_API_URL`, `ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID`. Defaults are Google's test ad ids. The AdMob app id in `AndroidManifest.xml` is also the test id and must be replaced before publishing.
