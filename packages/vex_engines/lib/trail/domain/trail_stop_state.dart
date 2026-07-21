/// Customer stop progress state.
enum TrailStopState {
  upcoming,
  current,
  checkedIn,
  skipped,
  missed,
  completed;

  bool get isTerminal =>
      this == TrailStopState.checkedIn ||
      this == TrailStopState.skipped ||
      this == TrailStopState.missed ||
      this == TrailStopState.completed;
}
