import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import 'sketchfab_embed_stub.dart'
    if (dart.library.html) 'sketchfab_embed_web.dart' as embed;

enum _PandaView { mr7Embed, localGlb }

/// Trial: MR7 Cartoon Panda (Sketchfab) audit + optional CC0 local GLB.
class PandaTrialPage extends StatefulWidget {
  const PandaTrialPage({super.key});

  @override
  State<PandaTrialPage> createState() => _PandaTrialPageState();
}

class _PandaTrialPageState extends State<PandaTrialPage> {
  static const _sketchfabUid = 'b9229a00d4084ca0832381cecf970c07';
  static const _embedUrl =
      'https://sketchfab.com/models/$_sketchfabUid/embed?autostart=1&ui_theme=dark';
  static const _viewType = 'sketchfab-panda-mr7';

  _PandaView _view = _PandaView.mr7Embed;
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

  void _switchView(_PandaView view) {
    if (view == _view) return;
    setState(() {
      _view = view;
      if (view == _PandaView.localGlb) {
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
        title: const Text('Cartoon Panda (MR7)'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Text(
            'Target: MR7 Sketchfab panda (CC-BY). Local GLB needs a Sketchfab login, '
            'so this trial audits the listing and offers a CC0 Quaternius panda for local 3D playback.',
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
                label: const Text('MR7 Sketchfab embed'),
                selected: _view == _PandaView.mr7Embed,
                onSelected: (_) => _switchView(_PandaView.mr7Embed),
              ),
              ChoiceChip(
                label: const Text('Local CC0 panda GLB'),
                selected: _view == _PandaView.localGlb,
                onSelected: (_) => _switchView(_PandaView.localGlb),
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
                child: _view == _PandaView.mr7Embed
                    ? _buildEmbed()
                    : Flutter3DViewer(
                        key: const ValueKey('panda-local-glb'),
                        controller: _controller,
                        src: 'assets/panda_mr7/quaternius_panda_cc0.glb',
                        progressBarColor: const Color(0xFF2F6F5E),
                        enableTouch: true,
                        activeGestureInterceptor: true,
                        onLoad: (_) => setState(() => _status = 'Local GLB loaded'),
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
          if (_view == _PandaView.localGlb && _available.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Clips in local GLB', style: Theme.of(context).textTheme.titleMedium),
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
          Text('MR7 asset audit', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const _AuditRow(
            tone: _AuditTone.warn,
            title: 'Animations listed: 1',
            detail:
                'Sketchfab API reports animationCount=1. Not enough moods for '
                'correct / wrong / thinking / celebrate without heavy Blender work '
                '(e.g. KayKit retarget).',
          ),
          const _AuditRow(
            tone: _AuditTone.warn,
            title: 'Mesh is heavy',
            detail: '~229k triangles / ~115k vertices — rough for low-end phones.',
          ),
          const _AuditRow(
            tone: _AuditTone.warn,
            title: 'Local GLB download gated',
            detail:
                'Free CC-BY download exists, but anonymous API returns 401. '
                'Needs a Sketchfab account to pull .glb/.blend.',
          ),
          const _AuditRow(
            tone: _AuditTone.ok,
            title: 'License OK for commercial',
            detail: 'CC Attribution — credit MR7 / Matt.Reardon required.',
          ),
          const _AuditRow(
            tone: _AuditTone.ok,
            title: 'Look & vibe',
            detail:
                'Rounded preschool-friendly panda. Strong visual candidate if '
                'animations can be added later.',
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
                'Trial verdict: pause / likely reject as-is for Nori reactions. '
                'Cute face, but only one listed clip + login-gated source + high poly. '
                'Prefer Xylo (emotions ready) or continue to Orange Dragon / Quirky Animals.',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'MR7: sketchfab.com/3d-models/panda-cartoon-cute-animated-rigged · '
            'Local stand-in: Quaternius Panda (CC0) via Poly Pizza.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmbed() {
    if (!kIsWeb) {
      return Image.asset(
        'assets/panda_mr7/thumb_large.jpeg',
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
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(color: Colors.grey.shade800, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
