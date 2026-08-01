import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// XP-06 featured pins and privacy-safe share card builders.
abstract class ShareCardRepository {
  Future<List<String>> featuredAwardIds();

  /// Replaces the featured set. At most [kMaxFeaturedAchievements] ids;
  /// each must be an award the learner already owns (server-enforced).
  Future<List<String>> setFeatured(List<String> awardIds);

  Future<ShareCard> forAchievement(String awardId);

  Future<ShareCard> forQuizScore({
    required int scorePercent,
    required bool passed,
  });
}

class FakeShareCardRepository implements ShareCardRepository {
  FakeShareCardRepository({
    this.displayName = 'Ali Alpha',
    List<AchievementAward>? awards,
    List<String>? featured,
  })  : _awards = [...?awards],
        _featured = [...?featured];

  String displayName;
  final List<AchievementAward> _awards;
  final List<String> _featured;

  List<String> get featuredSnapshot => List.unmodifiable(_featured);

  void seedAward(AchievementAward award) {
    if (_awards.any((a) => a.awardId == award.awardId)) return;
    _awards.add(award);
  }

  @override
  Future<List<String>> featuredAwardIds() async => List.unmodifiable(_featured);

  @override
  Future<List<String>> setFeatured(List<String> awardIds) async {
    final unique = <String>[];
    for (final id in awardIds) {
      if (unique.contains(id)) continue;
      if (!_awards.any((a) => a.awardId == id)) {
        throw StateError('Can only feature awards you own.');
      }
      unique.add(id);
      if (unique.length >= kMaxFeaturedAchievements) break;
    }
    _featured
      ..clear()
      ..addAll(unique);
    return featuredAwardIds();
  }

  @override
  Future<ShareCard> forAchievement(String awardId) async {
    AchievementAward? award;
    for (final candidate in _awards) {
      if (candidate.awardId == awardId) {
        award = candidate;
        break;
      }
    }
    if (award == null) {
      throw StateError('Achievement award not found.');
    }
    return ShareCard.achievement(
      displayName: displayName,
      titleEn: award.titleEn,
      titleUr: award.titleUr,
      descriptionEn: award.descriptionEn,
      descriptionUr: award.descriptionUr,
      slug: award.slug,
    );
  }

  @override
  Future<ShareCard> forQuizScore({
    required int scorePercent,
    required bool passed,
  }) async {
    return ShareCard.quizScore(
      displayName: displayName,
      scorePercent: scorePercent,
      passed: passed,
    );
  }
}

class SupabaseShareCardRepository implements ShareCardRepository {
  SupabaseShareCardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<String>> featuredAwardIds() async {
    final raw = await _client.rpc('my_featured_achievements');
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        if ((row['award_id'] as String?)?.isNotEmpty ?? false)
          row['award_id'] as String,
    ];
  }

  @override
  Future<List<String>> setFeatured(List<String> awardIds) async {
    final raw = await _client.rpc(
      'set_featured_achievements',
      params: {'p_award_ids': awardIds},
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        if ((row['award_id'] as String?)?.isNotEmpty ?? false)
          row['award_id'] as String,
    ];
  }

  @override
  Future<ShareCard> forAchievement(String awardId) async {
    final raw = await _client.rpc(
      'build_share_card',
      params: {
        'p_kind': 'achievement',
        'p_award_id': awardId,
      },
    );
    if (raw is! Map) {
      throw StateError('Share card unavailable.');
    }
    return ShareCard.fromRow(Map<String, dynamic>.from(raw));
  }

  @override
  Future<ShareCard> forQuizScore({
    required int scorePercent,
    required bool passed,
  }) async {
    final raw = await _client.rpc(
      'build_share_card',
      params: {
        'p_kind': 'quiz_score',
        'p_score_percent': scorePercent,
        'p_passed': passed,
      },
    );
    if (raw is! Map) {
      throw StateError('Share card unavailable.');
    }
    return ShareCard.fromRow(Map<String, dynamic>.from(raw));
  }
}
