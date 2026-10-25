/// What the free plan allows. Subscribers have no limits.
const int freeDrawingLimit = 3;

/// Whether a new drawing may be created. Deleting drawings frees slots, so the
/// limit is about drawings kept at the same time.
bool canCreateDrawing({required bool isPremium, required int drawingCount}) =>
    isPremium || drawingCount < freeDrawingLimit;

/// Whether the drawing may be exported as a PNG.
bool canExportPng({required bool isPremium}) => isPremium;
