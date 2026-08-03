import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// COM-01 discovery: my list, public discover/search, detail (read-only).
abstract class CommunityDiscoveryRepository {
  Future<List<CommunitySummary>> myCommunities();

  Future<List<CommunitySummary>> discoverPublic({String? query});

  Future<CommunityDetail> getDetail(String communityId);
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
        };

  final List<CommunitySummary> _mine;
  final List<CommunitySummary> _discoverable;
  final Map<String, CommunityDetail> _details;
  var alwaysFail = false;

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

  List<CommunitySummary> _list(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        CommunitySummary.fromJson(Map<String, dynamic>.from(row)),
    ];
  }
}
