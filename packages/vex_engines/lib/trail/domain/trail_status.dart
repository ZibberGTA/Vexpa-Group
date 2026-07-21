/// Trail lifecycle status in domain terms.
enum TrailStatus {
  draft,
  published,
  disabled,
  archived;

  bool get isTerminal => this == TrailStatus.archived;

  bool get isPublishedLike => this == TrailStatus.published;

  bool get isPubliclyHidden =>
      this == TrailStatus.draft ||
      this == TrailStatus.archived ||
      this == TrailStatus.disabled;
}
