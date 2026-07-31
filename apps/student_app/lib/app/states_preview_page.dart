import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// Dev-only catalog of FND-05 view states for owner review.
class StatesPreviewPage extends StatefulWidget {
  const StatesPreviewPage({super.key});

  @override
  State<StatesPreviewPage> createState() => _StatesPreviewPageState();
}

class _StatesPreviewPageState extends State<StatesPreviewPage> {
  late NanoViewState _state = const NanoViewReady();

  static const _options = <(String, NanoViewState)>[
    ('Ready', NanoViewReady()),
    ('Loading', NanoViewLoading()),
    ('Empty', NanoViewEmpty()),
    ('Error', NanoViewError()),
    ('Offline', NanoViewOffline(lastUpdatedLabel: '2 min ago')),
    ('Syncing', NanoViewSyncing()),
    ('Suspended', NanoViewSuspended()),
    ('Maintenance', NanoViewMaintenance()),
    ('Permission denied', NanoViewPermissionDenied()),
    ('Feature disabled', NanoViewFeatureDisabled()),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NanoTheme.junior(),
      child: NanoScaffold(
      padBody: false,
      appBar: AppBar(title: const Text('UI states preview')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(NanoSpacing.sm),
            child: Row(
              children: [
                for (final (label, state) in _options)
                  Padding(
                    padding: const EdgeInsets.only(right: NanoSpacing.sm),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _state.runtimeType == state.runtimeType,
                      onSelected: (_) => setState(() => _state = state),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: NanoViewStateHost(
              state: _state,
              onRetry: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Retry tapped')),
                );
                setState(() => _state = const NanoViewReady());
              },
              child: const _SampleContent(),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _SampleContent extends StatelessWidget {
  const _SampleContent();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(NanoSpacing.md),
      children: [
        Text('Sample learning content', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        const Text(
          'Banners (offline / syncing) keep this content visible. '
          'Blocking states replace it until the user recovers.',
        ),
        const SizedBox(height: NanoSpacing.lg),
        const JuniorActionCard(
          title: 'Math',
          subtitle: 'Visible under non-blocking states',
          backgroundColor: NanoColors.worldMath,
        ),
      ],
    );
  }
}
