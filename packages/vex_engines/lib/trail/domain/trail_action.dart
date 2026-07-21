/// Lifecycle actions supported by the current product.
enum TrailLifecycleAction {
  createDraft,
  updateDraft,
  publish,
  unpublish,
  archive,
  disable,
  duplicate,
  delete,
  replaceDocument,
  saveStops,
}

/// Customer progress actions supported by the current product.
enum TrailProgressAction { join, resume, checkIn, continueStop, skipStop }
