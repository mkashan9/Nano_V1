import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SAFE-04 platform emergency switch for open Communities (no school gate).
abstract class CommunityControlsRepository {
  Future<PlatformCommunityPolicy> loadPlatformPolicy();

  Future<PlatformCommunityPolicy> savePlatformPolicy({required bool enabled});

  Future<CommunityEntitlements> myEntitlements();
}

class FakeCommunityControlsRepository implements CommunityControlsRepository {
  FakeCommunityControlsRepository({bool platformEnabled = true})
      : _platformEnabled = platformEnabled;

  bool _platformEnabled;
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
  Future<CommunityEntitlements> myEntitlements() async {
    if (alwaysFail) throw StateError('Entitlements unavailable');
    return CommunityEntitlements(
      communitiesEnabled: _platformEnabled,
      platformEnabled: _platformEnabled,
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
  Future<CommunityEntitlements> myEntitlements() async {
    final raw = await _client.rpc('my_community_entitlements');
    return CommunityEntitlements.fromJson(_asMap(raw));
  }

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('Unexpected community policy response');
  }
}
