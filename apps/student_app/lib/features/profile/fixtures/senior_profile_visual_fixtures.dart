import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';

/// Visual fixtures matching `UI_reference/four_12/profile.jpeg` (VIS-08).
abstract final class SeniorProfileVisualFixtures {
  static const displayName = 'Ayaan';
  static const greeting = 'Hey Ayaan!';
  static const subtitle = 'Keep learning, keep leveling up!';
  static const rankLabel = 'Master Builder';
  static const levelLabel = 'Level 28';
  static const xpLabel = '12,450 / 15,000 XP';
  static const xpProgress = 12450 / 15000;
  static const streakDays = 23;
  static const streakSubtitle = 'Keep building!';

  static const metrics = <({
    String value,
    String label,
    Color accent,
    IconData icon,
  })>[
    (
      value: '12,450',
      label: 'XP Earned · +1,250',
      accent: Color(0xFF9B6DFF),
      icon: Icons.star_rounded,
    ),
    (
      value: '24',
      label: 'Projects · +3',
      accent: Color(0xFF3D8BFF),
      icon: Icons.work_outline,
    ),
    (
      value: '86',
      label: 'Hours · +10',
      accent: Color(0xFFFF8A3D),
      icon: Icons.schedule,
    ),
    (
      value: '320',
      label: 'Problems · +45',
      accent: Color(0xFF2FBF71),
      icon: Icons.lightbulb_outline,
    ),
  ];

  static const weekGoals = <({
    String title,
    String body,
    String progressLabel,
    String xpLabel,
    double progress,
    Color accent,
    IconData icon,
  })>[
    (
      title: 'Learn',
      body: 'Complete 3 lessons',
      progressLabel: '2 / 3',
      xpLabel: '+150 XP',
      progress: 2 / 3,
      accent: Color(0xFF9B6DFF),
      icon: Icons.menu_book,
    ),
    (
      title: 'Build',
      body: 'Work on a project',
      progressLabel: '1 / 1',
      xpLabel: '+200 XP',
      progress: 1,
      accent: Color(0xFF2FBF71),
      icon: Icons.build,
    ),
    (
      title: 'Share',
      body: 'Share your progress',
      progressLabel: '0 / 1',
      xpLabel: '+100 XP',
      progress: 0,
      accent: Color(0xFF3D8BFF),
      icon: Icons.send,
    ),
  ];

  static const achievements = <({String title, String level, Color accent, IconData icon})>[
    (title: 'Problem Solver', level: 'Level 4', accent: Color(0xFF9B6DFF), icon: Icons.psychology),
    (title: 'Creative Builder', level: 'Level 4', accent: Color(0xFFFF8A3D), icon: Icons.lightbulb),
    (title: 'Science Explorer', level: 'Level 3', accent: Color(0xFF3D8BFF), icon: Icons.science),
    (title: 'Entrepreneur', level: 'Level 3', accent: Color(0xFF2FBF71), icon: Icons.show_chart),
    (title: 'AI Creator', level: 'Level 4', accent: Color(0xFFB39DFF), icon: Icons.smart_toy),
    (title: 'Team Leader', level: 'Level 4', accent: Color(0xFFFF8A3D), icon: Icons.groups),
  ];

  static const topBuilders = <({String name, String rank, String streak})>[
    (name: 'Zayan', rank: 'Elite Builder', streak: '12 Day Streak'),
    (name: 'Hania', rank: 'Master Builder', streak: '8 Day Streak'),
    (name: 'Noor', rank: 'Rising Builder', streak: '5 Day Streak'),
  ];

  static const journey = <SeniorPathStep>[
    SeniorPathStep(
      title: 'Foundations',
      statusLabel: 'Completed',
      state: SeniorPathStepState.completed,
    ),
    SeniorPathStep(
      title: 'Problem Solver',
      statusLabel: 'Completed',
      state: SeniorPathStepState.completed,
    ),
    SeniorPathStep(
      title: 'Independent Builder',
      statusLabel: 'In Progress',
      state: SeniorPathStepState.inProgress,
    ),
    SeniorPathStep(
      title: 'Team Builder',
      statusLabel: 'Locked',
      state: SeniorPathStepState.locked,
    ),
    SeniorPathStep(
      title: 'Innovator',
      statusLabel: 'Locked',
      state: SeniorPathStepState.locked,
    ),
    SeniorPathStep(
      title: 'Future Founder',
      statusLabel: 'Locked',
      state: SeniorPathStepState.locked,
    ),
  ];
}
