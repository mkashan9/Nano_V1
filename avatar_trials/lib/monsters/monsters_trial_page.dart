import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class _MonsterOption {
  const _MonsterOption({
    required this.id,
    required this.label,
    required this.asset,
  });

  final String id;
  final String label;
  final String asset;
}

const _monsters = <_MonsterOption>[
  _MonsterOption(
    id: 'alien',
    label: 'Alien',
    asset: 'assets/monsters/alien.glb',
  ),
  _MonsterOption(
    id: 'cactoro',
    label: 'Cactoro',
    asset: 'assets/monsters/cactoro.glb',
  ),
  _MonsterOption(
    id: 'frog',
    label: 'Frog',
    asset: 'assets/monsters/frog.glb',
  ),
  _MonsterOption(
    id: 'mushnub',
    label: 'Mushnub',
    asset: 'assets/monsters/mushnub.glb',
  ),
  _MonsterOption(
    id: 'green_blob',
    label: 'Green Blob',
    asset: 'assets/monsters/green_blob.glb',
  ),
];

/// Friendly clips shared by Quaternius Ultimate / Cute-style character armatures.
enum MonsterReaction {
  idle('Idle', 'Idle'),
  wave('Wave', 'Wave'),
  yes('Yes', 'Yes'),
  no('No', 'No'),
  dance('Dance', 'Dance'),
  jump('Jump', 'Jump'),
  hitReact('Ouch', 'Hit'),
  walk('Walk', 'Walk'),
  run('Run', 'Run'),
  death('Death', 'Death');

  const MonsterReaction(this.label, this.token);

  final String label;
  final String token;
}

/// Trial B: Quaternius cute animated monsters (CC0) via flutter_3d_controller.
class MonstersTrialPage extends StatefulWidget {
  const MonstersTrialPage({super.key});

  @override
  State<MonstersTrialPage> createState() => _MonstersTrialPageState();
}

class _MonstersTrialPageState extends State<MonstersTrialPage> {
  Flutter3DController _controller = Flutter3DController();
  String _monsterId = _monsters.first.id;
  List<String> _available = const [];
  MonsterReaction _current = MonsterReaction.idle;
  String _status = 'Loading model…';
  bool _loaded = false;
  int _viewerKey = 0;

  String get _src =>
      _monsters.firstWhere((m) => m.id == _monsterId).asset;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  void _bindController() {
    _controller.onModelLoaded.addListener(_onLoadedChanged);
  }

  void _onLoadedChanged() {
    if (!mounted) return;
    final loaded = _controller.onModelLoaded.value;
    setState(() {
      _loaded = loaded;
      _status = loaded ? 'Model ready' : 'Loading model…';
    });
    if (loaded) {
      _refreshAnimations();
    }
  }

  Future<void> _refreshAnimations() async {
    try {
      final list = await _controller.getAvailableAnimations();
      if (!mounted) return;
      setState(() {
        _available = list;
        _status = list.isEmpty
            ? 'Loaded, but no animation names returned'
            : 'Loaded · ${list.length} clips';
      });
      await _play(MonsterReaction.idle, loop: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Animation list failed: $e');
    }
  }

  void _switchMonster(String id) {
    if (id == _monsterId) return;
    _controller.onModelLoaded.removeListener(_onLoadedChanged);
    setState(() {
      _monsterId = id;
      _loaded = false;
      _available = const [];
      _status = 'Loading model…';
      _current = MonsterReaction.idle;
      _viewerKey++;
      _controller = Flutter3DController();
      _bindController();
    });
  }

  String? _resolveClip(MonsterReaction reaction) {
    if (_available.isEmpty) {
      return 'CharacterArmature|${reaction.token}';
    }
    final token = reaction.token.toLowerCase();
    for (final name in _available) {
      final lower = name.toLowerCase();
      if (lower.endsWith('|$token') || lower.endsWith('_$token') || lower == token) {
        return name;
      }
    }
    for (final name in _available) {
      if (name.toLowerCase().contains(token)) return name;
    }
    return null;
  }

  Future<void> _play(MonsterReaction reaction, {bool loop = false}) async {
    final clip = _resolveClip(reaction);
    setState(() {
      _current = reaction;
      _status = clip == null
          ? '${reaction.label} not in this model'
          : 'Playing ${reaction.label}';
    });
    if (clip == null) return;
    if (loop) {
      _controller.playAnimation(animationName: clip);
    } else {
      _controller.playAnimation(animationName: clip, loopCount: 1);
    }
  }

  @override
  void dispose() {
    _controller.onModelLoaded.removeListener(_onLoadedChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cute Animated Monsters'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Quaternius CC0 monsters · pick a character, then tap reactions.\n'
              'These include Wave / Yes / No / HitReact — useful for quiz feedback.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final m in _monsters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(m.label),
                      selected: _monsterId == m.id,
                      onSelected: (_) => _switchMonster(m.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFE8F3EF)),
              child: Flutter3DViewer(
                key: ValueKey('monster-$_viewerKey-$_monsterId'),
                controller: _controller,
                src: _src,
                progressBarColor: const Color(0xFF2F6F5E),
                enableTouch: true,
                activeGestureInterceptor: true,
                onLoad: (address) {
                  setState(() => _status = 'Loaded $address');
                },
                onError: (error) {
                  setState(() => _status = 'Error: $error');
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              'Current: ${_current.label}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 140,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final reaction in MonsterReaction.values)
                    FilledButton.tonal(
                      onPressed: _loaded
                          ? () => _play(
                                reaction,
                                loop: reaction == MonsterReaction.idle ||
                                    reaction == MonsterReaction.walk ||
                                    reaction == MonsterReaction.run,
                              )
                          : null,
                      child: Text(reaction.label),
                    ),
                ],
              ),
            ),
          ),
          if (_available.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
              child: Text(
                'Clips: ${_available.join(', ')}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }
}
