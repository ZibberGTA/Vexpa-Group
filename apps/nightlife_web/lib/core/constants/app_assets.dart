import 'package:flutter/widgets.dart';

/// Central registry for Flutter asset paths.
///
/// Every path here is pubspec-relative and already includes the `assets/` prefix.
/// Pass these constants directly to [AssetImage], [Image.asset], and
/// [precacheImage] — never prepend `assets/` again.
class AppAssets {
  AppAssets._();

  static const String backgroundsPath = 'assets/backgrounds';

  /// Global site background for public pages and the venue portal.
  static const String globalBackground = 'assets/backgrounds/newbg.png';

  static const AssetImage globalBackgroundImage =
      AssetImage(globalBackground);

  static const String vexdaLogo = 'assets/images/vexda_logo_right.png';

  /// Hero container artwork — scoped to the homepage hero panel only.
  static const String heroArtwork = 'assets/backgrounds/mobilebg.png';

  static const AssetImage heroArtworkImage = AssetImage(heroArtwork);

  /// Homepage immersive background — canonical site artwork on disk.
  static const String homeBackground = globalBackground;

  static const AssetImage homeBackgroundImage = globalBackgroundImage;

  static const String businessBackground = '$backgroundsPath/business_background.webp';
  static const String venueBackground = '$backgroundsPath/venue_background.webp';
}
