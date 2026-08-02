import 'package:test/test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('fake submitByQuery and listMine', () async {
    final repo = FakeSafetyReportRepository();
    final report = await repo.submitByQuery(
      'sara',
      const ReportDraft(
        category: ReportCategory.spam,
        details: 'ads',
        alsoBlock: true,
      ),
    );
    expect(report.peerLabel, 'sara');
    expect(report.alsoBlocked, isTrue);
    expect(repo.submittedQueries, ['sara']);
    expect(await repo.listMine(), hasLength(1));
  });

  test('fake submitForPeer records token', () async {
    final repo = FakeSafetyReportRepository();
    await repo.submitForPeer(
      'tok-1',
      const ReportDraft(category: ReportCategory.other),
    );
    expect(repo.submittedPeerTokens, ['tok-1']);
  });
}
