import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:student_app/features/learning/visual/senior_learning_visual_assets.dart';

/// Visual fixtures matching `UI_reference/four_12/Learning_stack.jpeg` (VIS-06).
abstract final class SeniorLearningVisualFixtures {
  static const searchHint = 'Search anything to learn...';
  static const mentorGreeting = 'Hi Builder!';
  static const mentorTitlePrefix = "I'm your ";
  static const mentorTitleAccent = 'AI Mentor';
  static const mentorBody =
      "I'll help you learn, build and create amazing things.";
  static const mentorCta = 'Chat with Mentor';

  static const recent = <({String title, double progress, Color accent, IconData icon})>[
    (
      title: 'Python Basics',
      progress: 0.65,
      accent: Color(0xFF3D8BFF),
      icon: Icons.code,
    ),
    (
      title: 'Intro to AI',
      progress: 0.40,
      accent: Color(0xFF9B6DFF),
      icon: Icons.psychology,
    ),
    (
      title: 'Space Science',
      progress: 0.25,
      accent: Color(0xFF2FBF71),
      icon: Icons.public,
    ),
  ];

  static const categories = <({
    String title,
    String meta,
    String difficulty,
    Color accent,
    String? asset,
    IconData icon,
  })>[
    (
      title: 'Programming',
      meta: '28 Courses · 48h',
      difficulty: 'Easy',
      accent: Color(0xFF3D8BFF),
      asset: SeniorLearningVisualAssets.catProgramming,
      icon: Icons.laptop_mac,
    ),
    (
      title: 'AI',
      meta: '12 Courses · 30h',
      difficulty: 'Medium',
      accent: Color(0xFF9B6DFF),
      asset: SeniorLearningVisualAssets.catAi,
      icon: Icons.psychology,
    ),
    (
      title: 'Science',
      meta: '22 Courses · 36h',
      difficulty: 'Medium',
      accent: Color(0xFF2FBF71),
      asset: SeniorLearningVisualAssets.catScience,
      icon: Icons.science,
    ),
    (
      title: 'Business',
      meta: '16 Courses · 24h',
      difficulty: 'Easy',
      accent: Color(0xFFFF8A3D),
      asset: null,
      icon: Icons.business_center,
    ),
    (
      title: 'History',
      meta: '10 Courses · 18h',
      difficulty: 'Easy',
      accent: Color(0xFFFF4F9A),
      asset: null,
      icon: Icons.account_balance,
    ),
    (
      title: 'Design',
      meta: '14 Courses · 20h',
      difficulty: 'Medium',
      accent: Color(0xFFB39DFF),
      asset: null,
      icon: Icons.brush,
    ),
  ];

  static const paths = <SeniorPathStep>[
    SeniorPathStep(
      title: 'Foundations',
      statusLabel: 'Completed',
      state: SeniorPathStepState.completed,
    ),
    SeniorPathStep(
      title: 'Build Basics',
      statusLabel: 'In Progress',
      state: SeniorPathStepState.inProgress,
    ),
    SeniorPathStep(
      title: 'Real World Builder',
      statusLabel: 'Locked',
      state: SeniorPathStepState.locked,
    ),
  ];
}
