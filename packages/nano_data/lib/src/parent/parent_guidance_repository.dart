import 'package:nano_domain/nano_domain.dart';

/// PAR-01 weekly parent guidance cards (PDF upload is PAR-02).
abstract class ParentGuidanceRepository {
  Future<ParentGuidanceCard?> loadCurrentCard({String? childUserId});

  Future<ParentGuidanceCard> loadCardForGuardian({
    required String guardianId,
    required String childUserId,
  });

  Future<List<GuardianChildLink>> loadLinks({required String guardianId});
}

class FakeParentGuidanceRepository implements ParentGuidanceRepository {
  FakeParentGuidanceRepository({
    ParentGuidanceCard? card,
    List<GuardianChildLink>? links,
    this.alwaysFail = false,
  })  : _card = card ??
            ParentGuidanceCard(
              id: 'week-2026-31',
              weekKey: '2026-W31',
              title: 'Keep the streak gentle',
              body:
                  'Celebrate short daily learning. Ask what felt easy and what felt hard — no scores needed.',
              publishedAt: DateTime.utc(2026, 8, 1),
              activityTips: const [
                'Ten quiet minutes of reading together',
                'Let them teach you one new word',
              ],
              childDisplayName: 'Ali',
            ),
        _links = List.of(
          links ??
              const [
                GuardianChildLink(
                  guardianId: 'guardian-1',
                  childUserId: 'child-1',
                  childDisplayName: 'Ali',
                ),
              ],
        );

  ParentGuidanceCard _card;
  final List<GuardianChildLink> _links;
  bool alwaysFail;

  void seedCard(ParentGuidanceCard next) => _card = next;

  @override
  Future<ParentGuidanceCard?> loadCurrentCard({String? childUserId}) async {
    if (alwaysFail) throw StateError('Guidance unavailable');
    if (childUserId == null) return _card;
    return ParentGuidanceCard(
      id: _card.id,
      weekKey: _card.weekKey,
      title: _card.title,
      body: _card.body,
      publishedAt: _card.publishedAt,
      activityTips: _card.activityTips,
      childDisplayName: _card.childDisplayName,
    );
  }

  @override
  Future<ParentGuidanceCard> loadCardForGuardian({
    required String guardianId,
    required String childUserId,
  }) async {
    if (alwaysFail) throw StateError('Guidance unavailable');
    if (!GuardianAccessPolicy.canViewChild(
      guardianId: guardianId,
      childUserId: childUserId,
      links: _links,
    )) {
      throw StateError('Child not linked to this guardian');
    }
    final link = _links.firstWhere(
      (item) =>
          item.guardianId == guardianId && item.childUserId == childUserId,
    );
    return ParentGuidanceCard(
      id: _card.id,
      weekKey: _card.weekKey,
      title: _card.title,
      body: _card.body,
      publishedAt: _card.publishedAt,
      activityTips: _card.activityTips,
      childDisplayName: link.childDisplayName,
    );
  }

  @override
  Future<List<GuardianChildLink>> loadLinks({
    required String guardianId,
  }) async {
    if (alwaysFail) throw StateError('Links unavailable');
    return GuardianAccessPolicy.childrenFor(guardianId, _links);
  }
}
