import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// QA-02 performance and small-device smoke checklist.
class PerformanceAuditPage extends StatefulWidget {
  const PerformanceAuditPage({
    super.key,
    this.repository,
    this.width = PerformanceViewports.smallPhoneWidth,
    this.textScale = PerformanceViewports.textScaleSmoke,
  });

  final PerformanceAuditRepository? repository;
  final double width;
  final double textScale;

  @override
  State<PerformanceAuditPage> createState() => _PerformanceAuditPageState();
}

class _PerformanceAuditPageState extends State<PerformanceAuditPage> {
  NanoViewState _state = const NanoViewLoading();
  PerformanceAuditReport? _report;
  late final PerformanceAuditRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? FakePerformanceAuditRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final report = await _repo.loadReport(
        width: widget.width,
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

  IconData _iconFor(PerformanceCheckStatus status) {
    return switch (status) {
      PerformanceCheckStatus.pass => Icons.speed_outlined,
      PerformanceCheckStatus.warn => Icons.warning_amber_outlined,
      PerformanceCheckStatus.fail => Icons.error_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: Text(copy.performanceAuditTitle)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: report == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(NanoSpacing.md),
                children: [
                  Text(copy.performanceAuditSubtitle),
                  const SizedBox(height: NanoSpacing.md),
                  Text(
                    report.allPassed
                        ? copy.performanceAuditAllPassed
                        : copy.performanceAuditHasFailures(report.failCount),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  Text(
                    'Viewport ${widget.width.toStringAsFixed(0)}×'
                    '${PerformanceViewports.smallPhoneHeight.toStringAsFixed(0)}'
                    ' · textScale ${widget.textScale}',
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
                    child: Text(copy.performanceAuditRun),
                  ),
                ],
              ),
      ),
    );
  }
}
