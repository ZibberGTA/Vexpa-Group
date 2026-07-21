/// Visibility evaluation audience.
enum TrailVisibilityAudience { publicMobile, publicWeb, admin, preview }

/// Structured public visibility decision.
final class TrailVisibilityDecision {
  const TrailVisibilityDecision({
    required this.isVisible,
    required this.reasonCode,
    this.reasonMessage,
    this.nextVisibleAt,
    this.expiresAt,
  });

  const TrailVisibilityDecision.visible({this.nextVisibleAt, this.expiresAt})
    : isVisible = true,
      reasonCode = 'visible',
      reasonMessage = null;

  final bool isVisible;
  final String reasonCode;
  final String? reasonMessage;
  final DateTime? nextVisibleAt;
  final DateTime? expiresAt;
}
