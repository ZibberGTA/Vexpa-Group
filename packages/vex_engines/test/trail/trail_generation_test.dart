import 'package:test/test.dart';
import 'package:vex_engines/trail/trail_engine.dart';

void main() {
  group('TrailGenerationPolicy', () {
    test('scores and selects top venues', () {
      final result = TrailGenerationPolicy.generateDraft(
        candidates: [
          const TrailGenerationCandidate(
            venueId: 'quiet',
            name: 'Quiet',
            address: '',
            bannerImageUrl: '',
            logoUrl: '',
            crowdLevel: 'quiet',
            category: 'bar',
            hasDeals: false,
            featureTags: [],
          ),
          const TrailGenerationCandidate(
            venueId: 'packed',
            name: 'Packed',
            address: '',
            bannerImageUrl: 'x',
            logoUrl: '',
            crowdLevel: 'packed',
            category: 'cocktail bar',
            hasDeals: true,
            featureTags: ['live'],
          ),
        ],
        now: DateTime(2026, 7, 18, 18),
      );

      expect(result, isA<TrailSuccess<TrailGenerationProposal>>());
      final proposal =
          (result as TrailSuccess).value as TrailGenerationProposal;
      expect(proposal.trail.stops.first.venueId, 'packed');
      expect(proposal.trail.status, TrailStatus.draft);
      expect(proposal.trail.stops.first.order, 1);
    });

    test('fails when no candidates', () {
      final result = TrailGenerationPolicy.generateDraft(
        candidates: const [],
        now: DateTime(2026, 7, 18, 18),
      );
      expect(result, isA<TrailFailure>());
    });

    test('uses later start when now is after 19:00', () {
      final now = DateTime(2026, 7, 18, 21);
      final result = TrailGenerationPolicy.generateDraft(
        candidates: [
          const TrailGenerationCandidate(
            venueId: 'v1',
            name: 'Venue',
            address: '',
            bannerImageUrl: '',
            logoUrl: '',
            crowdLevel: 'busy',
            category: 'bar',
            hasDeals: false,
            featureTags: [],
          ),
        ],
        now: now,
      );
      final proposal =
          (result as TrailSuccess).value as TrailGenerationProposal;
      expect(
        proposal.trail.availabilityStart.isAfter(DateTime(2026, 7, 18, 19)),
        isTrue,
      );
    });
  });
}
