class UpcomingPlanItem {
  const UpcomingPlanItem({
    required this.dayOfMonth,
    required this.monthLabel,
    required this.title,
    required this.timeLabel,
    required this.joinedCount,
    required this.participantInitials,
  });

  final int dayOfMonth;
  /// Uppercase month abbreviation, e.g. MAR
  final String monthLabel;
  final String title;
  /// e.g. "09:00"
  final String timeLabel;
  final int joinedCount;
  /// One letter per stacked avatar (left to right).
  final List<String> participantInitials;

  static const List<UpcomingPlanItem> samples = [
    UpcomingPlanItem(
      dayOfMonth: 15,
      monthLabel: 'MAR',
      title: 'Weekend Hike Meetup',
      timeLabel: '09:00',
      joinedCount: 12,
      participantInitials: ['A', 'M', 'K'],
    ),
    UpcomingPlanItem(
      dayOfMonth: 3,
      monthLabel: 'APR',
      title: 'Trail Clean-up Day',
      timeLabel: '14:30',
      joinedCount: 8,
      participantInitials: ['E', 'L', 'T'],
    ),
  ];
}
