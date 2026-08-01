import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// XP-03 read side for granted achievements and stickers.
///
/// Grants happen only on the server inside evaluate_achievements.
abstract class AchievementRepository {
  Future<List<AchievementAward>> mine();
}

class FakeAchievementRepository implements AchievementRepository {
  FakeAchievementRepository({List<AchievementAward>? awards})
      : _awards = [...?awards];

  final List<AchievementAward> _awards;

  @override
  Future<List<AchievementAward>> mine() async {
    final sorted = [..._awards]
      ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
    return sorted;
  }

  void grant(AchievementAward award) {
    if (_awards.any((a) => a.slug == award.slug)) return;
    _awards.add(award);
  }
}

class SupabaseAchievementRepository implements AchievementRepository {
  SupabaseAchievementRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AchievementAward>> mine() async {
    final raw = await _client.rpc('my_achievements');
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((row) => AchievementAward.fromRow(Map<String, dynamic>.from(row)))
        .toList();
  }
}
