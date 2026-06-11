class SessionStats {
  const SessionStats({
    this.total = 0,
    this.good = 0,
    this.early = 0,
    this.late = 0,
    this.offsetTotalMs = 0,
  });

  final int total;
  final int good;
  final int early;
  final int late;
  final int offsetTotalMs;

  double get accuracy => total == 0 ? 0 : good / total;

  int get averageOffsetMs => total == 0 ? 0 : (offsetTotalMs / total).round();

  SessionStats record(int offsetMs) {
    final isGood = offsetMs.abs() <= 100;
    final isEarly = offsetMs < -100;
    final isLate = offsetMs > 100;

    return SessionStats(
      total: total + 1,
      good: good + (isGood ? 1 : 0),
      early: early + (isEarly ? 1 : 0),
      late: late + (isLate ? 1 : 0),
      offsetTotalMs: offsetTotalMs + offsetMs,
    );
  }
}
