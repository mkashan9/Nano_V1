import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// COM-01/02 communities: discovery + create + role management.
abstract class CommunityDiscoveryRepository {
  Future<List<CommunitySummary>> myCommunities();

  Future<List<CommunitySummary>> discoverPublic({String? query});

  Future<CommunityDetail> getDetail(String communityId);

  Future<CommunityDetail> createCommunity({
    required String name,
    String summary = '',
    String rulesText = '',
    CommunityVisibility visibility = CommunityVisibility.public,
  });

  Future<List<CommunityMember>> listMembers(String communityId);

  Future<List<CommunityMember>> setMemberRole({
    required String communityId,
    required String userId,
    required String role,
  });
}

class FakeCommunityDiscoveryRepository implements CommunityDiscoveryRepository {
  FakeCommunityDiscoveryRepository({
    List<CommunitySummary>? mine,
    List<CommunitySummary>? discoverable,
    Map<String, CommunityDetail>? details,
  })  : _mine = List.of(
          mine ??
              const [
                CommunitySummary(
                  id: 'a1000000-0000-4000-8000-000000000001',
                  slug: 'study-circle',
                  name: 'Study Circle',
                  summary: 'Share tips, ask questions, and cheer each other on.',
                  memberCount: 12,
                  myRole: 'member',
                  myStatus: CommunityMembershipStatus.active,
                ),
              ],
        ),
        _discoverable = List.of(
          discoverable ??
              const [
                CommunitySummary(
                  id: 'a1000000-0000-4000-8000-000000000002',
                  slug: 'science-lab',
                  name: 'Science Lab',
                  summary: 'Experiments, curiosity, and cool science finds.',
                  memberCount: 8,
                ),
                CommunitySummary(
                  id: 'a1000000-0000-4000-8000-000000000003',
                  slug: 'book-nook',
                  name: 'Book Nook',
                  summary: 'What are you reading? Recommend stories to friends.',
                  memberCount: 5,
                ),
              ],
        ),
        _details = {
          'a1000000-0000-4000-8000-000000000001': const CommunityDetail(
            id: 'a1000000-0000-4000-8000-000000000001',
            slug: 'study-circle',
            name: 'Study Circle',
            summary: 'Share tips, ask questions, and cheer each other on.',
            rulesText:
                'Be kind. No spoilers for quizzes. Report harmful posts.',
            memberCount: 12,
            myRole: 'member',
            myStatus: CommunityMembershipStatus.active,
          ),
          'a1000000-0000-4000-8000-000000000002': const CommunityDetail(
            id: 'a1000000-0000-4000-8000-000000000002',
            slug: 'science-lab',
            name: 'Science Lab',
            summary: 'Experiments, curiosity, and cool science finds.',
            rulesText: 'Stay curious. Credit sources. Keep it respectful.',
            memberCount: 8,
          ),
          'a1000000-0000-4000-8000-000000000003': const CommunityDetail(
            id: 'a1000000-0000-4000-8000-000000000003',
            slug: 'book-nook',
            name: 'Book Nook',
            summary: 'What are you reading? Recommend stories to friends.',
            rulesText: 'No hate speech. Spoiler-tag big plot twists.',
            memberCount: 5,
          ),
          ...?details,
        },
        _members = {
          'a1000000-0000-4000-8000-000000000001': [
            const CommunityMember(
              userId: 'self',
              displayName: 'You',
              role: 'member',
              isSelf: true,
            ),
            const CommunityMember(
              userId: 'u-owner',
              displayName: 'Ayesha',
              role: 'owner',
            ),
          ],
        };

  final List<CommunitySummary> _mine;
  final List<CommunitySummary> _discoverable;
  final Map<String, CommunityDetail> _details;
  final Map<String, List<CommunityMember>> _members;
  var alwaysFail = false;
  var _createSeq = 0;

  @override
  Future<List<CommunitySummary>> myCommunities() async {
    if (alwaysFail) throw StateError('Communities unavailable');
    return List.unmodifiable(_mine);
  }

  @override
  Future<List<CommunitySummary>> discoverPublic({String? query}) async {
    if (alwaysFail) throw StateError('Discover unavailable');
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isEmpty) return List.unmodifiable(_discoverable);
    return [
      for (final item in _discoverable)
        if (item.name.toLowerCase().contains(q) ||
            item.slug.toLowerCase().contains(q) ||
            item.summary.toLowerCase().contains(q))
          item,
    ];
  }

  @override
  Future<CommunityDetail> getDetail(String communityId) async {
    if (alwaysFail) throw StateError('Community unavailable');
    final detail = _details[communityId];
    if (detail == null) throw StateError('Community not found');
    return detail;
  }

  @override
  Future<CommunityDetail> createCommunity({
    required String name,
    String summary = '',
    String rulesText = '',
    CommunityVisibility visibility = CommunityVisibility.public,
  }) async {
    if (alwaysFail) throw StateError('Create failed');
    final trimmed = name.trim();
    if (trimmed.length < 3) {
      throw StateError('Name must be at least 3 characters.');
    }
    _createSeq += 1;
    final id = 'created-$_createSeq';
    final slug = trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final detail = CommunityDetail(
      id: id,
      slug: slug,
      name: trimmed,
      summary: summary.trim(),
      rulesText: rulesText.trim(),
      visibility: visibility,
      memberCount: 1,
      myRole: 'owner',
      myStatus: CommunityMembershipStatus.active,
    );
    _details[id] = detail;
    _mine.insert(0, detail.asSummary);
    _members[id] = [
      const CommunityMember(
        userId: 'self',
        displayName: 'You',
        role: 'owner',
        isSelf: true,
      ),
    ];
    return detail;
  }

  @override
  Future<List<CommunityMember>> listMembers(String communityId) async {
    if (alwaysFail) throw StateError('Members unavailable');
    return List.unmodifiable(_members[communityId] ?? const []);
  }

  @override
  Future<List<CommunityMember>> setMemberRole({
    required String communityId,
    required String userId,
    required String role,
  }) async {
    if (alwaysFail) throw StateError('Role update failed');
    final current = _members[communityId] ?? const <CommunityMember>[];
    _members[communityId] = [
      for (final m in current)
        if (m.userId == userId)
          CommunityMember(
            userId: m.userId,
            displayName: m.displayName,
            role: role,
            status: m.status,
            joinedAt: m.joinedAt,
            isSelf: m.isSelf,
          )
        else
          m,
    ];
    return listMembers(communityId);
  }
}

class SupabaseCommunityDiscoveryRepository
    implements CommunityDiscoveryRepository {
  SupabaseCommunityDiscoveryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CommunitySummary>> myCommunities() async {
    final raw = await _client.rpc('my_communities');
    return _list(raw);
  }

  @override
  Future<List<CommunitySummary>> discoverPublic({String? query}) async {
    final raw = await _client.rpc(
      'discover_public_communities',
      params: {'p_query': query},
    );
    return _list(raw);
  }

  @override
  Future<CommunityDetail> getDetail(String communityId) async {
    final raw = await _client.rpc(
      'get_community_detail',
      params: {'p_community_id': communityId},
    );
    if (raw is! Map) throw StateError('Community unavailable');
    return CommunityDetail.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<CommunityDetail> createCommunity({
    required String name,
    String summary = '',
    String rulesText = '',
    CommunityVisibility visibility = CommunityVisibility.public,
  }) async {
    final raw = await _client.rpc(
      'create_community',
      params: {
        'p_name': name,
        'p_summary': summary,
        'p_rules_text': rulesText,
        'p_visibility': visibility.wire,
      },
    );
    if (raw is! Map) throw StateError('Create failed');
    return CommunityDetail.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<CommunityMember>> listMembers(String communityId) async {
    final raw = await _client.rpc(
      'list_community_members',
      params: {'p_community_id': communityId},
    );
    return _members(raw);
  }

  @override
  Future<List<CommunityMember>> setMemberRole({
    required String communityId,
    required String userId,
    required String role,
  }) async {
    final raw = await _client.rpc(
      'set_community_member_role',
      params: {
        'p_community_id': communityId,
        'p_user_id': userId,
        'p_role': role,
      },
    );
    return _members(raw);
  }

  List<CommunitySummary> _list(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        CommunitySummary.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  List<CommunityMember> _members(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        CommunityMember.fromJson(Map<String, dynamic>.from(row)),
    ];
  }
}
