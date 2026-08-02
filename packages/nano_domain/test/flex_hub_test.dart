import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('flex hub aggregates open tasks for home card', () {
    final hub = FlexHubSummary(
      updatedAt: DateTime.utc(2026, 8, 2),
      sections: const [
        FlexHubSection(kind: FlexHubSectionKind.attendance, openCount: 1),
        FlexHubSection(
          kind: FlexHubSectionKind.marks,
          openCount: 2,
          nextDueLabel: 'Due Friday',
        ),
        FlexHubSection(kind: FlexHubSectionKind.classroom, openCount: 0),
      ],
    );
    expect(hub.openTasks, 3);
    expect(hub.section(FlexHubSectionKind.marks)?.hasWork, isTrue);
    final home = hub.toHomeFlexSummary();
    expect(home.openTasks, 3);
    expect(home.nextDueLabel, 'Due Friday');
  });
}
