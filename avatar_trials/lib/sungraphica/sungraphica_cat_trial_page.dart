import 'package:flutter/material.dart';

enum _CatMotion { bounce, tilt, soft }

class _CatMood {
  const _CatMood({
    required this.id,
    required this.label,
    required this.asset,
    required this.eventHint,
    this.motion = _CatMotion.bounce,
  });

  final String id;
  final String label;
  final String asset;
  final String eventHint;
  final _CatMotion motion;
}

const _reactions = <_CatMood>[
  _CatMood(
    id: 'welcome',
    label: 'Welcome',
    asset: 'assets/sungraphica_cat/faces/normal.png',
    eventHint: 'Student opens app',
  ),
  _CatMood(
    id: 'correct',
    label: 'Correct',
    asset: 'assets/sungraphica_cat/faces/happy.png',
    eventHint: 'Correct answer · closed-eye smile',
  ),
  _CatMood(
    id: 'celebrate',
    label: 'Celebrate',
    asset: 'assets/sungraphica_cat/faces/excited.png',
    eventHint: 'Quiz completed · excited laugh',
  ),
  _CatMood(
    id: 'thinking',
    label: 'Thinking',
    asset: 'assets/sungraphica_cat/faces/bored.png',
    eventHint: 'Waiting / processing',
    motion: _CatMotion.tilt,
  ),
  _CatMood(
    id: 'surprised',
    label: 'Surprised',
    asset: 'assets/sungraphica_cat/faces/surprised.png',
    eventHint: 'Unexpected result / hint',
  ),
  _CatMood(
    id: 'sad',
    label: 'Sad',
    asset: 'assets/sungraphica_cat/faces/sad.png',
    eventHint: 'Incorrect — gentle retry',
    motion: _CatMotion.soft,
  ),
  _CatMood(
    id: 'tired',
    label: 'Tired',
    asset: 'assets/sungraphica_cat/faces/tired.png',
    eventHint: 'Student struggling / sweat',
    motion: _CatMotion.soft,
  ),
  _CatMood(
    id: 'stern',
    label: 'Stern',
    asset: 'assets/sungraphica_cat/faces/angry.png',
    eventHint: 'Wrong answer (firmer)',
    motion: _CatMotion.soft,
  ),
  _CatMood(
    id: 'furious',
    label: 'Furious',
    asset: 'assets/sungraphica_cat/faces/furious.png',
    eventHint: 'Pack includes this — likely skip for kids UX',
    motion: _CatMotion.soft,
  ),
];

final _allFaces = [
  for (final name in [
    'normal',
    'happy',
    'excited',
    'bored',
    'angry',
    'furious',
    'sad',
    'tired',
    'surprised',
  ])
    _CatMood(
      id: name,
      label: name[0].toUpperCase() + name.substring(1),
      asset: 'assets/sungraphica_cat/faces/$name.png',
      eventHint: 'Browse pack expression',
    ),
];

/// Trial: SunGraphica Cat — full-body emotion PNGs + Flutter motion.
class SunGraphicaCatTrialPage extends StatefulWidget {
  const SunGraphicaCatTrialPage({super.key});

  @override
  State<SunGraphicaCatTrialPage> createState() =>
      _SunGraphicaCatTrialPageState();
}

class _SunGraphicaCatTrialPageState extends State<SunGraphicaCatTrialPage>
    with SingleTickerProviderStateMixin {
  late _CatMood _current;
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _current = _reactions.first;
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _select(_CatMood mood) {
    setState(() => _current = mood);
    _motion
      ..duration = switch (mood.motion) {
        _CatMotion.bounce => const Duration(milliseconds: 550),
        _CatMotion.tilt => const Duration(milliseconds: 700),
        _CatMotion.soft => const Duration(milliseconds: 450),
      }
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SunGraphica Cat'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Full-body flat 2D cat · 9 emotion poses · CC BY 4.0 (credit SunGraphica).\n'
            'SVG source included for later scarf/book branding and limb posing.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2C),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 260,
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (context, child) {
                        final t = Curves.easeOutBack.transform(_motion.value);
                        final soft = Curves.easeOut.transform(_motion.value);
                        return switch (_current.motion) {
                          _CatMotion.bounce => Transform.scale(
                              scale: 0.86 + 0.14 * t,
                              child: child,
                            ),
                          _CatMotion.tilt => Transform.rotate(
                              angle: (1 - soft) * -0.14,
                              child: Transform.scale(
                                scale: 0.94 + 0.06 * soft,
                                child: child,
                              ),
                            ),
                          _CatMotion.soft => Transform.translate(
                              offset: Offset(0, (1 - soft) * 14),
                              child: Opacity(
                                opacity: 0.55 + 0.45 * soft,
                                child: child,
                              ),
                            ),
                        };
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Image.asset(
                          _current.asset,
                          key: ValueKey(_current.asset),
                          height: 240,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _current.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _current.eventHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'App event reactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final mood in _reactions)
                ChoiceChip(
                  label: Text(mood.label),
                  selected: _current.id == mood.id,
                  onSelected: (_) => _select(mood),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('All pack emotions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allFaces.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final mood = _allFaces[index];
              final selected = _current.asset == mood.asset;
              return Material(
                color: selected ? const Color(0xFFE8F3EF) : const Color(0xFF1A1F2C),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _select(mood),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(mood.asset, fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Verdict so far: strongest Duolingo-like full-body free foundation. '
                'Emotions are already readable. Next design pass would add scarf/book '
                'branding and a few limb poses (wave/point) from the SVG elements.',
                style: TextStyle(height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Source: SunGraphica · itch.io/funny-character-pack-free-version · CC BY 4.0',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
