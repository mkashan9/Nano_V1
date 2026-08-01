import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// ADM-05 platform gamification policy and catalog administration.
abstract class GamificationAdminRepository {
  Future<GamificationAdminSnapshot> load();

  Future<void> setDailyCap(int dailyCap);

  Future<void> setAwardAmount({
    required String sourceKind,
    required int amount,
  });

  Future<void> setLevelStep(int xpPerLevel);

  Future<void> setAchievementActive({
    required String achievementId,
    required bool active,
  });

  Future<void> setMissionActive({
    required String missionId,
    required bool active,
  });

  Future<void> setMissionRewards({
    required String missionId,
    required int targetCount,
    required int xpBonus,
  });

  Future<XpAdjustmentResult> adjustXp({
    required String userId,
    required int amount,
    required String reason,
  });
}

class FakeGamificationAdminRepository implements GamificationAdminRepository {
  FakeGamificationAdminRepository({GamificationAdminSnapshot? seed})
      : _snapshot = seed ?? _default;

  GamificationAdminSnapshot _snapshot;
  final adjustments = <XpAdjustmentResult>[];

  static final _default = GamificationAdminSnapshot(
    dailyCap: 200,
    awardRules: const [
      XpAwardRuleAdmin(
        sourceKind: 'video_completion',
        amount: 10,
        notes: 'Topic completion',
      ),
      XpAwardRuleAdmin(
        sourceKind: 'quiz_pass',
        amount: 30,
        notes: 'First quiz pass',
      ),
      XpAwardRuleAdmin(sourceKind: 'manual_adjust', amount: 0),
      XpAwardRuleAdmin(sourceKind: 'game_result', amount: 20),
    ],
    levelRules: [
      for (var level = 1; level <= 5; level++)
        LevelRuleAdmin(level: level, minXp: (level - 1) * 250),
    ],
    achievements: const [
      AchievementAdmin(
        id: 'ach-1',
        slug: 'first_steps',
        kind: 'sticker',
        titleEn: 'First Steps',
        active: true,
        sortOrder: 10,
      ),
      AchievementAdmin(
        id: 'ach-2',
        slug: 'quiz_rookie',
        kind: 'achievement',
        titleEn: 'Quiz Rookie',
        active: true,
        sortOrder: 20,
      ),
    ],
    missions: const [
      MissionAdmin(
        id: 'mis-1',
        slug: 'daily_lesson',
        cadence: 'daily',
        titleEn: 'Complete a lesson',
        targetCount: 1,
        xpBonus: 15,
        active: true,
        sortOrder: 10,
      ),
      MissionAdmin(
        id: 'mis-2',
        slug: 'weekly_lessons',
        cadence: 'weekly',
        titleEn: 'Finish 3 lessons',
        targetCount: 3,
        xpBonus: 50,
        active: true,
        sortOrder: 30,
      ),
    ],
  );

  @override
  Future<GamificationAdminSnapshot> load() async => _snapshot;

  @override
  Future<void> setDailyCap(int dailyCap) async {
    if (dailyCap < 1) throw StateError('Daily cap must be at least 1.');
    _snapshot = GamificationAdminSnapshot(
      dailyCap: dailyCap,
      awardRules: _snapshot.awardRules,
      levelRules: _snapshot.levelRules,
      achievements: _snapshot.achievements,
      missions: _snapshot.missions,
    );
  }

  @override
  Future<void> setAwardAmount({
    required String sourceKind,
    required int amount,
  }) async {
    if (amount < 1) throw StateError('Award amount must be at least 1.');
    final next = [
      for (final rule in _snapshot.awardRules)
        if (rule.sourceKind == sourceKind)
          XpAwardRuleAdmin(
            sourceKind: rule.sourceKind,
            amount: amount,
            notes: rule.notes,
          )
        else
          rule,
    ];
    _snapshot = GamificationAdminSnapshot(
      dailyCap: _snapshot.dailyCap,
      awardRules: next,
      levelRules: _snapshot.levelRules,
      achievements: _snapshot.achievements,
      missions: _snapshot.missions,
    );
  }

  @override
  Future<void> setLevelStep(int xpPerLevel) async {
    if (xpPerLevel < 50 || xpPerLevel > 5000) {
      throw StateError('XP per level must be between 50 and 5000.');
    }
    _snapshot = GamificationAdminSnapshot(
      dailyCap: _snapshot.dailyCap,
      awardRules: _snapshot.awardRules,
      levelRules: [
        for (var level = 1; level <= 40; level++)
          LevelRuleAdmin(level: level, minXp: (level - 1) * xpPerLevel),
      ],
      achievements: _snapshot.achievements,
      missions: _snapshot.missions,
    );
  }

  @override
  Future<void> setAchievementActive({
    required String achievementId,
    required bool active,
  }) async {
    _snapshot = GamificationAdminSnapshot(
      dailyCap: _snapshot.dailyCap,
      awardRules: _snapshot.awardRules,
      levelRules: _snapshot.levelRules,
      achievements: [
        for (final item in _snapshot.achievements)
          if (item.id == achievementId)
            AchievementAdmin(
              id: item.id,
              slug: item.slug,
              kind: item.kind,
              titleEn: item.titleEn,
              titleUr: item.titleUr,
              ruleKind: item.ruleKind,
              sortOrder: item.sortOrder,
              active: active,
            )
          else
            item,
      ],
      missions: _snapshot.missions,
    );
  }

  @override
  Future<void> setMissionActive({
    required String missionId,
    required bool active,
  }) async {
    _snapshot = GamificationAdminSnapshot(
      dailyCap: _snapshot.dailyCap,
      awardRules: _snapshot.awardRules,
      levelRules: _snapshot.levelRules,
      achievements: _snapshot.achievements,
      missions: [
        for (final item in _snapshot.missions)
          if (item.id == missionId)
            MissionAdmin(
              id: item.id,
              slug: item.slug,
              cadence: item.cadence,
              titleEn: item.titleEn,
              titleUr: item.titleUr,
              ruleKind: item.ruleKind,
              targetCount: item.targetCount,
              xpBonus: item.xpBonus,
              sortOrder: item.sortOrder,
              active: active,
            )
          else
            item,
      ],
    );
  }

  @override
  Future<void> setMissionRewards({
    required String missionId,
    required int targetCount,
    required int xpBonus,
  }) async {
    if (targetCount < 1) throw StateError('Mission target must be at least 1.');
    if (xpBonus < 0) throw StateError('Mission XP bonus cannot be negative.');
    _snapshot = GamificationAdminSnapshot(
      dailyCap: _snapshot.dailyCap,
      awardRules: _snapshot.awardRules,
      levelRules: _snapshot.levelRules,
      achievements: _snapshot.achievements,
      missions: [
        for (final item in _snapshot.missions)
          if (item.id == missionId)
            MissionAdmin(
              id: item.id,
              slug: item.slug,
              cadence: item.cadence,
              titleEn: item.titleEn,
              titleUr: item.titleUr,
              ruleKind: item.ruleKind,
              targetCount: targetCount,
              xpBonus: xpBonus,
              sortOrder: item.sortOrder,
              active: item.active,
            )
          else
            item,
      ],
    );
  }

  @override
  Future<XpAdjustmentResult> adjustXp({
    required String userId,
    required int amount,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('A reason is required for manual XP adjustments.');
    }
    if (amount == 0) throw StateError('Adjustment amount cannot be zero.');
    final result = XpAdjustmentResult(
      ledgerId: 'ledger-${adjustments.length + 1}',
      userId: userId,
      amount: amount,
      reason: reason.trim(),
    );
    adjustments.add(result);
    return result;
  }
}

class SupabaseGamificationAdminRepository
    implements GamificationAdminRepository {
  SupabaseGamificationAdminRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<GamificationAdminSnapshot> load() async {
    final raw = await _client.rpc('list_gamification_admin');
    return GamificationAdminSnapshot.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<void> setDailyCap(int dailyCap) async {
    await _client.rpc('set_xp_daily_cap', params: {'p_daily_cap': dailyCap});
  }

  @override
  Future<void> setAwardAmount({
    required String sourceKind,
    required int amount,
  }) async {
    await _client.rpc(
      'set_xp_award_amount',
      params: {'p_source_kind': sourceKind, 'p_amount': amount},
    );
  }

  @override
  Future<void> setLevelStep(int xpPerLevel) async {
    await _client.rpc(
      'set_level_step',
      params: {'p_xp_per_level': xpPerLevel},
    );
  }

  @override
  Future<void> setAchievementActive({
    required String achievementId,
    required bool active,
  }) async {
    await _client.rpc(
      'set_achievement_active',
      params: {'p_achievement_id': achievementId, 'p_active': active},
    );
  }

  @override
  Future<void> setMissionActive({
    required String missionId,
    required bool active,
  }) async {
    await _client.rpc(
      'set_mission_active',
      params: {'p_mission_id': missionId, 'p_active': active},
    );
  }

  @override
  Future<void> setMissionRewards({
    required String missionId,
    required int targetCount,
    required int xpBonus,
  }) async {
    await _client.rpc(
      'set_mission_rewards',
      params: {
        'p_mission_id': missionId,
        'p_target_count': targetCount,
        'p_xp_bonus': xpBonus,
      },
    );
  }

  @override
  Future<XpAdjustmentResult> adjustXp({
    required String userId,
    required int amount,
    required String reason,
  }) async {
    final raw = await _client.rpc(
      'admin_adjust_xp',
      params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_reason': reason,
      },
    );
    return XpAdjustmentResult.fromJson(Map<String, dynamic>.from(raw as Map));
  }
}
