import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SAFE-04 platform + school community feature switches.
abstract class CommunityControlsRepository {
  Future<PlatformCommunityPolicy> loadPlatformPolicy();

  Future<PlatformCommunityPolicy> savePlatformPolicy({required bool enabled});

  Future<SchoolCommunityPolicy> loadSchoolPolicy(String schoolId);

  Future<SchoolCommunityPolicy> saveSchoolPolicy({
    required String schoolId,
    required bool enabled,
  });

  Future<List<SchoolCommunityPolicy>> listSchoolPolicies();

  Future<CommunityEntitlements> myEntitlements();
}

class FakeCommunityControlsRepository implements CommunityControlsRepository {
  FakeCommunityControlsRepository({
    bool platformEnabled = false,
    Map<String, bool>? schoolEnabled,
  })  : _platformEnabled = platformEnabled,
        _schoolEnabled = {
          TenancyFixtures.alphaSchoolId: false,
          ...?schoolEnabled,
        };

  bool _platformEnabled;
  final Map<String, bool> _schoolEnabled;
  var alwaysFail = false;

  @override
  Future<PlatformCommunityPolicy> loadPlatformPolicy() async {
    if (alwaysFail) throw StateError('Platform community policy unavailable');
    return PlatformCommunityPolicy(communitiesEnabled: _platformEnabled);
  }

  @override
  Future<PlatformCommunityPolicy> savePlatformPolicy({
    required bool enabled,
  }) async {
    if (alwaysFail) throw StateError('Save platform policy failed');
    _platformEnabled = enabled;
    return PlatformCommunityPolicy(communitiesEnabled: _platformEnabled);
  }

  @override
  Future<SchoolCommunityPolicy> loadSchoolPolicy(String schoolId) async {
    if (alwaysFail) throw StateError('School community policy unavailable');
    return SchoolCommunityPolicy(
      schoolId: schoolId,
      communitiesEnabled: _schoolEnabled[schoolId] ?? false,
    );
  }

  @override
  Future<SchoolCommunityPolicy> saveSchoolPolicy({
    required String schoolId,
    required bool enabled,
  }) async {
    if (alwaysFail) throw StateError('Save school policy failed');
    _schoolEnabled[schoolId] = enabled;
    return SchoolCommunityPolicy(
      schoolId: schoolId,
      communitiesEnabled: enabled,
    );
  }

  @override
  Future<List<SchoolCommunityPolicy>> listSchoolPolicies() async {
    if (alwaysFail) throw StateError('List school policies failed');
    return [
      for (final entry in _schoolEnabled.entries)
        SchoolCommunityPolicy(
          schoolId: entry.key,
          schoolName: entry.key == TenancyFixtures.alphaSchoolId
              ? 'Alpha School'
              : entry.key,
          communitiesEnabled: entry.value,
        ),
    ];
  }

  @override
  Future<CommunityEntitlements> myEntitlements() async {
    if (alwaysFail) throw StateError('Entitlements unavailable');
    return CommunityEntitlements(
      communitiesEnabled: _platformEnabled,
      platformEnabled: _platformEnabled,
      schoolEnabled: _schoolEnabled[TenancyFixtures.alphaSchoolId],
      juniorBlocked: false,
      reason: _platformEnabled ? 'ok' : 'platform_disabled',
    );
  }
}

class SupabaseCommunityControlsRepository
    implements CommunityControlsRepository {
  SupabaseCommunityControlsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PlatformCommunityPolicy> loadPlatformPolicy() async {
    final raw = await _client.rpc('get_platform_community_policy');
    return PlatformCommunityPolicy.fromJson(_asMap(raw));
  }

  @override
  Future<PlatformCommunityPolicy> savePlatformPolicy({
    required bool enabled,
  }) async {
    final raw = await _client.rpc(
      'upsert_platform_community_policy',
      params: {'p_enabled': enabled},
    );
    return PlatformCommunityPolicy.fromJson(_asMap(raw));
  }

  @override
  Future<SchoolCommunityPolicy> loadSchoolPolicy(String schoolId) async {
    final raw = await _client.rpc(
      'get_school_community_policy',
      params: {'p_school_id': schoolId},
    );
    return SchoolCommunityPolicy.fromJson(_asMap(raw));
  }

  @override
  Future<SchoolCommunityPolicy> saveSchoolPolicy({
    required String schoolId,
    required bool enabled,
  }) async {
    final raw = await _client.rpc(
      'upsert_school_community_policy',
      params: {
        'p_school_id': schoolId,
        'p_enabled': enabled,
      },
    );
    return SchoolCommunityPolicy.fromJson(_asMap(raw));
  }

  @override
  Future<List<SchoolCommunityPolicy>> listSchoolPolicies() async {
    final raw = await _client.rpc('list_school_community_policies');
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        SchoolCommunityPolicy.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<CommunityEntitlements> myEntitlements() async {
    final raw = await _client.rpc('my_community_entitlements');
    return CommunityEntitlements.fromJson(_asMap(raw));
  }

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('Unexpected community policy response');
  }
}
