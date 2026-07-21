import '../domain/trail.dart';
import '../domain/trail_publication_policy.dart';
import '../domain/trail_publication_readiness.dart';

/// Publication readiness assessment service.
final class TrailPublicationService {
  const TrailPublicationService();

  TrailPublicationReadiness assessReadiness(Trail trail) {
    return TrailPublicationPolicy.evaluate(trail);
  }

  bool isReady(Trail trail) => TrailPublicationPolicy.isReady(trail);
}
