import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class _QuirkyAnimal {
  const _QuirkyAnimal({
    required this.id,
    required this.label,
    required this.asset,
  });

  final String id;
  final String label;
  final String asset;
}

const _animals = <_QuirkyAnimal>[
  _QuirkyAnimal(
    id: 'pudu',
    label: 'Pudu',
    asset: 'assets/quirky_animals/models/Pudu_Animations.glb',
  ),
  _QuirkyAnimal(
    id: 'sparrow',
    label: 'Sparrow',
    asset: 'assets/quirky_animals/models/Sparrow_Animations.glb',
  ),
  _QuirkyAnimal(
    id: 'muskrat',
    label: 'Muskrat',
    asset: 'assets/quirky_animals/models/Muskrat_Animations.glb',
  ),
  _QuirkyAnimal(
    id: 'colobus',
    label: 'Colobus',
    asset: 'assets/quirky_animals/models/Colobus_Animations.glb',
  ),
  _QuirkyAnimal(
    id: 'gecko',
    label: 'Gecko',
    asset: 'assets/quirky_animals/models/Gecko_Animations.glb',
  ),
  _QuirkyAnimal(
    id: 'inkfish',
    label: 'Inkfish',
    asset: 'assets/quirky_animals/models/Inkfish_Animations.glb',
  ),
  _QuirkyAnimal(
    id: 'herring',
    label: 'Herring',
    asset: 'assets/quirky_animals/models/Herring_Animations.glb',
  ),
  _QuirkyAnimal(
    id: 'taipan',
    label: 'Taipan',
    asset: 'assets/quirky_animals/models/Taipan_Animations.glb',
  ),
];

/// App-event reactions mapped to Quirky Series clip names.
enum QuirkyReaction {
  idle('Idle', 'Idle_A', loop: true),
  idleB('Idle B', 'Idle_B', loop: true),
  idleC('Idle C', 'Idle_C', loop: true),
  correct('Correct', 'Bounce'),
  celebrate('Celebrate', 'Spin'),
  tap('Tap mascot', 'Clicked'),
  jump('Jump', 'Jump'),
  fear('Surprise', 'Fear'),
  wrong('Wrong', 'Sit'),
  struggle('Struggle', 'Hit'),
  eat('Reward snack', 'Eat'),
  walk('Walk-in', 'Walk', loop: true),
  run('Excited run', 'Run', loop: true),
  swim('Swim', 'Swim', loop: true),
  fly('Fly', 'Fly', loop: true),
  roll('Roll', 'Roll'),
  attack('Attack', 'Attack'),
  death('KO', 'Death');

  const QuirkyReaction(this.label, this.clipHint, {this.loop = false});

  final String label;
  final String clipHint;
  final bool loop;
}

/// Trial: Omabuarts Quirky Series FREE Animals — 18 clips + local GLB.
class QuirkyAnimalsTrialPage extends StatefulWidget {
  const QuirkyAnimalsTrialPage({super.key});

  @override
  State<QuirkyAnimalsTrialPage> createState() => _QuirkyAnimalsTrialPageState();
}

class _QuirkyAnimalsTrialPageState extends State<QuirkyAnimalsTrialPage> {
  Flutter3DController _controller = Flutter3DController();
  _QuirkyAnimal _animal = _animals.first;
  List<String> _available = const [];
  QuirkyReaction _current = QuirkyReaction.idle;
  String _status = 'Loading model…';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller.onModelLoaded.addListener(_onLoadedChanged);
  }

  @override
  void dispose() {
    _controller.onModelLoaded.removeListener(_onLoadedChanged);
    super.dispose();
  }

  void _onLoadedChanged() {
    if (!mounted) return;
    final loaded = _controller.onModelLoaded.value;
    setState(() {
      _loaded = loaded;
      _status = loaded ? 'Model ready' : 'Loading model…';
    });
    if (loaded) _refreshAnimations();
  }

  Future<void> _refreshAnimations() async {
    try {
      final list = await _controller.getAvailableAnimations();
      if (!mounted) return;
      setState(() {
        _available = list;
        _status = list.isEmpty
            ? 'Loaded, but no animation names returned'
            : 'Loaded · ${list.length} clips · ${_animal.label}';
      });
      await _play(QuirkyReaction.idle);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Animation list failed: $e');
    }
  }

  void _selectAnimal(_QuirkyAnimal animal) {
    if (animal.id == _animal.id) return;
    setState(() {
      _animal = animal;
      _controller.onModelLoaded.removeListener(_onLoadedChanged);
      _controller = Flutter3DController();
      _controller.onModelLoaded.addListener(_onLoadedChanged);
      _loaded = false;
      _available = const [];
      _status = 'Loading ${_animal.label}…';
      _current = QuirkyReaction.idle;
    });
  }

  Future<void> _play(QuirkyReaction reaction) async {
    setState(() {
      _current = reaction;
      _status = 'Playing ${reaction.label}';
    });
    var name = reaction.clipHint;
    if (_available.isNotEmpty) {
      final hint = reaction.clipHint.toLowerCase();
      final exact = _available.where((a) => a.toLowerCase() == hint);
      if (exact.isNotEmpty) {
        name = exact.first;
      } else {
        final soft = _available.where(
          (a) => a.toLowerCase().contains(hint),
        );
        name = soft.isNotEmpty ? soft.first : _available.first;
      }
    }
    if (reaction.loop) {
      _controller.playAnimation(animationName: name);
    } else {
      _controller.playAnimation(animationName: name, loopCount: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quirky Series Animals'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Omabuarts FREE pack · 8 animals · 18 body clips · CC-BY.\n'
              'Blendshapes ship in source; this trial drives named body animations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
          ),
          Text(_status, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final animal in _animals)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(animal.label),
                      selected: _animal.id == animal.id,
                      onSelected: (_) => _selectAnimal(animal),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFE8F3EF)),
              child: Flutter3DViewer(
                key: ValueKey(_animal.asset),
                controller: _controller,
                src: _animal.asset,
                progressBarColor: const Color(0xFF2F6F5E),
                enableTouch: true,
                activeGestureInterceptor: true,
                onLoad: (_) => setState(
                  () => _status = 'Loaded ${_animal.label}',
                ),
                onError: (error) => setState(() => _status = 'Error: $error'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Text(
              'App event · ${_current.label}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 156,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final reaction in QuirkyReaction.values)
                    FilledButton.tonal(
                      onPressed: _loaded ? () => _play(reaction) : null,
                      child: Text(reaction.label),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE7F6EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Verdict: strongest technical system for reactions (jump/fear/sit/'
                  'bounce/click/idles). Character cast is quirky-not-preschool; '
                  'retexture or buy a cuter animal from the same series if look matters.',
                  style: TextStyle(height: 1.35),
                ),
              ),
            ),
          ),
          if (_available.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
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
