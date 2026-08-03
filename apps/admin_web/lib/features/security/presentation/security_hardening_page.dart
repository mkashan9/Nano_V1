import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// QA-01 security hardening checklist for platform staff.
class SecurityHardeningPage extends StatefulWidget {
  const SecurityHardeningPage({
    super.key,
    required this.config,
    required this.principal,
    this.repository,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final SecurityHardeningRepository? repository;

  @override
  State<SecurityHardeningPage> createState() => _SecurityHardeningPageState();
}

class _SecurityHardeningPageState extends State<SecurityHardeningPage> {
  NanoViewState _state = const NanoViewLoading();
  SecurityHardeningReport? _report;
  late final SecurityHardeningRepository _repo;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? FakeSecurityHardeningRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final report = await _repo.loadReport(
        config: widget.config,
        principal: widget.principal,
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

  IconData _iconFor(SecurityCheckStatus status) {
    return switch (status) {
      SecurityCheckStatus.pass => Icons.verified_user_outlined,
      SecurityCheckStatus.warn => Icons.warning_amber_outlined,
      SecurityCheckStatus.fail => Icons.gpp_bad_outlined,
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
                        copy.securityHardeningTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: NanoSpacing.xs),
                      Text(
                        copy.securityHardeningSubtitle,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: NanoSpacing.md),
                      Text(
                        report.allPassed
                            ? copy.securityHardeningAllPassed
                            : copy.securityHardeningHasFailures(
                                report.failCount,
                              ),
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
                        child: Text(copy.tryAgain),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
