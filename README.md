# Color Fun

A colouring/painting app (Flutter). Import a picture of a drawing; the app scans
the lines and builds a map of paintable regions so the **bucket tool works on
photos and scans** without leaking or leaving white halos.

- Architecture and pattern: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Why we decided what we decided: [docs/DECISIONS.md](docs/DECISIONS.md)

## Features
Ready-made colouring book (animals, cars, motorbikes, houses, plants),

Brush, pencil, eraser, bucket (region based), eyedropper, line/rectangle/ellipse,
text, rectangular select & move, layers (visibility, opacity, order), undo/redo,
pinch zoom/pan, project gallery with autosave, PNG export/share.

## Development
```
flutter pub get
flutter analyze
flutter test
flutter run
```
