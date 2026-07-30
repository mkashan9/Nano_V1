import 'package:avatar_trials/panda/sketchfab_embed_stub.dart'
    if (dart.library.html) 'package:avatar_trials/panda/sketchfab_embed_web.dart'
    as embed;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

enum _DragonView { sketchfabEmbed, localGlb }

/// Trial: shakiller Cute Dragon (Sketchfab) audit + optional CC0 local GLB.
class DragonTrialPage extends StatefulWidget {
  const DragonTrialPage({super.key});

  @override
  State<DragonTrialPage> createState() => _DragonTrialPageState();
}

class _DragonTrialPageState extends State<DragonTrialPage> {
  static const _sketchfabUid = 'df14ec74767c4598920132758dab8a49';
  static const _embedUrl =
      'https://sketchfab.com/models/$_sketchfabUid/embed?autostart=1&ui_theme=dark';
  static const _viewType = 'sketchfab-cute-dragon';

  _DragonView _view = _DragonView.sketchfabEmbed;
  Flutter3DController _controller = Flutter3DController();
  List<String> _available = const [];
  String _status = 'Ready';
  bool _loaded = false;
  String? _currentClip;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      embed.registerSketchfabView(_viewType, _embedUrl);
    }
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
      _status = loaded ? 'Local GLB ready' : 'Loading local GLB…';
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
            ? 'Loaded · no named clips (static mesh or unnamed anim)'
            : 'Loaded · ${list.length} clip(s)';
        if (list.isNotEmpty) {
          _currentClip = list.first;
          _controller.playAnimation(animationName: list.first);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Animation list failed: $e');
    }
  }

  void _switchView(_DragonView view) {
    if (view == _view) return;
    setState(() {
      _view = view;
      if (view == _DragonView.localGlb) {
        _controller.onModelLoaded.removeListener(_onLoadedChanged);
        _controller = Flutter3DController();
        _controller.onModelLoaded.addListener(_onLoadedChanged);
        _loaded = false;
        _available = const [];
        _currentClip = null;
        _status = 'Loading local GLB…';
      } else {
        _status = 'Sketchfab embed';
      }
    });
  }

  Future<void> _playClip(String name) async {
    setState(() {
      _currentClip = name;
      _status = 'Playing $name';
    });
    _controller.playAnimation(animationName: name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cute Orange Dragon'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Target: shakiller Cute Dragon (CC-BY). Strong personality, but Sketchfab '
            'lists only 1 animation and anonymous GLB download is blocked — audit + embed, '
            'with a CC0 Quaternius dragon for local 3D.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('shakiller Sketchfab embed'),
                selected: _view == _DragonView.sketchfabEmbed,
                onSelected: (_) => _switchView(_DragonView.sketchfabEmbed),
              ),
              ChoiceChip(
                label: const Text('Local CC0 dragon GLB'),
                selected: _view == _DragonView.localGlb,
                onSelected: (_) => _switchView(_DragonView.localGlb),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: const Color(0xFF1A1F2C),
              child: SizedBox(
                height: 360,
                child: _view == _DragonView.sketchfabEmbed
                    ? _buildEmbed()
                    : Flutter3DViewer(
                        key: const ValueKey('dragon-local-glb'),
                        controller: _controller,
                        src: 'assets/dragon_cute/quaternius_dragon_cc0.glb',
                        progressBarColor: const Color(0xFF2F6F5E),
                        enableTouch: true,
                        activeGestureInterceptor: true,
                        onLoad: (_) =>
                            setState(() => _status = 'Local GLB loaded'),
                        onError: (e) => setState(() => _status = 'Error: $e'),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (_view == _DragonView.localGlb && _available.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Clips in local GLB',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final clip in _available)
                  ChoiceChip(
                    label: Text(clip),
                    selected: _currentClip == clip,
                    onSelected: _loaded ? (_) => _playClip(clip) : null,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'shakiller asset audit',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _AuditRow(
            tone: _AuditTone.ok,
            title: 'Best visual personality so far',
            detail:
                'Large readable eyes, rounded proportions, memorable orange dragon look '
                '— closest to a warm learning-guide identity.',
          ),
          const _AuditRow(
            tone: _AuditTone.ok,
            title: 'Mobile-friendlier mesh than the panda',
            detail: '~28k triangles / ~14k vertices (vs panda ~229k).',
          ),
          const _AuditRow(
            tone: _AuditTone.warn,
            title: 'Animations listed: 1',
            detail:
                'Sketchfab API animationCount=1. Not enough for correct / wrong / think / '
                'celebrate without retargeting or new clips.',
          ),
          const _AuditRow(
            tone: _AuditTone.warn,
            title: 'Local GLB download gated',
            detail:
                'Free CC-BY, but anonymous download returns 401. Needs Sketchfab login '
                'for .fbx/.glb (~7.7 MB archive).',
          ),
          const _AuditRow(
            tone: _AuditTone.ok,
            title: 'License OK for commercial',
            detail: 'CC Attribution — credit shakiller required.',
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Trial verdict: strong look, weak ready-made emotions. Keep as a '
                'personality shortlist candidate only if you accept Blender/KayKit work. '
                'For ship-soon reactions, Xylo still wins. Next: Quirky Series Animals '
                '(blendshapes + many clips).',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'shakiller: sketchfab.com/3d-models/cute-dragon · '
            'Local stand-in: Quaternius Dragon (CC0) via Poly Pizza.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbed() {
    if (!kIsWeb) {
      return Image.asset(
        'assets/dragon_cute/thumb_1920.jpeg',
        fit: BoxFit.cover,
      );
    }
    return const HtmlElementView(viewType: _viewType);
  }
}

enum _AuditTone { ok, warn }

class _AuditRow extends StatelessWidget {
  const _AuditRow({
    required this.tone,
    required this.title,
    required this.detail,
  });

  final _AuditTone tone;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final color = tone == _AuditTone.ok
        ? const Color(0xFF2F6F5E)
        : const Color(0xFFB45309);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tone == _AuditTone.ok ? Icons.check_circle : Icons.warning_amber,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
