import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SOC-01 username / friend code / limited profile lookups.
abstract class SocialIdentityRepository {
  Future<SocialIdentity> loadMine();

  Future<SocialIdentity> claimUsername(String username);

  Future<SocialIdentity> rotateFriendCode();

  Future<LimitedProfile> lookup(String query);
}

class FakeSocialIdentityRepository implements SocialIdentityRepository {
  FakeSocialIdentityRepository({
    SocialIdentity? mine,
    Map<String, LimitedProfile>? directory,
    this.alwaysFail = false,
  })  : _mine = mine ??
            const SocialIdentity(
              username: null,
              friendCode: 'AB12CD34',
            ),
        _directory = {
          ...?directory,
          'sara': const LimitedProfile(
            socialLabel: 'sara',
            username: 'sara',
            level: 2,
            companionName: 'Nori',
            acceptsFriendRequests: true,
            achievementTitles: ['First quiz'],
          ),
          'XY98ZT76': const LimitedProfile(
            socialLabel: 'sara',
            username: 'sara',
            level: 2,
            companionName: 'Nori',
          ),
        };

  final bool alwaysFail;
  SocialIdentity _mine;
  final Map<String, LimitedProfile> _directory;
  final claimedUsernames = <String>[];
  var rotateCount = 0;

  @override
  Future<SocialIdentity> loadMine() async {
    if (alwaysFail) throw StateError('Social identity unavailable');
    return _mine;
  }

  @override
  Future<SocialIdentity> claimUsername(String username) async {
    if (alwaysFail) throw StateError('Could not claim username');
    final error = UsernamePolicy.validate(username);
    if (error != null) throw ArgumentError(error);
    final clean = UsernamePolicy.normalize(username);
    if (_directory.containsKey(clean) && _mine.username != clean) {
      throw StateError('Username is already taken.');
    }
    claimedUsernames.add(clean);
    _mine = SocialIdentity(
      username: clean,
      friendCode: _mine.friendCode,
      friendCodeRotatedAt: _mine.friendCodeRotatedAt,
    );
    return _mine;
  }

  @override
  Future<SocialIdentity> rotateFriendCode() async {
    if (alwaysFail) throw StateError('Could not rotate friend code');
    rotateCount += 1;
    final next = 'ZZ${rotateCount.toString().padLeft(6, '0')}';
    _mine = SocialIdentity(
      username: _mine.username,
      friendCode: next.substring(0, 8),
      friendCodeRotatedAt: DateTime.utc(2026, 8, 2),
    );
    return _mine;
  }

  @override
  Future<LimitedProfile> lookup(String query) async {
    if (alwaysFail) throw StateError('Lookup failed');
    final key = query.trim();
    final byLower = _directory[key.toLowerCase()];
    if (byLower != null) return byLower;
    final byCode = _directory[key.toUpperCase()];
    if (byCode != null) return byCode;
    throw StateError('No discoverable profile found.');
  }
}

class SupabaseSocialIdentityRepository implements SocialIdentityRepository {
  SupabaseSocialIdentityRepository(this._client);

  final SupabaseClient _client;

  SocialIdentity _parseIdentity(dynamic raw) {
    if (raw is! Map) throw StateError('Social identity missing.');
    return SocialIdentity.fromJson(Map<String, dynamic>.from(raw));
  }

  LimitedProfile _parseLimited(dynamic raw) {
    if (raw is! Map) throw StateError('Limited profile missing.');
    return LimitedProfile.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<SocialIdentity> loadMine() async {
    final raw = await _client.rpc('my_social_identity');
    return _parseIdentity(raw);
  }

  @override
  Future<SocialIdentity> claimUsername(String username) async {
    final raw = await _client.rpc(
      'claim_username',
      params: {'p_username': username},
    );
    return _parseIdentity(raw);
  }

  @override
  Future<SocialIdentity> rotateFriendCode() async {
    final raw = await _client.rpc('rotate_friend_code');
    return _parseIdentity(raw);
  }

  @override
  Future<LimitedProfile> lookup(String query) async {
    final raw = await _client.rpc(
      'lookup_limited_profile',
      params: {'p_query': query},
    );
    return _parseLimited(raw);
  }
}
