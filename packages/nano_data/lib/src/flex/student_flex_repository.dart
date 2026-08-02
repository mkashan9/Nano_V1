import 'package:nano_domain/nano_domain.dart';

/// FLX-01 Flex hub for school-linked students.
abstract class StudentFlexRepository {
  Future<FlexHubSummary> loadHub({required bool flexEligible});
}

class FakeStudentFlexRepository implements StudentFlexRepository {
  FakeStudentFlexRepository({
    FlexHubSummary? seed,
    this.alwaysFail = false,
  }) : _seed = seed;

  FlexHubSummary? _seed;
  var alwaysFail;

  @override
  Future<FlexHubSummary> loadHub({required bool flexEligible}) async {
    if (alwaysFail) throw StateError('Flex unavailable');
    if (!flexEligible) {
      throw StateError('Flex is not available for this account.');
    }
    return _seed ??
        FlexHubSummary(
          updatedAt: DateTime.utc(2026, 8, 2, 7),
          sections: const [
            FlexHubSection(
              kind: FlexHubSectionKind.attendance,
              openCount: 1,
              nextDueLabel: 'Today',
            ),
            FlexHubSection(
              kind: FlexHubSectionKind.marks,
              openCount: 1,
              nextDueLabel: 'Due Friday',
            ),
            FlexHubSection(
              kind: FlexHubSectionKind.classroom,
              openCount: 1,
              nextDueLabel: 'New announcement',
            ),
          ],
        );
  }
}
