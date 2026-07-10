export 'package:vex_engines/venue/shared/image_position_metadata.dart';

import 'package:flutter/painting.dart';
import 'package:vex_engines/venue/shared/image_position_metadata.dart';

/// Flutter presentation helper for [ImagePositionMetadata].
extension ImagePositionMetadataAlignment on ImagePositionMetadata {
  Alignment get alignment => Alignment(
    (focalPointX.clamp(0, 1) * 2) - 1,
    (focalPointY.clamp(0, 1) * 2) - 1,
  );
}
