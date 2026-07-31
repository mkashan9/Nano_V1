import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Profile, privacy, and device sessions for the signed-in learner.
abstract class StudentProfileRepository {
  Future<StudentProfileView> loadProfile({
    required String userId,
    required String displayName,
    required AppRole role,
  });

  Future<PrivacySettings> loadPrivacy(String userId);

  Future<PrivacySettings> savePrivacy(PrivacySettings settings);

  Future<List<DeviceSession>> loadSessions(String userId);

  /// Server-backed and audited. Never revokes another learner's session.
  Future<void> revokeSession(String sessionId);
}

class FakeStudentProfileRepository implements StudentProfileRepository {
  FakeStudentProfileRepository({
    List<DeviceSession>? sessions,
    this._privacy,
    this.alwaysFail = false,
    this.revokeFails = false,
    this.progress = const (xp: 560, streak: 7, topics: 12),
  }) : _sessions = [...?sessions];

  final bool alwaysFail;
  final bool revokeFails;
  final ({int xp, int streak, int topics}) progress;

  final List<DeviceSession> _sessions;
  PrivacySettings? _privacy;

  final revokedSessionIds = <String>[];
  final privacyWrites = <PrivacySettings>[];

  @override
  Future<StudentProfileView> loadProfile({
    required String userId,
    required String displayName,
    required AppRole role,
  }) async {
    if (alwaysFail) throw StateError('Profile unavailable');
    final schoolLinked = role != AppRole.independentStudent;
    return StudentProfileView(
      userId: userId,
      displayName: displayName,
      role: role,
      schoolName: schoolLinked ? 'Alpha Academy' : null,
      className: schoolLinked ? 'Grade 5B' : null,
      email: 'learner@example.dev',
      guardianContact: 'guardian@example.dev',
      attendanceLabel: '94% this term',
      latestMarkLabel: 'Fractions quiz 8/10',
      xp: progress.xp,
      streakDays: progress.streak,
      completedTopics: progress.topics,
      recommendedNext: 'Fractions: equal parts',
      achievements: [
        ProfileAchievement(
          id: 'a1',
          title: 'First quiz cleared',
          earnedAt: DateTime.utc(2026, 7, 20),
        ),
        ProfileAchievement(
          id: 'a2',
          title: '7 day streak',
          earnedAt: DateTime.utc(2026, 7, 30),
        ),
      ],
    );
  }

  @override
  Future<PrivacySettings> loadPrivacy(String userId) async {
    if (alwaysFail) throw StateError('Privacy unavailable');
    return _privacy ??= PrivacySettings(userId: userId);
  }

  @override
  Future<PrivacySettings> savePrivacy(PrivacySettings settings) async {
    privacyWrites.add(settings);
    _privacy = settings;
    return settings;
  }

  @override
  Future<List<DeviceSession>> loadSessions(String userId) async {
    if (alwaysFail) throw StateError('Sessions unavailable');
    return List.unmodifiable(_sessions);
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    if (revokeFails) throw StateError('Revoke rejected');
    final index = _sessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) {
      throw StateError('session not found or not yours');
    }
    final session = _sessions[index];
    if (!session.isRevocable) {
      throw StateError('session not revocable');
    }
    _sessions[index] = session.copyWith(revokedAt: DateTime.now().toUtc());
    revokedSessionIds.add(sessionId);
  }
}

class SupabaseStudentProfileRepository implements StudentProfileRepository {
  SupabaseStudentProfileRepository(this._client, {this.currentSessionId});

  final SupabaseClient _client;

  /// Marked in the list so the learner can tell which device is this one.
  final String? currentSessionId;

  @override
  Future<StudentProfileView> loadProfile({
    required String userId,
    required String displayName,
    required AppRole role,
  }) async {
    final row = await _client
        .from('profiles')
        .select('id, display_name, account_kind, status')
        .eq('id', userId)
        .maybeSingle();
    final prefs = await _client
        .from('student_preferences')
        .select('companion_name, locale')
        .eq('user_id', userId)
        .maybeSingle();
    final name = (row?['display_name'] as String?) ?? displayName;
    return StudentProfileView(
      userId: userId,
      displayName: name.isEmpty ? displayName : name,
      role: role,
      companionName: (prefs?['companion_name'] as String?) ??
          CompanionNamePolicy.defaultName,
      locale: (prefs?['locale'] as String?) == 'ur'
          ? NanoAppLocale.ur
          : NanoAppLocale.en,
    );
  }

  @override
  Future<PrivacySettings> loadPrivacy(String userId) async {
    final row = await _client
        .from('privacy_settings')
        .select('user_id, discoverable, show_achievements, allow_friend_requests')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return PrivacySettings(userId: userId);
    return PrivacySettings.fromRow(row);
  }

  @override
  Future<PrivacySettings> savePrivacy(PrivacySettings settings) async {
    final row = await _client
        .from('privacy_settings')
        .upsert(settings.toRow(), onConflict: 'user_id')
        .select('user_id, discoverable, show_achievements, allow_friend_requests')
        .single();
    return PrivacySettings.fromRow(row);
  }

  @override
  Future<List<DeviceSession>> loadSessions(String userId) async {
    final rows = await _client
        .from('device_sessions')
        .select('id, user_id, school_id, device_label, user_agent, last_seen_at, revoked_at')
        .eq('user_id', userId)
        .order('last_seen_at', ascending: false);
    return [
      for (final row in rows as List<dynamic>)
        DeviceSession.fromRow(row as Map<String, dynamic>).copyWith(
          isCurrent: row['id'] == currentSessionId,
        ),
    ];
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    // Server-side function: device_sessions has no client write policy.
    await _client.rpc<void>(
      'revoke_device_session',
      params: {'p_session_id': sessionId},
    );
  }
}
