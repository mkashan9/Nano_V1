import 'package:dicebear_core/dicebear_core.dart' hide Color;
import 'package:dicebear_styles/adventurer.dart';
import 'package:dicebear_styles/avataaars.dart';
import 'package:dicebear_styles/big_smile.dart';
import 'package:dicebear_styles/bottts.dart';
import 'package:dicebear_styles/fun_emoji.dart';
import 'package:dicebear_styles/lorelei.dart';
import 'package:dicebear_styles/miniavs.dart';
import 'package:dicebear_styles/thumbs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class _StyleOption {
  const _StyleOption(this.id, this.label, this.rawJson);

  final String id;
  final String label;
  final String rawJson;
}

const _styles = <_StyleOption>[
  _StyleOption('avataaars', 'Avataaars', avataaars),
  _StyleOption('lorelei', 'Lorelei', lorelei),
  _StyleOption('adventurer', 'Adventurer', adventurer),
  _StyleOption('fun_emoji', 'Fun Emoji', funEmoji),
  _StyleOption('big_smile', 'Big Smile', bigSmile),
  _StyleOption('miniavs', 'Miniavs', miniavs),
  _StyleOption('bottts', 'Bottts', bottts),
  _StyleOption('thumbs', 'Thumbs', thumbs),
];

/// Trial 3: DiceBear local SVG generation from a student seed.
/// Same seed → same avatar. No network required.
class DiceBearTrialPage extends StatefulWidget {
  const DiceBearTrialPage({super.key});

  @override
  State<DiceBearTrialPage> createState() => _DiceBearTrialPageState();
}

class _DiceBearTrialPageState extends State<DiceBearTrialPage> {
  final _seedController = TextEditingController(text: 'student_1287');
  late Style _style;
  String _styleId = _styles.first.id;
  late String _seed;
  late String _svgA;
  late String _svgB;

  static const _demoStudents = <String>[
    'student_1287',
    'student_42',
    'student_901',
    'aisha',
    'leo',
    'maya',
  ];

  @override
  void initState() {
    super.initState();
    _style = Style.parse(_styles.first.rawJson);
    _regenerate();
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _setStyle(String id) {
    final option = _styles.firstWhere((s) => s.id == id);
    setState(() {
      _styleId = id;
      _style = Style.parse(option.rawJson);
      _regenerate();
    });
  }

  void _regenerate() {
    _seed = _seedController.text.trim().isEmpty
        ? 'student_1287'
        : _seedController.text.trim();
    _svgA = Avatar(_style, {
      'seed': _seed,
      'size': 128,
      'backgroundColor': ['b6e3f4', 'c0aede', 'd1d4f9'],
    }).svg;
    // Same seed again — proves determinism.
    _svgB = Avatar(_style, {
      'seed': _seed,
      'size': 128,
      'backgroundColor': ['b6e3f4', 'c0aede', 'd1d4f9'],
    }).svg;
  }

  String _svgFor(String seed) {
    return Avatar(_style, {
      'seed': seed,
      'size': 96,
      'backgroundColor': ['b6e3f4', 'c0aede', 'd1d4f9'],
    }).svg;
  }

  @override
  Widget build(BuildContext context) {
    final match = _svgA == _svgB;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DiceBear trial'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Default / auto profile pictures — generated locally from a seed.\n'
            'No internet, no uploads. Same student ID → same face every time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _seedController,
            decoration: const InputDecoration(
              labelText: 'Seed (e.g. student_1287)',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => setState(_regenerate),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => setState(_regenerate),
            child: const Text('Generate'),
          ),
          const SizedBox(height: 20),
          Text(
            'Style',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _styles)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _styleId == s.id,
                  onSelected: (_) => _setStyle(s.id),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AvatarCard(label: 'From seed', svg: _svgA),
              const SizedBox(width: 16),
              _AvatarCard(label: 'Same seed again', svg: _svgB),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            match
                ? 'Deterministic: both SVGs are identical.'
                : 'Mismatch — unexpected.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: match ? const Color(0xFF2F6F5E) : Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'seed = "$_seed"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 28),
          Text(
            'Classroom defaults',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Bulk-generate from student IDs — good fallback before they customize with avatar_maker.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _demoStudents.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              final id = _demoStudents[index];
              return Column(
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F3EF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: SvgPicture.string(
                          _svgFor(id),
                          width: 72,
                          height: 72,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    id,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Note: each style has its own licence — check before shipping. '
            'Core DiceBear code is MIT.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.label, required this.svg});

  final String label;
  final String svg;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3EF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.string(svg, width: 120, height: 120),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
