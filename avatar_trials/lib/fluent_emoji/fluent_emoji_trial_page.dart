import 'package:flutter/material.dart';

class _EmojiReaction {
  const _EmojiReaction({
    required this.id,
    required this.label,
    required this.asset,
    required this.eventHint,
  });

  final String id;
  final String label;
  final String asset;
  final String eventHint;
}

const _reactions = <_EmojiReaction>[
  _EmojiReaction(
    id: 'happy',
    label: 'Happy',
    asset: 'assets/fluent_emoji/happy.png',
    eventHint: 'Correct answer',
  ),
  _EmojiReaction(
    id: 'thumbs_up',
    label: 'Thumbs up',
    asset: 'assets/fluent_emoji/thumbs_up.png',
    eventHint: 'Encouragement',
  ),
  _EmojiReaction(
    id: 'clap',
    label: 'Clap',
    asset: 'assets/fluent_emoji/clap.png',
    eventHint: 'Good effort',
  ),
  _EmojiReaction(
    id: 'partying',
    label: 'Party',
    asset: 'assets/fluent_emoji/partying.png',
    eventHint: 'Quiz completed',
  ),
  _EmojiReaction(
    id: 'party_popper',
    label: 'Celebrate',
    asset: 'assets/fluent_emoji/party_popper.png',
    eventHint: 'Achievement',
  ),
  _EmojiReaction(
    id: 'starstruck',
    label: 'Star-struck',
    asset: 'assets/fluent_emoji/starstruck.png',
    eventHint: 'Major success',
  ),
  _EmojiReaction(
    id: 'thinking',
    label: 'Thinking',
    asset: 'assets/fluent_emoji/thinking.png',
    eventHint: 'Waiting / hint',
  ),
  _EmojiReaction(
    id: 'confused',
    label: 'Confused',
    asset: 'assets/fluent_emoji/confused.png',
    eventHint: 'Wrong answer',
  ),
  _EmojiReaction(
    id: 'crying',
    label: 'Sad',
    asset: 'assets/fluent_emoji/crying.png',
    eventHint: 'Struggle',
  ),
  _EmojiReaction(
    id: 'surprised',
    label: 'Surprise',
    asset: 'assets/fluent_emoji/surprised.png',
    eventHint: 'Unexpected',
  ),
  _EmojiReaction(
    id: 'hug',
    label: 'Hug',
    asset: 'assets/fluent_emoji/hug.png',
    eventHint: 'Comfort',
  ),
  _EmojiReaction(
    id: 'sleeping',
    label: 'Sleep',
    asset: 'assets/fluent_emoji/sleeping.png',
    eventHint: 'Idle / break',
  ),
  _EmojiReaction(
    id: 'wave',
    label: 'Wave',
    asset: 'assets/fluent_emoji/wave.png',
    eventHint: 'Hello / return',
  ),
  _EmojiReaction(
    id: 'joy',
    label: 'Joy',
    asset: 'assets/fluent_emoji/joy.png',
    eventHint: 'Fun moment',
  ),
  _EmojiReaction(
    id: 'ok',
    label: 'OK',
    asset: 'assets/fluent_emoji/ok.png',
    eventHint: 'Confirm',
  ),
  _EmojiReaction(
    id: 'folded',
    label: 'Thanks',
    asset: 'assets/fluent_emoji/folded.png',
    eventHint: 'Gratitude',
  ),
];

/// Trial C: Microsoft Fluent animated emoji reactions (MIT).
/// Great for quiz feedback chips — not a full-body companion.
class FluentEmojiTrialPage extends StatefulWidget {
  const FluentEmojiTrialPage({super.key});

  @override
  State<FluentEmojiTrialPage> createState() => _FluentEmojiTrialPageState();
}

class _FluentEmojiTrialPageState extends State<FluentEmojiTrialPage> {
  late _EmojiReaction _selected;

  @override
  void initState() {
    super.initState();
    _selected = _reactions.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluent animated emoji'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Microsoft Fluent animated emoji (MIT) · 256×256 APNG.\n'
            'Best for quiz feedback overlays — not a single companion body.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3EF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Column(
                children: [
                  Image.asset(
                    _selected.asset,
                    width: 220,
                    height: 220,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 220,
                      child: Center(child: Text('Failed to load emoji')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _selected.label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'App event idea: ${_selected.eventHint}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Reactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final reaction in _reactions)
                ChoiceChip(
                  label: Text(reaction.label),
                  selected: _selected.id == reaction.id,
                  onSelected: (_) => setState(() => _selected = reaction),
                  avatar: ClipOval(
                    child: Image.asset(
                      reaction.asset,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'How this fits Nano',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '• Use as reaction stickers after quiz / video events\n'
            '• Pair with a 3D companion (robot/monster) for body motion\n'
            '• Fully offline once bundled\n'
            '• Not a replacement for Nori as a character',
            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Assets: Microsoft Fluent Emoji Animated · MIT License',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
