import 'package:vex_core/vex_core.dart';

/// Contract for discovery index lookups — implemented by app Firebase adapters.
abstract interface class DiscoveryVenueIndexRepository {
  Future<DataResult<Set<String>>> searchVenueIds({required List<String> terms});
}
