import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';

/// Visual fixtures matching `UI_reference/four_12/home.jpeg` (VIS-05).
abstract final class SeniorHomeVisualFixtures {
  static const headlinePrefix = "I'm building ";
  static const headlineAccent = 'my future.';
  static const streakDays = 12;
  static const streakCaption = "Today's Builder Streak";
  static const rankTitle = 'Builder Rank';
  static const rankLabel = 'Gold Builder';

  static const continueEyebrow = 'Continue Building';
  static const continueTitle = 'Resume your current project';
  static const projectTitle = 'Space Explorer Game';
  static const projectProgress = 0.72;
  static const continueLabel = 'Continue';

  static const missions = <({
    String kind,
    String title,
    int xp,
    String progress,
    Color accent,
    IconData icon,
  })>[
    (
      kind: 'Learn',
      title: 'Complete a lesson',
      xp: 40,
      progress: '0 / 1',
      accent: Color(0xFF2FBF71),
      icon: Icons.menu_book_rounded,
    ),
    (
      kind: 'Build',
      title: 'Work on your project',
      xp: 60,
      progress: '0 / 1',
      accent: Color(0xFFFF8A3D),
      icon: Icons.construction_rounded,
    ),
    (
      kind: 'Share',
      title: 'Share what you built',
      xp: 30,
      progress: '0 / 1',
      accent: Color(0xFF3D8BFF),
      icon: Icons.share_rounded,
    ),
  ];

  static const dashboard = <({
    String value,
    String label,
    Color accent,
    IconData icon,
  })>[
    (
      value: '560 XP',
      label: 'Total XP',
      accent: Color(0xFF9B6DFF),
      icon: Icons.hexagon_outlined,
    ),
    (
      value: '8',
      label: 'Projects Built',
      accent: Color(0xFF3D8BFF),
      icon: Icons.view_in_ar,
    ),
    (
      value: '6.4',
      label: 'Hours Focused',
      accent: Color(0xFF2FBF71),
      icon: Icons.schedule,
    ),
    (
      value: '42',
      label: 'Problems Solved',
      accent: Color(0xFFFF8A3D),
      icon: Icons.code,
    ),
  ];

  static const learning = <({
    String title,
    String tag,
    double progress,
    String difficulty,
    String time,
    Color accent,
    IconData icon,
  })>[
    (
      title: 'Genetics: The Code of Life',
      tag: 'Science',
      progress: 0.65,
      difficulty: 'Medium',
      time: '45 min',
      accent: Color(0xFF9B6DFF),
      icon: Icons.biotech,
    ),
    (
      title: 'The Tempest',
      tag: 'English',
      progress: 0.30,
      difficulty: 'Easy',
      time: '30 min',
      accent: Color(0xFF3D8BFF),
      icon: Icons.description_outlined,
    ),
    (
      title: 'The Mughal Empire',
      tag: 'History',
      progress: 0.20,
      difficulty: 'Medium',
      time: '40 min',
      accent: Color(0xFFFF8A3D),
      icon: Icons.account_balance,
    ),
  ];

  static const challengeTimer = 'New Challenge in 14:18:32';
  static const challengeBadge = "Today's Challenge";
  static const challengeTitle = 'Build a Calculator';
  static const challengeBody =
      'Design a working calculator with clear layout and logic.';
  static const challengeReward = 'Reward 100 XP';
}
