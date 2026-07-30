import 'package:nano_domain/nano_domain.dart';

/// Re-export friendly fixtures for package tests (same data as student app).
abstract final class StudentHomeFixtures {
  static const studentName = 'Ali';
  static const xp = 560;
  static const subjects = <LearningSubject>[
    LearningSubject(
      id: 'math',
      title: 'Math',
      progress: 0.55,
      worldColorValue: 0xFF2F7BFF,
      tag: 'Math',
      estimatedMinutes: 25,
      shortPrompt: 'Play numbers',
    ),
    LearningSubject(
      id: 'english',
      title: 'English',
      progress: 0.30,
      worldColorValue: 0xFF2FBF71,
      tag: 'English',
      estimatedMinutes: 30,
      shortPrompt: 'ABC time',
    ),
  ];
}
