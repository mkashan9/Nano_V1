/// ADM-05 curator models for gamification policy and catalogs.
class GamificationAdminSnapshot {
  const GamificationAdminSnapshot({
    required this.dailyCap,
    this.awardRules = const [],
    this.levelRules = const [],
    this.achievements = const [],
    this.missions = const [],
  });

  final int dailyCap;
  final List<XpAwardRuleAdmin> awardRules;
  final List<LevelRuleAdmin> levelRules;
  final List<AchievementAdmin> achievements;
  final List<MissionAdmin> missions;

  int get xpPerLevel {
    if (levelRules.length < 2) return 250;
    return levelRules[1].minXp - levelRules[0].minXp;
  }

  factory GamificationAdminSnapshot.fromJson(Map<String, dynamic> json) {
    return GamificationAdminSnapshot(
      dailyCap: (json['daily_cap'] as num?)?.toInt() ?? 200,
      awardRules: [
        if (json['award_rules'] is List)
          for (final row in (json['award_rules'] as List).whereType<Map>())
            XpAwardRuleAdmin.fromJson(Map<String, dynamic>.from(row)),
      ],
      levelRules: [
        if (json['level_rules'] is List)
          for (final row in (json['level_rules'] as List).whereType<Map>())
            LevelRuleAdmin.fromJson(Map<String, dynamic>.from(row)),
      ],
      achievements: [
        if (json['achievements'] is List)
          for (final row in (json['achievements'] as List).whereType<Map>())
            AchievementAdmin.fromJson(Map<String, dynamic>.from(row)),
      ],
      missions: [
        if (json['missions'] is List)
          for (final row in (json['missions'] as List).whereType<Map>())
            MissionAdmin.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }
}

class XpAwardRuleAdmin {
  const XpAwardRuleAdmin({
    required this.sourceKind,
    required this.amount,
    this.notes = '',
  });

  final String sourceKind;
  final int amount;
  final String notes;

  bool get isEditable =>
      sourceKind == 'video_completion' ||
      sourceKind == 'quiz_pass' ||
      sourceKind == 'game_result';

  factory XpAwardRuleAdmin.fromJson(Map<String, dynamic> json) {
    return XpAwardRuleAdmin(
      sourceKind: json['source_kind'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class LevelRuleAdmin {
  const LevelRuleAdmin({required this.level, required this.minXp});

  final int level;
  final int minXp;

  factory LevelRuleAdmin.fromJson(Map<String, dynamic> json) {
    return LevelRuleAdmin(
      level: (json['level'] as num?)?.toInt() ?? 1,
      minXp: (json['min_xp'] as num?)?.toInt() ?? 0,
    );
  }
}

class AchievementAdmin {
  const AchievementAdmin({
    required this.id,
    required this.slug,
    required this.kind,
    required this.titleEn,
    required this.active,
    this.titleUr = '',
    this.ruleKind = '',
    this.sortOrder = 0,
  });

  final String id;
  final String slug;
  final String kind;
  final String titleEn;
  final String titleUr;
  final String ruleKind;
  final int sortOrder;
  final bool active;

  factory AchievementAdmin.fromJson(Map<String, dynamic> json) {
    return AchievementAdmin(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      kind: json['kind'] as String? ?? 'achievement',
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      ruleKind: json['rule_kind'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }
}

class MissionAdmin {
  const MissionAdmin({
    required this.id,
    required this.slug,
    required this.cadence,
    required this.titleEn,
    required this.targetCount,
    required this.xpBonus,
    required this.active,
    this.titleUr = '',
    this.ruleKind = '',
    this.sortOrder = 0,
  });

  final String id;
  final String slug;
  final String cadence;
  final String titleEn;
  final String titleUr;
  final String ruleKind;
  final int targetCount;
  final int xpBonus;
  final int sortOrder;
  final bool active;

  factory MissionAdmin.fromJson(Map<String, dynamic> json) {
    return MissionAdmin(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      cadence: json['cadence'] as String? ?? 'daily',
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      ruleKind: json['rule_kind'] as String? ?? '',
      targetCount: (json['target_count'] as num?)?.toInt() ?? 1,
      xpBonus: (json['xp_bonus'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
    );
  }
}

class XpAdjustmentResult {
  const XpAdjustmentResult({
    required this.ledgerId,
    required this.userId,
    required this.amount,
    required this.reason,
  });

  final String ledgerId;
  final String userId;
  final int amount;
  final String reason;

  factory XpAdjustmentResult.fromJson(Map<String, dynamic> json) {
    return XpAdjustmentResult(
      ledgerId: json['ledger_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
    );
  }
}
