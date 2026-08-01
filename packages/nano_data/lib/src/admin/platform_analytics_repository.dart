import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// ADM-08 read model for the superadmin Analytics hub.
abstract class PlatformAnalyticsRepository {
  Future<PlatformAnalytics> load();
}

class FakePlatformAnalyticsRepository implements PlatformAnalyticsRepository {
  FakePlatformAnalyticsRepository({PlatformAnalytics? seed})
      : _seed = seed ??
            PlatformAnalytics(
              activeSchoolCount: 2,
              suspendedSchoolCount: 0,
              activeLearnerCount: 48,
              independentLearnerCount: 3,
              publishedSubjectCount: 2,
              publishedTopicCount: 5,
              liveGameCount: 1,
              publishedNotificationCount: 3,
              topicCompletions7d: 12,
              xpAwards7d: 40,
              quizPasses7d: 8,
              auditEvents7d: 25,
              assetsAwaitingReview: 4,
              openIncidentCount: 0,
              actionBreakdown7d: const [
                AnalyticsActionCount(action: 'update', eventCount: 10),
                AnalyticsActionCount(action: 'create', eventCount: 8),
                AnalyticsActionCount(action: 'revoke', eventCount: 4),
              ],
              generatedAt: DateTime.utc(2026, 8, 2, 0),
            );

  final PlatformAnalytics _seed;
  var alwaysFail = false;

  @override
  Future<PlatformAnalytics> load() async {
    if (alwaysFail) throw StateError('Platform analytics unavailable');
    return _seed;
  }
}

class SupabasePlatformAnalyticsRepository
    implements PlatformAnalyticsRepository {
  SupabasePlatformAnalyticsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PlatformAnalytics> load() async {
    final raw = await _client.rpc('platform_analytics');
    if (raw is! Map) {
      throw StateError('Platform analytics unavailable.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (!PlatformDashboard.isPrivacySafePayload(map)) {
      throw StateError('Platform analytics failed privacy review.');
    }
    return PlatformAnalytics.fromJson(map);
  }
}
