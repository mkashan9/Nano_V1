import 'package:flutter/material.dart';

/// Visual fixtures matching `UI_reference/four_12/Communities.jpeg` (VIS-09).
abstract final class SeniorCommunitiesVisualFixtures {
  static const title = 'Communities';
  static const subtitlePrefix = 'Build ';
  static const subtitleAccent = 'Together ✨';

  static const challengeEyebrow = 'WEEKLY BUILD CHALLENGE';
  static const challengeHeadline = 'Solve real problems. ';
  static const challengeHeadlineAccent = 'Build the future.';
  static const challengeBody =
      'Choose a challenge, build with others and create impact.';
  static const challengeCta = 'Join Challenge';
  static const challengeTimer = 'Ends in 2d 14h 32m';
  static const challengeReward = 'Reward 500 XP + Badge';
  static const challengeJoiners = '1,248 Builders joining';

  static const challenges = <({IconData icon, String label})>[
    (icon: Icons.smart_toy, label: 'Build an AI Study Assistant'),
    (icon: Icons.phone_android, label: 'Create a School Attendance App'),
    (icon: Icons.recycling, label: 'Design a Better Recycling System'),
  ];

  static const teams = <({
    String title,
    String needs,
    String members,
    Color accent,
    IconData icon,
  })>[
    (
      title: 'Flutter Team',
      needs: 'Needs UI Designer',
      members: '2/5 Members',
      accent: Color(0xFF3D8BFF),
      icon: Icons.flutter_dash,
    ),
    (
      title: 'AI Crew',
      needs: 'Needs Prompt Engineer',
      members: '3/6 Members',
      accent: Color(0xFF9B6DFF),
      icon: Icons.psychology,
    ),
    (
      title: 'Robotics Lab',
      needs: 'Needs Hardware Lead',
      members: '4/8 Members',
      accent: Color(0xFF2FBF71),
      icon: Icons.precision_manufacturing,
    ),
  ];

  static const clubs = <({
    String title,
    String members,
    Color accent,
    IconData icon,
  })>[
    (
      title: 'AI Builders',
      members: '1,532 Members',
      accent: Color(0xFF9B6DFF),
      icon: Icons.psychology,
    ),
    (
      title: 'Game Developers',
      members: '980 Members',
      accent: Color(0xFF3D8BFF),
      icon: Icons.sports_esports,
    ),
    (
      title: 'Future Scientists',
      members: '1,210 Members',
      accent: Color(0xFF2FBF71),
      icon: Icons.science,
    ),
    (
      title: 'Young Founders',
      members: '760 Members',
      accent: Color(0xFFFF8A3D),
      icon: Icons.show_chart,
    ),
    (
      title: 'Robot Makers',
      members: '640 Members',
      accent: Color(0xFFB39DFF),
      icon: Icons.smart_toy,
    ),
    (
      title: 'Design Studio',
      members: '890 Members',
      accent: Color(0xFFFF6B9D),
      icon: Icons.draw,
    ),
  ];

  static const startEyebrow = 'Have an idea?';
  static const startTitle = 'Start Your ';
  static const startTitleAccent = 'Own Project';
  static const startCta = 'Create Project';
  static const startBullets = <({IconData icon, String label})>[
    (icon: Icons.groups, label: 'Find teammates'),
    (icon: Icons.extension, label: 'Build together'),
    (icon: Icons.bolt, label: 'Learn by creating'),
  ];
}
