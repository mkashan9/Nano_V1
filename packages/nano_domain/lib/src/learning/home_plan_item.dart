class HomePlanItem {
  const HomePlanItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xpReward,
    this.completed = false,
    this.progress = 0,
    this.target = 1,
    this.cadence = 'daily',
  });

  final String id;
  final String title;
  final String subtitle;
  final int xpReward;

  /// XP-04: true when this period's mission is done.
  final bool completed;
  final int progress;
  final int target;
  final String cadence;
}
