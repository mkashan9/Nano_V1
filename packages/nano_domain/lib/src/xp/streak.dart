/// XP-05 streak read model.
enum StreakStatus {
  fresh,
  active,
  paused;

  static StreakStatus fromName(String value) => switch (value) {
        'active' => StreakStatus.active,
        'paused' => StreakStatus.paused,
        _ => StreakStatus.fresh,
      };
}

class StreakSnapshot {
  const StreakSnapshot({
    required this.current,
    required this.longest,
    this.lastActiveOn,
    this.status = StreakStatus.fresh,
    this.notice,
    this.messageEn = '',
    this.messageUr = '',
  });

  final int current;
  final int longest;
  final DateTime? lastActiveOn;
  final StreakStatus status;
  final String? notice;
  final String messageEn;
  final String messageUr;

  bool get hasGentleNotice =>
      notice == 'welcome_back' && messageEn.isNotEmpty;

  String messageFor({required bool urdu}) => urdu ? messageUr : messageEn;

  static const empty = StreakSnapshot(current: 0, longest: 0);

  factory StreakSnapshot.fromJson(Map<String, dynamic> json) {
    final last = json['last_active_on'];
    return StreakSnapshot(
      current: (json['current'] as num?)?.toInt() ?? 0,
      longest: (json['longest'] as num?)?.toInt() ?? 0,
      lastActiveOn: last == null ? null : DateTime.parse('$last').toUtc(),
      status: StreakStatus.fromName(json['status'] as String? ?? 'fresh'),
      notice: json['notice'] as String?,
      messageEn: json['message_en'] as String? ?? '',
      messageUr: json['message_ur'] as String? ?? '',
    );
  }
}
