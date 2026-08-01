import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SCH-06 Settings tab: marks policy + result periods.
class SchoolMarksPoliciesPage extends StatefulWidget {
  const SchoolMarksPoliciesPage({
    super.key,
    required this.repository,
  });

  final SchoolMarksPolicyRepository repository;

  @override
  State<SchoolMarksPoliciesPage> createState() =>
      _SchoolMarksPoliciesPageState();
}

class _SchoolMarksPoliciesPageState extends State<SchoolMarksPoliciesPage> {
  NanoViewState _state = const NanoViewLoading();
  SchoolMarksPolicy? _policy;
  var _busy = false;
  String _attendanceMode = 'daily';
  String _reportFormat = 'both';
  var _allowBonus = false;
  final _passing = TextEditingController(text: '40');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _passing.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final policy = await widget.repository.load();
      if (!mounted) return;
      _attendanceMode = policy.attendanceMode;
      _reportFormat = policy.reportCardFormat;
      _allowBonus = policy.allowBonus;
      _passing.text = policy.passingPercent.toStringAsFixed(
        policy.passingPercent == policy.passingPercent.roundToDouble() ? 0 : 1,
      );
      setState(() {
        _policy = policy;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _save() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() => _busy = true);
    try {
      final percent = double.tryParse(_passing.text.trim());
      if (percent == null) throw StateError('Passing percent must be a number.');
      final next = await widget.repository.save(
        attendanceMode: _attendanceMode,
        passingPercent: percent,
        allowBonus: _allowBonus,
        reportCardFormat: _reportFormat,
      );
      if (!mounted) return;
      setState(() {
        _policy = next;
        _state = const NanoViewReady();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.policiesSaved)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPeriod() async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.policiesCreatePeriodTitle),
          content: TextField(
            controller: name,
            decoration: InputDecoration(labelText: copy.policiesPeriodNameLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.policiesCreatePeriodAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = await widget.repository.createPeriod(name: name.text);
      if (!mounted) return;
      setState(() => _policy = next);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      name.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closePeriod(ResultPeriod period) async {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(copy.policiesClosePeriodTitle),
          content: TextField(
            controller: reason,
            decoration: InputDecoration(labelText: copy.policiesReasonLabel),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(copy.policiesConfirmAction),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final next = await widget.repository.closePeriod(
        periodId: period.id,
        reason: reason.text,
      );
      if (!mounted) return;
      setState(() => _policy = next);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      reason.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final policy = _policy;

    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
          Text(copy.policiesPageTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(copy.policiesPageSubtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _attendanceMode,
            decoration: InputDecoration(labelText: copy.policiesAttendanceLabel),
            items: [
              DropdownMenuItem(
                value: 'daily',
                child: Text(copy.policiesAttendanceDaily),
              ),
              DropdownMenuItem(
                value: 'session',
                child: Text(copy.policiesAttendanceSession),
              ),
            ],
            onChanged: _busy
                ? null
                : (v) {
                    if (v != null) setState(() => _attendanceMode = v);
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passing,
            enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: copy.policiesPassingLabel),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _reportFormat,
            decoration: InputDecoration(labelText: copy.policiesReportFormatLabel),
            items: [
              DropdownMenuItem(
                value: 'percent',
                child: Text(copy.policiesFormatPercent),
              ),
              DropdownMenuItem(
                value: 'grade',
                child: Text(copy.policiesFormatGrade),
              ),
              DropdownMenuItem(
                value: 'both',
                child: Text(copy.policiesFormatBoth),
              ),
            ],
            onChanged: _busy
                ? null
                : (v) {
                    if (v != null) setState(() => _reportFormat = v);
                  },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(copy.policiesAllowBonusLabel),
            value: _allowBonus,
            onChanged: _busy
                ? null
                : (v) => setState(() => _allowBonus = v),
          ),
          if (policy != null) ...[
            const SizedBox(height: 8),
            Text(copy.policiesGradeBandsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              [
                for (final b in policy.gradeBands)
                  '${b.label} ≥ ${b.min.toStringAsFixed(0)}%',
              ].join(' · '),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(copy.policiesSaveAction),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Text(
                  copy.policiesPeriodsTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              FilledButton.tonal(
                onPressed: _busy ? null : _createPeriod,
                child: Text(copy.policiesCreatePeriodAction),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (policy == null || policy.periods.isEmpty)
            Text(copy.policiesPeriodsEmpty)
          else
            for (final period in policy.periods)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(period.name),
                  subtitle: Text(
                    [
                      period.status,
                      if (period.startsOn != null) period.startsOn!,
                      if (period.endsOn != null) '→ ${period.endsOn}',
                    ].join(' · '),
                  ),
                  trailing: period.isOpen
                      ? TextButton(
                          onPressed: _busy ? null : () => _closePeriod(period),
                          child: Text(copy.policiesClosePeriodAction),
                        )
                      : null,
                ),
              ),
        ],
        ),
      ),
    );
  }
}
