import 'package:test/test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('SafetyReport.fromJson maps under_review and omits user ids', () {
    final report = SafetyReport.fromJson({
      'id': 'r1',
      'category': 'harassment',
      'status': 'under_review',
      'peer_label': 'sara',
      'username': 'sara',
      'also_blocked': true,
      'created_at': '2026-08-02T00:00:00Z',
    });

    expect(report.status, ReportStatus.underReview);
    expect(report.category, ReportCategory.harassment);
    expect(report.alsoBlocked, isTrue);
    expect(report.toString(), isNot(contains('user_id')));
  });

  test('ReportDraft wires category name', () {
    const draft = ReportDraft(
      category: ReportCategory.impersonation,
      alsoBlock: false,
    );
    expect(draft.categoryWire, 'impersonation');
  });
}
