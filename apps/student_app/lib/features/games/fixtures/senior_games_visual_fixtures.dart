import 'package:flutter/material.dart';
import 'package:student_app/features/games/visual/senior_games_visual_assets.dart';

/// Visual fixtures matching `UI_reference/four_12/games.jpeg` (VIS-07).
abstract final class SeniorGamesVisualFixtures {
  static const lineOne = 'Play. Learn.';
  static const lineTwo = 'Build the future.';
  static const subtitle = 'Every game teaches a real skill.';

  static const games = <({
    String title,
    String category,
    int xp,
    int difficulty,
    Color accent,
    String? asset,
  })>[
    (
      title: 'Code Quest',
      category: 'Programming',
      xp: 120,
      difficulty: 3,
      accent: Color(0xFF2FBF71),
      asset: SeniorGamesVisualAssets.codeQuest,
    ),
    (
      title: 'Math Arena',
      category: 'Logic',
      xp: 100,
      difficulty: 3,
      accent: Color(0xFF3D8BFF),
      asset: SeniorGamesVisualAssets.mathArena,
    ),
    (
      title: 'Physics Lab',
      category: 'Science',
      xp: 110,
      difficulty: 4,
      accent: Color(0xFF2FBF71),
      asset: SeniorGamesVisualAssets.physicsLab,
    ),
    (
      title: 'Space Explorer',
      category: 'Discovery',
      xp: 130,
      difficulty: 3,
      accent: Color(0xFF9B6DFF),
      asset: SeniorGamesVisualAssets.spaceExplorer,
    ),
    (
      title: 'Logic Factory',
      category: 'Logic',
      xp: 90,
      difficulty: 4,
      accent: Color(0xFF3D8BFF),
      asset: null,
    ),
    (
      title: 'Business Empire',
      category: 'Business',
      xp: 140,
      difficulty: 3,
      accent: Color(0xFFFF8A3D),
      asset: null,
    ),
  ];

  static const challenges = <({
    String title,
    String body,
    String cta,
    Color accent,
    IconData icon,
  })>[
    (
      title: 'Daily Challenge',
      body: "Complete today's challenge and earn bonus XP!",
      cta: 'Start Challenge',
      accent: Color(0xFF2FBF71),
      icon: Icons.gps_fixed,
    ),
    (
      title: 'Weekly Tournament',
      body: 'Compete with builders worldwide this week!',
      cta: 'Join Tournament',
      accent: Color(0xFF9B6DFF),
      icon: Icons.emoji_events,
    ),
    (
      title: 'Boss Challenge',
      body: 'Take on the boss. Test your skills. Win big!',
      cta: 'Fight Boss',
      accent: Color(0xFFFF4D6D),
      icon: Icons.smart_toy,
    ),
  ];

  static const worlds = <({
    String label,
    Color accent,
    bool locked,
    bool completed,
    String? progress,
    IconData icon,
  })>[
    (
      label: 'Green Planet',
      accent: Color(0xFF2FBF71),
      locked: false,
      completed: true,
      progress: null,
      icon: Icons.forest,
    ),
    (
      label: 'Tech City',
      accent: Color(0xFF9B6DFF),
      locked: false,
      completed: false,
      progress: '60%',
      icon: Icons.location_city,
    ),
    (
      label: 'Deep Space',
      accent: Color(0xFF3D8BFF),
      locked: true,
      completed: false,
      progress: null,
      icon: Icons.public,
    ),
    (
      label: 'Future Lab',
      accent: Color(0xFFFF8A3D),
      locked: true,
      completed: false,
      progress: null,
      icon: Icons.science,
    ),
  ];

  static const achievements = <String>[
    'Code Master',
    'Problem Solver',
    'Science Explorer',
    'Creative Builder',
    'Entrepreneur',
  ];

  static const rewards = <({String title, String body, IconData icon})>[
    (title: 'Knowledge', body: 'Keep growing', icon: Icons.schedule),
    (title: 'Projects', body: 'Build real things', icon: Icons.work_outline),
    (title: 'Builder Badges', body: 'Show your skills', icon: Icons.hexagon_outlined),
    (title: 'Creativity Points', body: 'Turn ideas into impact', icon: Icons.auto_awesome),
  ];
}
