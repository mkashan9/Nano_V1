import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('ParentGuidanceSafety rejects forbidden fields', () {
    expect(
      ParentGuidanceSafety.mapLooksSafe({
        'title': 'Tip',
        'body': 'Read together',
      }),
      isTrue,
    );
    expect(
      ParentGuidanceSafety.mapLooksSafe({
        'title': 'Tip',
        'draft_marks': 88,
      }),
      isFalse,
    );
  });

  test('GuardianAccessPolicy only allows linked children', () {
    const links = [
      GuardianChildLink(
        guardianId: 'g1',
        childUserId: 'c1',
        childDisplayName: 'Ali',
      ),
    ];
    expect(
      GuardianAccessPolicy.canViewChild(
        guardianId: 'g1',
        childUserId: 'c1',
        links: links,
      ),
      isTrue,
    );
    expect(
      GuardianAccessPolicy.canViewChild(
        guardianId: 'g1',
        childUserId: 'c2',
        links: links,
      ),
      isFalse,
    );
    expect(GuardianAccessPolicy.childrenFor('g1', links), hasLength(1));
    expect(GuardianAccessPolicy.childrenFor('g2', links), isEmpty);
  });
}
