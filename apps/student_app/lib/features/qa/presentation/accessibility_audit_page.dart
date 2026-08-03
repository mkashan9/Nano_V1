import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/accessibility_settings_page.dart';

/// QA-04 accessibility smoke checklist.
class AccessibilityAuditPage extends StatefulWidget {
  const AccessibilityAuditPage({
    super.key,
    this.repository,
    this.textScale = AccessibilityAuditBudgets.textScaleSmoke,
    this.preferences = AccessibilityPreferences.defaults,
  });

  final AccessibilityAuditRepository? repository;
  final double textScale;
  final AccessibilityPreferences preferences;

  @override
  State<AccessibilityAuditPage> createState() => _AccessibilityAuditPageState();
}

class _AccessibilityAuditPageState extends State<AccessibilityAuditPage> {
  NanoViewState _state = const NanoViewLoading();
  AccessibilityAuditReport? _report;
  late final AccessibilityAuditRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? FakeAccessibilityAuditRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final report = await _repo.loadReport(
        preferences: widget.preferences.copyWith(textScale: widget.textScale),
        textScale: widget.textScale,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  IconData _iconFor(AccessibilityCheckStatus status) {
    return switch (status) {
      AccessibilityCheckStatus.pass => Icons.accessibility_new_outlined,
      AccessibilityCheckStatus.warn => Icons.warning_amber_outlined,
      AccessibilityCheckStatus.fail => Icons.error_outline,
    };
  }

  void _openSettings() {
    var prefs = widget.preferences;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AccessibilitySettingsHost(
          initial: prefs,
          childBuilder: (current, onChanged) => AccessibilitySettingsPage(
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: Text(copy.accessibilityAuditTitle)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: report == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(NanoSpacing.md),
                children: [
                  Text(copy.accessibilityAuditSubtitle),
                  const SizedBox(height: NanoSpacing.md),
                  Text(
                    report.allPassed
                        ? copy.accessibilityAuditAllPassed
                        : copy.accessibilityAuditHasFailures(report.failCount),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  Text(
                    'textScale ${widget.textScale} · handbook 8.5',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  for (final check in report.checks)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(_iconFor(check.status)),
                      title: Text(check.title),
                      subtitle: Text(check.detail),
                      trailing: Text(check.status.name),
                    ),
                  const SizedBox(height: NanoSpacing.lg),
                  FilledButton.tonal(
                    onPressed: _load,
                    child: Text(copy.accessibilityAuditRun),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  OutlinedButton(
                    onPressed: _openSettings,
                    child: Text(copy.accessibilityAuditOpenSettings),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AccessibilitySettingsHost extends StatefulWidget {
  const _AccessibilitySettingsHost({
    required this.initial,
    required this.childBuilder,
  });

  final AccessibilityPreferences initial;
  final Widget Function(
    AccessibilityPreferences preferences,
    ValueChanged<AccessibilityPreferences> onChanged,
  ) childBuilder;

  @override
  State<_AccessibilitySettingsHost> createState() =>
      _AccessibilitySettingsHostState();
}

class _AccessibilitySettingsHostState extends State<_AccessibilitySettingsHost> {
  late AccessibilityPreferences _prefs;
  late NanoFeedback _feedback;

  @override
  void initState() {
    super.initState();
    _prefs = widget.initial;
    _feedback = NanoFeedback(preferences: _prefs);
  }

  @override
  Widget build(BuildContext context) {
    return NanoAccessibilityScope(
      preferences: _prefs,
      feedback: _feedback,
      child: widget.childBuilder(_prefs, (next) {
        setState(() {
          _prefs = next;
          _feedback.updatePreferences(next);
        });
      }),
    );
  }
}
