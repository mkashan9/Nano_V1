import '../home/student_home_summary.dart';

/// FLX-01 Flex hub read model for school-linked students.
enum FlexHubSectionKind {
  attendance,
  marks,
  classroom;

  String get wire => name;
}

class FlexHubSection {
  const FlexHubSection({
    required this.kind,
    required this.openCount,
    this.nextDueLabel,
  });

  final FlexHubSectionKind kind;
  final int openCount;
  final String? nextDueLabel;

  bool get hasWork => openCount > 0;
}

class FlexHubSummary {
  const FlexHubSummary({
    required this.sections,
    required this.updatedAt,
    this.fromCache = false,
  });

  final List<FlexHubSection> sections;
  final DateTime updatedAt;
  final bool fromCache;

  int get openTasks =>
      sections.fold<int>(0, (sum, s) => sum + s.openCount);

  FlexHubSection? section(FlexHubSectionKind kind) {
    for (final s in sections) {
      if (s.kind == kind) return s;
    }
    return null;
  }

  FlexSummary toHomeFlexSummary() {
    String? due;
    for (final s in sections) {
      final label = s.nextDueLabel;
      if (label != null && label.isNotEmpty) {
        due = label;
        break;
      }
    }
    return FlexSummary(openTasks: openTasks, nextDueLabel: due);
  }
}
