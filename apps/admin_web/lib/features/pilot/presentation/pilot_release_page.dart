import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// QA-06 pilot release readiness checklist for platform staff.
class PilotReleasePage extends StatefulWidget {
  const PilotReleasePage({
    super.key,
    required this.config,
    this.repository,
    this.gates = PilotReleaseGates.pilotReady,
  });

  final EnvironmentConfig config;
  final PilotReleaseRepository? repository;
  final PilotReleaseGates gates;

  @override
  State<PilotReleasePage> createState() => _PilotReleasePageState();
}

class _PilotReleasePageState extends State<PilotReleasePage> {
  NanoViewState _state = const NanoViewLoading();
  PilotReleaseReport? _report;
  late final PilotReleaseRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? FakePilotReleaseRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final report = await _repo.loadReport(
        gates: widget.gates,
        config: widget.config,
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

  IconData _iconFor(PilotReleaseCheckStatus status) {
    return switch (status) {
      PilotReleaseCheckStatus.pass => Icons.rocket_launch_outlined,
      PilotReleaseCheckStatus.warn => Icons.warning_amber_outlined,
      PilotReleaseCheckStatus.fail => Icons.error_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final report = _report;

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: report == null
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(
                    children: [
                      Text(
                        copy.pilotReleaseTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: NanoSpacing.xs),
                      Text(
                        copy.pilotReleaseSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: NanoSpacing.md),
                      Text(
                        report.allPassed
                            ? copy.pilotReleaseAllPassed
                            : copy.pilotReleaseHasFailures(report.failCount),
                        style: theme.textTheme.titleMedium,
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
                      OutlinedButton(
                        onPressed: _load,
                        child: Text(copy.pilotReleaseRun),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
