/// Shared Google Cloud Vector Map configuration for Vexda web maps.
library;

import 'vexda_cloud_map_config.local.dart' show kVexdaWebCloudMapId;

/// Cloud Map ID used by every web [GoogleMap] instance.
///
/// Styling is applied in Google Cloud Map Styles — not via JSON `styles:`.
/// Configure `kVexdaWebCloudMapId` in gitignored
/// [vexda_cloud_map_config.local.dart] (see [kVexdaWebCloudMapId]).
abstract final class VexdaCloudMapConfig {
  VexdaCloudMapConfig._();

  /// Cloud Vector Map ID (JavaScript map type, Vector renderer).
  static const String mapId = kVexdaWebCloudMapId;

  static bool get isConfigured => mapId.trim().isNotEmpty;

  /// True when web maps should use Cloud Vector Map ID styling.
  static bool get usesVectorMaps => isConfigured;
}
