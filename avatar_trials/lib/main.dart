import 'dart:math';

import 'package:avatar_maker/avatar_maker.dart';
import 'package:avatar_trials/companion/companion_trial_page.dart';
import 'package:avatar_trials/dicebear/dicebear_trial_page.dart';
import 'package:avatar_trials/fluent_emoji/fluent_emoji_trial_page.dart';
import 'package:avatar_trials/dragon/dragon_trial_page.dart';
import 'package:avatar_trials/kenney/kenney_shapes_trial_page.dart';
import 'package:avatar_trials/rabbit/rabbit_state_machine_trial_page.dart';
import 'package:avatar_trials/sungraphica/sungraphica_cat_trial_page.dart';
import 'package:avatar_trials/raccoon/null_painter_raccoon_trial_page.dart';
import 'package:avatar_trials/mewki/bunny_mood_trial_page.dart';
import 'package:avatar_trials/mewki/fox_mood_trial_page.dart';
import 'package:avatar_trials/panda/panda_trial_page.dart';
import 'package:avatar_trials/quirky/quirky_animals_trial_page.dart';
import 'package:avatar_trials/xylo/xylo_trial_page.dart';
import 'package:avatar_trials/monsters/monsters_trial_page.dart';
import 'package:avatar_trials/robot/robot_trial_page.dart';
import 'package:avatar_trials/threedee_robotz/threedee_robotz_trial_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runApp(const AvatarTrialsApp());
}

class AvatarTrialsApp extends StatelessWidget {
  const AvatarTrialsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avatar Trials',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6F5E)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Trials'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Try each system one by one',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Start with avatar_maker for student profile avatars.',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _TrialCard(
            title: '1. avatar_maker',
            subtitle: 'Student profile customizer + SVG avatar',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AvatarMakerTrialPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '2. Yofardev AI engine',
            subtitle: 'Nori reaction / animation controller',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CompanionTrialPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '3. DiceBear defaults',
            subtitle: 'Auto-generated profile pictures',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiceBearTrialPage()),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Animal companion trials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Child-friendly non-robot characters (try one by one).',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _TrialCard(
            title: '1. Mewki Fox Mood',
            subtitle: '21 fox emotions Â· Flutter bounce/tilt',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FoxMoodTrialPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '2. Mewki Bunny Mood',
            subtitle: '26 bunny emotions Â· Flutter bounce/tilt',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BunnyMoodTrialPage()),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Simple 2D mascot trials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Duolingo-like flat companions (try one by one).',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _TrialCard(
            title: '1. Kenney Shape Characters',
            subtitle: 'CC0 modular body/face/hands Â· Flutter motion',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const KenneyShapesTrialPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '2. Rabbit state machine',
            subtitle: 'Local fallback Â· event-driven states',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RabbitStateMachineTrialPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '3. SunGraphica Cat',
            subtitle: 'CC BY Â· 9 emotions Â· Duolingo-like 2D',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SunGraphicaCatTrialPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '4. Null Painter Raccoon',
            subtitle: 'CC BY · 8 full-body animation loops',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NullPainterRaccoonTrialPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const _TrialCard(
            title: '5. SunGraphica Bird',
            subtitle: 'Same pack · more face modes',
            status: 'Next',
          ),
          const SizedBox(height: 12),
          const _TrialCard(
            title: '6. Kitsune Fox / Lottie options',
            subtitle: 'Earlier Lottie candidates',
            status: 'Later',
          ),
          const SizedBox(height: 28),
          const Text(
            'Full-body companion trials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Complete characters with emotions (try one by one).',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _TrialCard(
            title: '1. Xylo (Megupets)',
            subtitle: 'Full-body 2D Â· CC0 Â· faces + hype + walk',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const XyloTrialPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '2. Cartoon Panda',
            subtitle: 'MR7 audit Â· 1 anim Â· CC-BY Â· local CC0 stand-in',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PandaTrialPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '3. Cute Orange Dragon',
            subtitle: 'shakiller audit Â· 1 anim Â· CC-BY Â· local CC0 stand-in',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DragonTrialPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: '4. Quirky Series Animals',
            subtitle: '8 animals Â· 18 clips Â· CC-BY Â· local GLB',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const QuirkyAnimalsTrialPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            '3D companion trials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Animated learning companion options (try one by one).',
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _TrialCard(
            title: 'D. ThreeDee Robotz',
            subtitle: 'Polished cartoon robot Â· free Gumroad tier',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ThreeDeeRobotzTrialPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: 'A. Quaternius LowPoly Robot',
            subtitle: 'CC0 Â· 14 animations Â· flutter_3d_controller',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RobotTrialPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: 'B. Cute Animated Monsters',
            subtitle: 'Quaternius CC0 monster pack',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MonstersTrialPage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _TrialCard(
            title: 'C. Fluent animated emoji',
            subtitle: 'Microsoft MIT emoji reactions',
            status: 'Ready to try',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const FluentEmojiTrialPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrialCard extends StatelessWidget {
  const _TrialCard({
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? const Color(0xFFE8F3EF) : const Color(0xFFF3F3F3),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? const Color(0xFF2F6F5E)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Own the controller explicitly â€” the package's provider registers
/// `AvatarMakerController`, but widgets look up `AvatarMakerController?`,
/// so Provider misses and each rebuild creates a disposable controller.
class AvatarMakerTrialPage extends StatefulWidget {
  const AvatarMakerTrialPage({super.key});

  @override
  State<AvatarMakerTrialPage> createState() => _AvatarMakerTrialPageState();
}

class _AvatarMakerTrialPageState extends State<AvatarMakerTrialPage> {
  late final AvatarMakerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PersistentAvatarMakerController(
      locale: WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('avatar_maker trial'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              AvatarMakerAvatar(
                radius: 96,
                backgroundColor: const Color(0xFFE8F3EF),
                controller: _controller,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AvatarMakerSaveWidget(controller: _controller),
                  const SizedBox(width: 8),
                  AvatarMakerRandomWidget(controller: _controller),
                  const SizedBox(width: 8),
                  AvatarMakerResetWidget(controller: _controller),
                ],
              ),
              const SizedBox(height: 24),
              AvatarMakerCustomizer(
                scaffoldWidth: min(600, width * 0.9),
                controller: _controller,
                autosave: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


