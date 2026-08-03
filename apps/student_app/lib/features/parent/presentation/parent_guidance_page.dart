import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// PAR-01 weekly parent guidance card (student-facing share surface).
class ParentGuidancePage extends StatefulWidget {
  const ParentGuidancePage({
    super.key,
    required this.repository,
    this.childUserId,
  });

  final ParentGuidanceRepository repository;
  final String? childUserId;

  @override
  State<ParentGuidancePage> createState() => _ParentGuidancePageState();
}

class _ParentGuidancePageState extends State<ParentGuidancePage> {
  NanoViewState _state = const NanoViewLoading();
  ParentGuidanceCard? _card;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final card = await widget.repository.loadCurrentCard(
        childUserId: widget.childUserId,
      );
      if (!mounted) return;
      setState(() {
        _card = card;
        _state = card == null
            ? const NanoViewEmpty()
            : const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(
        () => _state = NanoViewError(message: copy.parentGuidanceLoadError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final card = _card;
    return Scaffold(
      appBar: AppBar(title: Text(copy.parentGuidanceTitle)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: card == null
            ? Center(child: Text(copy.parentGuidanceEmpty))
            : ListView(
                padding: const EdgeInsets.all(NanoSpacing.md),
                children: [
                  Text(card.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: NanoSpacing.xs),
                  Text(card.weekKey, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: NanoSpacing.md),
                  Text(card.body),
                  const SizedBox(height: NanoSpacing.md),
                  Text(
                    copy.parentGuidanceTips,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  for (final tip in card.activityTips)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(tip),
                    ),
                  const SizedBox(height: NanoSpacing.lg),
                  Text(
                    copy.parentGuidancePrivacyHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}
