import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// LGE-03 inbox for pending / active / completed league challenges.
class LeagueChallengesPage extends StatefulWidget {
  const LeagueChallengesPage({
    super.key,
    required this.repository,
  });

  final LeagueRepository repository;

  @override
  State<LeagueChallengesPage> createState() => _LeagueChallengesPageState();
}

class _LeagueChallengesPageState extends State<LeagueChallengesPage> {
  NanoViewState _state = const NanoViewLoading();
  List<LeagueChallenge> _items = const [];
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final items = await widget.repository.listChallenges();
      if (!mounted) return;
      setState(() {
        _items = items;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _run(
    String id,
    Future<LeagueChallenge> Function() action,
  ) async {
    if (_busyId != null) return;
    setState(() => _busyId = id);
    try {
      await action();
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update challenge')),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    copy.leagueChallengesTitle,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(copy.gamesClose),
                ),
              ],
            ),
            const SizedBox(height: NanoSpacing.sm),
            Text(
              copy.leagueBoardSoftHint,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: NanoSpacing.md),
            if (_items.isEmpty)
              Text(copy.leagueChallengesEmpty)
            else
              for (final item in _items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${item.titleFor(urdu: copy.isUrdu)} · ${item.peerLabel}',
                  ),
                  subtitle: Text(
                    [
                      item.status.wire,
                      if (item.myScore != null) 'you ${item.myScore}',
                      if (item.peerScore != null) 'peer ${item.peerScore}',
                      if (item.outcome != null) item.outcome!.name,
                    ].join(' · '),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      if (item.canRespond) ...[
                        TextButton(
                          onPressed: _busyId == item.id
                              ? null
                              : () => _run(
                                    item.id,
                                    () => widget.repository.respondChallenge(
                                      challengeId: item.id,
                                      accept: true,
                                    ),
                                  ),
                          child: Text(copy.leagueChallengeAccept),
                        ),
                        TextButton(
                          onPressed: _busyId == item.id
                              ? null
                              : () => _run(
                                    item.id,
                                    () => widget.repository.respondChallenge(
                                      challengeId: item.id,
                                      accept: false,
                                    ),
                                  ),
                          child: Text(copy.leagueChallengeDecline),
                        ),
                      ],
                      if (item.canRecordScore)
                        TextButton(
                          onPressed: _busyId == item.id
                              ? null
                              : () => _run(
                                    item.id,
                                    () => widget.repository
                                        .recordChallengeScore(item.id),
                                  ),
                          child: Text(copy.leagueChallengeRecord),
                        ),
                      if (item.canRematch)
                        TextButton(
                          onPressed: _busyId == item.id
                              ? null
                              : () => _run(
                                    item.id,
                                    () => widget.repository
                                        .createRematch(item.id),
                                  ),
                          child: Text(copy.leagueChallengeRematch),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
