/// Local migration switch for TrailService cutover.
///
/// Default is the VexTrail-backed facade. Tests may override [useVexTrailFacade]
/// or set [overrideForTests] without introducing a remote flag.
abstract final class TrailServiceMigrationConfig {
  static const bool useVexTrailFacade = true;

  static bool? overrideForTests;

  static bool get enabled => overrideForTests ?? useVexTrailFacade;

  static void resetTestOverrides() {
    overrideForTests = null;
  }
}
