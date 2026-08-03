import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SAFE-04 Settings tab: school communities opt-in (default off).
class SchoolCommunitiesSettingsPage extends StatefulWidget {
  const SchoolCommunitiesSettingsPage({
    super.key,
    required this.repository,
    required this.schoolId,
  });

  final CommunityControlsRepository repository;
  final String schoolId;

  @override
  State<SchoolCommunitiesSettingsPage> createState() =>
      _SchoolCommunitiesSettingsPageState();
}

class _SchoolCommunitiesSettingsPageState
    extends State<SchoolCommunitiesSettingsPage> {
  NanoViewState _state = const NanoViewLoading();
  var _enabled = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final policy = await widget.repository.loadSchoolPolicy(widget.schoolId);
      if (!mounted) return;
      setState(() {
        _enabled = policy.communitiesEnabled;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() => _busy = true);
    try {
      final saved = await widget.repository.saveSchoolPolicy(
        schoolId: widget.schoolId,
        enabled: value,
      );
      if (!mounted) return;
      setState(() => _enabled = saved.communitiesEnabled);
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
            copy.schoolCommunitiesTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: NanoSpacing.sm),
          Text(copy.schoolCommunitiesHint),
          const SizedBox(height: NanoSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(copy.schoolCommunitiesToggle),
            subtitle: Text(
              _enabled
                  ? copy.schoolCommunitiesOn
                  : copy.schoolCommunitiesOff,
            ),
            value: _enabled,
            onChanged: _busy ? null : _toggle,
          ),
        ],
      ),
    );
  }
}
