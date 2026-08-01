/// XP-06 privacy-safe share cards for achievements and quiz scores.
///
/// Cards never carry school name, email, guardian contact, attendance, or
/// marks. Display names are reduced to a first-name token before share text
/// is built. Image delivery and social targets remain SOC-04.
enum ShareCardKind {
  achievement,
  quizScore;

  static ShareCardKind fromName(String value) => switch (value) {
        'quiz_score' || 'quizScore' => ShareCardKind.quizScore,
        _ => ShareCardKind.achievement,
      };

  String get wireName => switch (this) {
        ShareCardKind.achievement => 'achievement',
        ShareCardKind.quizScore => 'quiz_score',
      };
}

/// A clipboard-ready share payload. Built by the server (or a fake that
/// follows the same privacy rules).
class ShareCard {
  const ShareCard({
    required this.kind,
    required this.firstName,
    required this.headlineEn,
    required this.headlineUr,
    required this.bodyEn,
    required this.bodyUr,
    required this.shareTextEn,
    required this.shareTextUr,
    this.slug = '',
    this.scorePercent,
  });

  final ShareCardKind kind;
  final String firstName;
  final String headlineEn;
  final String headlineUr;
  final String bodyEn;
  final String bodyUr;
  final String shareTextEn;
  final String shareTextUr;
  final String slug;
  final int? scorePercent;

  String headlineFor({required bool urdu}) => urdu ? headlineUr : headlineEn;

  String bodyFor({required bool urdu}) => urdu ? bodyUr : bodyEn;

  String shareTextFor({required bool urdu}) =>
      urdu ? shareTextUr : shareTextEn;

  /// First whitespace-separated token; never the full school-linked name.
  static String privacySafeFirstName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'Learner';
    final first = trimmed.split(RegExp(r'\s+')).first;
    return first.isEmpty ? 'Learner' : first;
  }

  /// Rejects payloads that still smuggle private academic or contact fields.
  static bool isPrivacySafePayload(Map<String, dynamic> row) {
    const forbidden = {
      'email',
      'guardian',
      'guardian_contact',
      'school',
      'school_name',
      'school_id',
      'attendance',
      'attendance_label',
      'mark',
      'marks',
      'latest_mark',
      'latest_mark_label',
      'class_name',
      'phone',
      'payment',
    };
    for (final key in row.keys) {
      if (forbidden.contains(key.toLowerCase())) return false;
    }
    final blob = row.values.map((value) => '$value').join(' ').toLowerCase();
    for (final needle in [
      '@',
      'attendance',
      'guardian',
      'school mark',
      'term mark',
    ]) {
      if (blob.contains(needle)) return false;
    }
    return true;
  }

  factory ShareCard.achievement({
    required String displayName,
    required String titleEn,
    required String titleUr,
    String descriptionEn = '',
    String descriptionUr = '',
    String slug = '',
  }) {
    final first = privacySafeFirstName(displayName);
    final headlineEn = '$first earned $titleEn';
    final headlineUr = '$first نے $titleUr حاصل کیا';
    final bodyEn = descriptionEn.isEmpty
        ? 'A Nano achievement unlocked.'
        : descriptionEn;
    final bodyUr = descriptionUr.isEmpty
        ? 'Nano کا ایک اعزاز کھلا۔'
        : descriptionUr;
    return ShareCard(
      kind: ShareCardKind.achievement,
      firstName: first,
      headlineEn: headlineEn,
      headlineUr: headlineUr,
      bodyEn: bodyEn,
      bodyUr: bodyUr,
      shareTextEn: '$headlineEn on Nano! $bodyEn',
      shareTextUr: '$headlineUr — Nano! $bodyUr',
      slug: slug,
    );
  }

  factory ShareCard.quizScore({
    required String displayName,
    required int scorePercent,
    required bool passed,
  }) {
    final first = privacySafeFirstName(displayName);
    final clamped = scorePercent.clamp(0, 100);
    final headlineEn = passed
        ? '$first scored $clamped% on a Nano quiz'
        : '$first tried a Nano quiz ($clamped%)';
    final headlineUr = passed
        ? '$first نے Nano کوئز میں $clamped% حاصل کیے'
        : '$first نے Nano کوئز کیا ($clamped%)';
    const bodyEn = 'Practice makes progress — no academic marks here.';
    const bodyUr = 'مشق سے پیشرفت — یہاں تعلیمی نمبر نہیں۔';
    return ShareCard(
      kind: ShareCardKind.quizScore,
      firstName: first,
      headlineEn: headlineEn,
      headlineUr: headlineUr,
      bodyEn: bodyEn,
      bodyUr: bodyUr,
      shareTextEn: '$headlineEn! $bodyEn',
      shareTextUr: '$headlineUr! $bodyUr',
      scorePercent: clamped,
    );
  }

  factory ShareCard.fromRow(Map<String, dynamic> row) {
    if (!isPrivacySafePayload(row)) {
      throw StateError('Share card payload failed privacy review.');
    }
    return ShareCard(
      kind: ShareCardKind.fromName(row['kind'] as String? ?? 'achievement'),
      firstName: row['first_name'] as String? ?? 'Learner',
      headlineEn: row['headline_en'] as String? ?? '',
      headlineUr: row['headline_ur'] as String? ?? '',
      bodyEn: row['body_en'] as String? ?? '',
      bodyUr: row['body_ur'] as String? ?? '',
      shareTextEn: row['share_text_en'] as String? ?? '',
      shareTextUr: row['share_text_ur'] as String? ?? '',
      slug: row['slug'] as String? ?? '',
      scorePercent: row['score_percent'] as int?,
    );
  }
}

/// Max pins a learner may feature on Me (handbook featured_achievements).
const int kMaxFeaturedAchievements = 3;
