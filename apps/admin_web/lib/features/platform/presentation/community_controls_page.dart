import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SAFE-04 platform hub: global switch + per-school overrides.
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
  var _platformEnabled = false;
  List<SchoolCommunityPolicy> _schools = const [];
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
      final schools = await widget.repository.listSchoolPolicies();
      if (!mounted) return;
      setState(() {
        _platformEnabled = platform.communitiesEnabled;
        _schools = schools;
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

  Future<void> _setSchool(SchoolCommunityPolicy school, bool value) async {
    setState(() => _busy = true);
    try {
      final saved = await widget.repository.saveSchoolPolicy(
        schoolId: school.schoolId,
        enabled: value,
      );
      if (!mounted) return;
      setState(() {
        _schools = [
          for (final item in _schools)
            if (item.schoolId == school.schoolId)
              SchoolCommunityPolicy(
                schoolId: saved.schoolId,
                schoolName: item.schoolName,
                communitiesEnabled: saved.communitiesEnabled,
                updatedAt: saved.updatedAt,
                updatedBy: saved.updatedBy,
              )
            else
              item,
        ];
      });
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
          const SizedBox(height: NanoSpacing.xl),
          Text(
            copy.platformCommunitiesSchoolsHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: NanoSpacing.sm),
          if (_schools.isEmpty)
            Text(copy.platformCommunitiesNoSchools)
          else
            for (final school in _schools)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(school.schoolName ?? school.schoolId),
                subtitle: Text(
                  school.communitiesEnabled
                      ? copy.schoolCommunitiesOn
                      : copy.schoolCommunitiesOff,
                ),
                value: school.communitiesEnabled,
                onChanged: _busy
                    ? null
                    : (value) => _setSchool(school, value),
              ),
        ],
      ),
    );
  }
}
