import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/locale_preview_page.dart';

/// QA-05 Urdu / bidirectional layout smoke checklist.
class BidiLayoutAuditPage extends StatefulWidget {
  const BidiLayoutAuditPage({
    super.key,
    this.repository,
    this.locale = NanoAppLocale.ur,
    this.width = BidiLayoutBudgets.smallPhoneWidth,
    this.textScale = BidiLayoutBudgets.textScaleSmoke,
  });

  final BidiLayoutAuditRepository? repository;
  final NanoAppLocale locale;
  final double width;
  final double textScale;

  @override
  State<BidiLayoutAuditPage> createState() => _BidiLayoutAuditPageState();
}

class _BidiLayoutAuditPageState extends State<BidiLayoutAuditPage> {
  NanoViewState _state = const NanoViewLoading();
  BidiLayoutAuditReport? _report;
  late NanoAppLocale _locale;
  late final BidiLayoutAuditRepository _repo;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
    _repo = widget.repository ?? FakeBidiLayoutAuditRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final report = await _repo.loadReport(
        locale: _locale,
        width: widget.width,
        textScale: widget.textScale,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _locale = report.locale;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  IconData _iconFor(BidiLayoutCheckStatus status) {
    return switch (status) {
      BidiLayoutCheckStatus.pass => Icons.translate_outlined,
      BidiLayoutCheckStatus.warn => Icons.warning_amber_outlined,
      BidiLayoutCheckStatus.fail => Icons.error_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoCopy(_locale);
    final theme = Theme.of(context);
    final report = _report;

    return NanoLocaleScope(
      locale: _locale,
      copy: copy,
      child: Directionality(
        textDirection: _locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(title: Text(copy.bidiLayoutAuditTitle)),
          body: NanoViewStateHost(
            state: _state,
            onRetry: _load,
            child: report == null
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.all(NanoSpacing.md),
                    children: [
                      Text(copy.bidiLayoutAuditSubtitle),
                      const SizedBox(height: NanoSpacing.md),
                      Text(
                        report.allPassed
                            ? copy.bidiLayoutAuditAllPassed
                            : copy.bidiLayoutAuditHasFailures(report.failCount),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      Text(
                        'Locale ${_locale.tag} · '
                        '${_locale.isRtl ? 'RTL' : 'LTR'} · '
                        '${widget.width.toStringAsFixed(0)}×'
                        '${BidiLayoutBudgets.smallPhoneHeight.toStringAsFixed(0)}'
                        ' · textScale ${widget.textScale}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: NanoSpacing.md),
                      SegmentedButton<NanoAppLocale>(
                        segments: [
                          ButtonSegment(
                            value: NanoAppLocale.en,
                            label: Text(copy.languageEnglish),
                          ),
                          ButtonSegment(
                            value: NanoAppLocale.ur,
                            label: Text(copy.languageUrdu),
                          ),
                        ],
                        selected: {_locale},
                        onSelectionChanged: (next) {
                          setState(() => _locale = next.first);
                          _load();
                        },
                      ),
                      const SizedBox(height: NanoSpacing.md),
                      Text(
                        copy.sampleSentence,
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
                      FilledButton.tonal(
                        onPressed: _load,
                        child: Text(copy.bidiLayoutAuditRun),
                      ),
                      const SizedBox(height: NanoSpacing.sm),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => NanoLocaleScope(
                                locale: _locale,
                                copy: NanoCopy(_locale),
                                child: Directionality(
                                  textDirection: _locale.isRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  child: const LocalePreviewPage(),
                                ),
                              ),
                            ),
                          );
                        },
                        child: Text(copy.bidiLayoutAuditOpenPreview),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
