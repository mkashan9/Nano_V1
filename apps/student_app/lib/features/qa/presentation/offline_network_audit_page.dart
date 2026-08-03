import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/sync_preview_page.dart';

/// QA-03 offline / poor-network smoke checklist.
class OfflineNetworkAuditPage extends StatefulWidget {
  const OfflineNetworkAuditPage({
    super.key,
    this.repository,
    this.quality = NetworkQuality.offline,
    this.latencyMs,
  });

  final OfflineNetworkAuditRepository? repository;
  final NetworkQuality quality;
  final int? latencyMs;

  @override
  State<OfflineNetworkAuditPage> createState() =>
      _OfflineNetworkAuditPageState();
}

class _OfflineNetworkAuditPageState extends State<OfflineNetworkAuditPage> {
  NanoViewState _state = const NanoViewLoading();
  OfflineNetworkAuditReport? _report;
  late NetworkQuality _quality;
  late final OfflineNetworkAuditRepository _repo;

  @override
  void initState() {
    super.initState();
    _quality = widget.quality;
    _repo = widget.repository ?? FakeOfflineNetworkAuditRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final report = await _repo.loadReport(
        quality: _quality,
        latencyMs: widget.latencyMs,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _quality = report.quality;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  String _qualityLabel(NanoCopy copy, NetworkQuality quality) {
    return switch (quality) {
      NetworkQuality.offline => copy.offlineNetworkQualityOffline,
      NetworkQuality.poor => copy.offlineNetworkQualityPoor,
      NetworkQuality.ok => copy.offlineNetworkQualityOk,
    };
  }

  IconData _iconFor(OfflineNetworkCheckStatus status) {
    return switch (status) {
      OfflineNetworkCheckStatus.pass => Icons.cloud_off_outlined,
      OfflineNetworkCheckStatus.warn => Icons.warning_amber_outlined,
      OfflineNetworkCheckStatus.fail => Icons.error_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: Text(copy.offlineNetworkAuditTitle)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: report == null
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.all(NanoSpacing.md),
                children: [
                  if (NetworkQualityPolicy.shouldShowOfflineChrome(_quality))
                    const NanoOfflineBanner(),
                  if (NetworkQualityPolicy.shouldShowOfflineChrome(_quality))
                    const SizedBox(height: NanoSpacing.sm),
                  Text(copy.offlineNetworkAuditSubtitle),
                  const SizedBox(height: NanoSpacing.md),
                  Text(
                    report.allPassed
                        ? copy.offlineNetworkAuditAllPassed
                        : copy.offlineNetworkAuditHasFailures(report.failCount),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  Text(
                    'Network: ${_qualityLabel(copy, _quality)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  SegmentedButton<NetworkQuality>(
                    segments: [
                      ButtonSegment(
                        value: NetworkQuality.offline,
                        label: Text(copy.offlineNetworkQualityOffline),
                      ),
                      ButtonSegment(
                        value: NetworkQuality.poor,
                        label: Text(copy.offlineNetworkQualityPoor),
                      ),
                      ButtonSegment(
                        value: NetworkQuality.ok,
                        label: Text(copy.offlineNetworkQualityOk),
                      ),
                    ],
                    selected: {_quality},
                    onSelectionChanged: (next) {
                      setState(() => _quality = next.first);
                      _load();
                    },
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
                    child: Text(copy.offlineNetworkAuditRun),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SyncPreviewPage(),
                        ),
                      );
                    },
                    child: Text(copy.offlineNetworkAuditOpenSync),
                  ),
                ],
              ),
      ),
    );
  }
}
