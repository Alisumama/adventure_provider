/// Active trail session shown on the home hero card.
class ActiveSessionData {
  const ActiveSessionData({
    required this.trailName,
    required this.activityLabel,
    required this.startedAgoLabel,
    required this.km,
    required this.timeLabel,
    required this.steps,
    required this.kcal,
  });

  final String trailName;
  final String activityLabel;
  final String startedAgoLabel;
  final double km;
  final String timeLabel;
  final int steps;
  final int kcal;

  /// Sample session for UI preview / tests.
  static const ActiveSessionData preview = ActiveSessionData(
    trailName: 'Eagle Ridge Loop',
    activityLabel: 'Hiking',
    startedAgoLabel: '1h 24m ago',
    km: 4.2,
    timeLabel: '1h 24m',
    steps: 8420,
    kcal: 312,
  );
}
