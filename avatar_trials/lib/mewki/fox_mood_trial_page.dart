import 'package:flutter/material.dart';

class _FoxMood {
  const _FoxMood({
    required this.id,
    required this.label,
    required this.asset,
    required this.eventHint,
    this.motion = FoxMotion.bounce,
  });

  final String id;
  final String label;
  final String asset;
  final String eventHint;
  final FoxMotion motion;
}

enum FoxMotion { bounce, tilt, soft }

const _appReactions = <_FoxMood>[
  _FoxMood(
    id: 'correct',
    label: 'Correct',
    asset: 'assets/mewki_fox/fox_emote_14.png',
    eventHint: 'Correct answer → YES',
    motion: FoxMotion.bounce,
  ),
  _FoxMood(
    id: 'happy',
    label: 'Happy',
    asset: 'assets/mewki_fox/fox_emote_12.png',
    eventHint: 'Student returns / greeting',
    motion: FoxMotion.bounce,
  ),
  _FoxMood(
    id: 'love',
    label: 'Proud',
    asset: 'assets/mewki_fox/fox_emote_03.png',
    eventHint: 'Achievement / stars moment',
    motion: FoxMotion.bounce,
  ),
  _FoxMood(
    id: 'adore',
    label: 'Celebrate',
    asset: 'assets/mewki_fox/fox_emote_07.png',
    eventHint: 'Quiz completed',
    motion: FoxMotion.bounce,
  ),
  _FoxMood(
    id: 'thinking',
    label: 'Thinking',
    asset: 'assets/mewki_fox/fox_emote_05.png',
    eventHint: 'Waiting for answer / hint loading',
    motion: FoxMotion.tilt,
  ),
  _FoxMood(
    id: 'curious',
    label: 'Curious',
    asset: 'assets/mewki_fox/fox_emote_01.png',
    eventHint: 'Hint available',
    motion: FoxMotion.tilt,
  ),
  _FoxMood(
    id: 'surprised',
    label: 'Surprised',
    asset: 'assets/mewki_fox/fox_emote_11.png',
    eventHint: 'Unexpected result',
    motion: FoxMotion.bounce,
  ),
  _FoxMood(
    id: 'sad',
    label: 'Sad',
    asset: 'assets/mewki_fox/fox_emote_04.png',
    eventHint: 'Incorrect — gentle retry',
    motion: FoxMotion.soft,
  ),
  _FoxMood(
    id: 'no',
    label: 'No',
    asset: 'assets/mewki_fox/fox_emote_08.png',
    eventHint: 'Wrong answer (firmer)',
    motion: FoxMotion.soft,
  ),
  _FoxMood(
    id: 'frustrated',
    label: 'Frustrated',
    asset: 'assets/mewki_fox/fox_emote_10.png',
    eventHint: 'Repeated struggle',
    motion: FoxMotion.soft,
  ),
  _FoxMood(
    id: 'offline',
    label: 'Offline',
    asset: 'assets/mewki_fox/fox_emote_09.png',
    eventHint: 'Offline / confused',
    motion: FoxMotion.soft,
  ),
  _FoxMood(
    id: 'focused',
    label: 'Focused',
    asset: 'assets/mewki_fox/fox_emote_02.png',
    eventHint: 'Lesson begins / concentrate',
    motion: FoxMotion.tilt,
  ),
];

/// All numbered emotes for browsing the full pack.
final _allEmotes = List<_FoxMood>.generate(19, (i) {
  final n = i + 1;
  final id = n.toString().padLeft(2, '0');
  return _FoxMood(
    id: 'emote_$id',
    label: 'Emote $id',
    asset: 'assets/mewki_fox/fox_emote_$id.png',
    eventHint: 'Browse pack expression',
    motion: FoxMotion.bounce,
  );
});

/// Trial 1 (animal companions): Mewki Fox Mood + Flutter motion.
class FoxMoodTrialPage extends StatefulWidget {
  const FoxMoodTrialPage({super.key});

  @override
  State<FoxMoodTrialPage> createState() => _FoxMoodTrialPageState();
}

class _FoxMoodTrialPageState extends State<FoxMoodTrialPage>
    with SingleTickerProviderStateMixin {
  late _FoxMood _current;
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _current = _appReactions.first;
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

  void _select(_FoxMood mood) {
    setState(() => _current = mood);
    _motion
      ..duration = switch (mood.motion) {
        FoxMotion.bounce => const Duration(milliseconds: 550),
        FoxMotion.tilt => const Duration(milliseconds: 700),
        FoxMotion.soft => const Duration(milliseconds: 450),
      }
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mewki Fox Mood'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Hand-drawn fox emotions · commercial use OK · static PNGs + Flutter motion.\n'
            'Tap an app event to switch expression.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 240,
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (context, child) {
                        final t = Curves.easeOutBack.transform(_motion.value);
                        final soft = Curves.easeOut.transform(_motion.value);
                        return switch (_current.motion) {
                          FoxMotion.bounce => Transform.scale(
                              scale: 0.82 + 0.18 * t,
                              child: child,
                            ),
                          FoxMotion.tilt => Transform.rotate(
                              angle: (1 - soft) * -0.18,
                              child: Transform.scale(
                                scale: 0.92 + 0.08 * soft,
                                child: child,
                              ),
                            ),
                          FoxMotion.soft => Transform.translate(
                              offset: Offset(0, (1 - soft) * 16),
                              child: Opacity(
                                opacity: 0.55 + 0.45 * soft,
                                child: child,
                              ),
                            ),
                        };
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutBack,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: Image.asset(
                          _current.asset,
                          key: ValueKey(_current.asset),
                          width: 220,
                          height: 220,
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
              for (final mood in _appReactions)
                ChoiceChip(
                  label: Text(mood.label),
                  selected: _current.id == mood.id,
                  onSelected: (_) => _select(mood),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'All pack emotes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Browse every expression in the downloaded pack.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allEmotes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              final mood = _allEmotes[index];
              final selected = _current.asset == mood.asset;
              return Material(
                color: selected ? const Color(0xFFE8F3EF) : Colors.black,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _select(mood),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Image.asset(mood.asset, fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Source: mewki · https://mewki.itch.io/fox-emotes · '
            'commercial & personal use allowed.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
