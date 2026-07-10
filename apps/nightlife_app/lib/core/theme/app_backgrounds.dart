class AppBackgrounds {
  const AppBackgrounds._();

  static const String basePath = 'assets/backgrounds';

  /// Default app-wide background image.
  /// Place your file at: assets/backgrounds/background.png
  static const String defaultBackground = '$basePath/background.png';

  // For now every screen uses the same default image.
  // Later, you can swap any of these to screen-specific files again.
  static const String map = defaultBackground;
  static const String search = defaultBackground;
  static const String saved = defaultBackground;
  static const String business = defaultBackground;
  static const String manage = defaultBackground;
  static const String account = defaultBackground;
  static const String venue = defaultBackground;
  static const String artist = defaultBackground;
  static const String auth = defaultBackground;
}
