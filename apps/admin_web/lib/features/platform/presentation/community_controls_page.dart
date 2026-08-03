import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SAFE-04 platform emergency kill switch for open Communities.
class CommunityControlsPage extends StatefulWidget {
  const CommunityControlsPage({
    super.key,
    required this.repository,
  });

  final CommunityControlsRepository repository;

  @override
  State<CommunityControlsPage> createState() => _CommunityControlsPageState();
}

class _CommunityControlsPageState extends State<CommunityControlsPage> {
  NanoViewState _state = const NanoViewLoading();
  var _platformEnabled = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final platform = await widget.repository.loadPlatformPolicy();
      if (!mounted) return;
      setState(() {
        _platformEnabled = platform.communitiesEnabled;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _setPlatform(bool value) async {
    setState(() => _busy = true);
    try {
      final saved =
          await widget.repository.savePlatformPolicy(enabled: value);
      if (!mounted) return;
      setState(() => _platformEnabled = saved.communitiesEnabled);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: ListView(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        children: [
          Text(
            copy.platformCommunitiesTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(copy.platformCommunitiesHint),
          const SizedBox(height: NanoSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(copy.platformCommunitiesToggle),
            subtitle: Text(
              _platformEnabled
                  ? copy.platformCommunitiesOn
                  : copy.platformCommunitiesOff,
            ),
            value: _platformEnabled,
            onChanged: _busy ? null : _setPlatform,
          ),
        ],
      ),
    );
  }
}
