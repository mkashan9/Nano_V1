import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('loadCurrentCard returns the seeded weekly tip', () async {
    final repo = FakeParentGuidanceRepository();
    final card = await repo.loadCurrentCard();
    expect(card?.title, 'Keep the streak gentle');
    expect(card?.activityTips, isNotEmpty);
  });

  test('guardian can load only a linked child card', () async {
    final repo = FakeParentGuidanceRepository();
    final card = await repo.loadCardForGuardian(
      guardianId: 'guardian-1',
      childUserId: 'child-1',
    );
    expect(card.childDisplayName, 'Ali');

    expect(
      () => repo.loadCardForGuardian(
        guardianId: 'guardian-1',
        childUserId: 'stranger',
      ),
      throwsStateError,
    );
  });

  test('loadLinks returns only that guardian children', () async {
    final repo = FakeParentGuidanceRepository();
    final links = await repo.loadLinks(guardianId: 'guardian-1');
    expect(links, hasLength(1));
    expect(await repo.loadLinks(guardianId: 'nobody'), isEmpty);
  });
}
