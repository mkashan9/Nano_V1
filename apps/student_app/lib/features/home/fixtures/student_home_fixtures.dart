import 'package:nano_domain/nano_domain.dart';

/// Deterministic fixtures shared by Junior and Senior presentations.
abstract final class StudentHomeFixtures {
  static const studentName = 'Ali';
  static const xp = 560;
  static const streak = 7;

  static const continueTitle = 'Animals Adventure';
  static const continueProgress = 0.42;

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
    LearningSubject(
      id: 'science',
      title: 'Science',
      progress: 0.65,
      worldColorValue: 0xFFFF8A3D,
      tag: 'Science',
      estimatedMinutes: 45,
      shortPrompt: 'Mix & learn',
    ),
    LearningSubject(
      id: 'stories',
      title: 'Stories',
      progress: 0.20,
      worldColorValue: 0xFFFF4F9A,
      tag: 'Stories',
      estimatedMinutes: 20,
      shortPrompt: 'Read along',
    ),
  ];

  static const missions = <HomePlanItem>[
    HomePlanItem(
      id: 'm1',
      title: 'Complete a lesson',
      subtitle: 'Learn',
      xpReward: 40,
    ),
    HomePlanItem(
      id: 'm2',
      title: 'Play one game',
      subtitle: 'Games',
      xpReward: 30,
    ),
    HomePlanItem(
      id: 'm3',
      title: 'Practice quiz',
      subtitle: 'Quiz',
      xpReward: 50,
    ),
  ];
}
