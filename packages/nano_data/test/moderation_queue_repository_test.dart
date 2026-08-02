import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake claim and resolve close the report', () async {
    final repo = FakeModerationQueueRepository();
    final open = await repo.queue();
    expect(open, isNotEmpty);

    final claimed = await repo.claim(open.first.id);
    expect(claimed.status, ReportStatus.underReview);

    final closed = await repo.resolve(
      claimed.id,
      ModerationResolution.warn,
      note: 'Warned via chat policy',
    );
    expect(closed.status, ReportStatus.resolved);
    expect(closed.resolutionAction, ModerationResolution.warn);
  });

  test('fake refuses non-admin', () async {
    final repo = FakeModerationQueueRepository(alwaysFail: true);
    expect(
      () => repo.queue(),
      throwsA(isA<ModerationQueueRefused>()),
    );
  });
}
