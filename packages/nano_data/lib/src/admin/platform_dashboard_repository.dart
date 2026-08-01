import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// ADM-01 read model for the superadmin Platform home.
abstract class PlatformDashboardRepository {
  Future<PlatformDashboard> load({String query = ''});
}

class FakePlatformDashboardRepository implements PlatformDashboardRepository {
  FakePlatformDashboardRepository({PlatformDashboard? seed})
      : _seed = seed ??
            PlatformDashboard(
              schoolCount: 2,
              activeSchoolCount: 2,
              learnerCount: 48,
              staffCount: 6,
              suspendedProfileCount: 1,
              openIncidentCount: 0,
              schools: const [
                SchoolDirectoryEntry(
                  id: 's-alpha',
                  code: 'ALPHA',
                  name: 'Alpha Academy',
                  status: 'active',
                  learnerCount: 30,
                  staffCount: 4,
                ),
                SchoolDirectoryEntry(
                  id: 's-beta',
                  code: 'BETA',
                  name: 'Beta School',
                  status: 'active',
                  learnerCount: 18,
                  staffCount: 2,
                ),
              ],
              recentAudit: [
                AuditPreviewEntry(
                  action: 'other',
                  targetType: 'generated_asset',
                  createdAt: DateTime.utc(2026, 8, 1, 12),
                  schoolCode: null,
                ),
              ],
            );

  final PlatformDashboard _seed;
  var alwaysFail = false;

  @override
  Future<PlatformDashboard> load({String query = ''}) async {
    if (alwaysFail) throw StateError('Platform dashboard unavailable');
    final filtered = [
      for (final school in _seed.schools)
        if (school.matchesQuery(query)) school,
    ];
    return PlatformDashboard(
      schoolCount: _seed.schoolCount,
      activeSchoolCount: _seed.activeSchoolCount,
      learnerCount: _seed.learnerCount,
      staffCount: _seed.staffCount,
      suspendedProfileCount: _seed.suspendedProfileCount,
      openIncidentCount: _seed.openIncidentCount,
      schools: filtered,
      recentAudit: _seed.recentAudit,
    );
  }
}

class SupabasePlatformDashboardRepository
    implements PlatformDashboardRepository {
  SupabasePlatformDashboardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PlatformDashboard> load({String query = ''}) async {
    final raw = await _client.rpc(
      'platform_dashboard',
      params: {'p_query': query},
    );
    if (raw is! Map) {
      throw StateError('Platform dashboard unavailable.');
    }
    final map = Map<String, dynamic>.from(raw);
    if (!PlatformDashboard.isPrivacySafePayload(map)) {
      throw StateError('Platform dashboard failed privacy review.');
    }
    return PlatformDashboard.fromJson(map);
  }
}
