/// Submission payload for `trail.venue_participation` workflow requests.
final class TrailParticipationSubmissionPayload {
  const TrailParticipationSubmissionPayload({
    required this.schemaVersion,
    required this.trailId,
    required this.venueId,
    required this.requestedStopOrder,
    required this.participationNote,
  });

  static const currentSchemaVersion = 1;
  static const maxParticipationNoteLength = 2000;

  final int schemaVersion;
  final String trailId;
  final String venueId;
  final int requestedStopOrder;
  final String participationNote;

  Map<String, Object?> toPayloadValues() {
    return {
      'schemaVersion': schemaVersion,
      'trailId': trailId,
      'venueId': venueId,
      'requestedStopOrder': requestedStopOrder,
      'participationNote': participationNote,
    };
  }

  static TrailParticipationSubmissionPayload? fromPayloadValues(
    Map<String, Object?> values,
  ) {
    final schemaVersion = values['schemaVersion'];
    final trailId = values['trailId']?.toString().trim();
    final venueId = values['venueId']?.toString().trim();
    final requestedStopOrder = values['requestedStopOrder'];
    final participationNote = values['participationNote']?.toString() ?? '';

    if (trailId == null ||
        trailId.isEmpty ||
        venueId == null ||
        venueId.isEmpty ||
        requestedStopOrder is! num) {
      return null;
    }

    return TrailParticipationSubmissionPayload(
      schemaVersion: schemaVersion is num ? schemaVersion.toInt() : 1,
      trailId: trailId,
      venueId: venueId,
      requestedStopOrder: requestedStopOrder.toInt(),
      participationNote: participationNote,
    );
  }
}
