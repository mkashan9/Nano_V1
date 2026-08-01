import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('GenerationBudget', () {
    test('reads the server row, including the "all kinds" shape', () {
      final budget = GenerationBudget.fromRow({
        'scope': 'platform',
        'scope_key': '',
        'kind': 'all',
        'max_requests_per_day': 200,
        'requests_used': 12,
        'max_cost_micros_per_day': 5000000,
        'cost_micros_used': 250000,
      });

      expect(budget.scope, GenerationQuotaScope.platform);
      expect(budget.kind, isNull, reason: '"all" is every kind together');
      expect(budget.requestsRemaining, 188);
      expect(budget.costMicrosRemaining, 4750000);
      expect(budget.isExhausted, isFalse);
      expect(budget.label, 'platform');
    });

    test('a per-kind budget keeps its kind and its feature label', () {
      final budget = GenerationBudget.fromRow({
        'scope': 'feature',
        'scope_key': 'companion',
        'kind': 'video',
        'max_requests_per_day': 20,
        'requests_used': 20,
        'max_cost_micros_per_day': 3000000,
        'cost_micros_used': 10,
      });

      expect(budget.kind, GeneratedAssetKind.video);
      expect(budget.label, 'companion');
      expect(budget.isExhausted, isTrue);
      expect(budget.requestsRemaining, 0);
    });

    test('either limit is enough to stop the next request', () {
      final costSpent = GenerationBudget.fromRow({
        'scope': 'platform',
        'scope_key': '',
        'kind': 'all',
        'max_requests_per_day': 200,
        'requests_used': 1,
        'max_cost_micros_per_day': 1000,
        'cost_micros_used': 1000,
      });

      expect(costSpent.isExhausted, isTrue);
      expect(costSpent.requestsRemaining, 199, reason: 'requests are not the reason');
    });

    test('an over-spent budget reports nothing left rather than a negative', () {
      final budget = GenerationBudget.fromRow({
        'scope': 'platform',
        'scope_key': '',
        'kind': 'all',
        'max_requests_per_day': 5,
        'requests_used': 9,
        'max_cost_micros_per_day': 100,
        'cost_micros_used': 400,
      });

      expect(budget.requestsRemaining, 0);
      expect(budget.costMicrosRemaining, 0);
    });
  });

  group('clips arriving late', () {
    test('learning that clips exist keeps the session history intact', () {
      final now = DateTime.utc(2026, 8, 1, 9);
      final runtime = CompanionRuntime.forExperience(junior: true)
          .notify(CompanionEvent.appOpen, now: now);

      final withClips = runtime.withClipsAvailable(true);

      expect(withClips.clipsAvailable, isTrue);
      expect(withClips.reaction, isNotNull, reason: 'the screen is not disturbed');
      expect(withClips.shownThisSession, runtime.shownThisSession);
      expect(withClips.lastShownAt, runtime.lastShownAt);
      expect(
        withClips.isSuppressed(CompanionEvent.appOpen, now),
        isTrue,
        reason: 'a cooldown in progress stays in progress',
      );
    });

    test('the same answer twice changes nothing', () {
      final runtime = CompanionRuntime.forExperience(junior: true);

      expect(runtime.withClipsAvailable(false), same(runtime));
    });
  });
}
