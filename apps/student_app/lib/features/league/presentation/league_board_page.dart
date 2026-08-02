import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// LGE-02 privacy-safe weekly leaderboard for the caller's pool.
class LeagueBoardPage extends StatefulWidget {
  const LeagueBoardPage({
    super.key,
    required this.repository,
  });

  final LeagueRepository repository;

  @override
  State<LeagueBoardPage> createState() => _LeagueBoardPageState();
}

class _LeagueBoardPageState extends State<LeagueBoardPage> {
  NanoViewState _state = const NanoViewLoading();
  LeagueBoard? _board;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final board = await widget.repository.leaderboard();
      if (!mounted) return;
      setState(() {
        _board = board;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final board = _board;
    final theme = Theme.of(context);
    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: board == null
            ? const SizedBox.shrink()
            : ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          copy.leagueBoardTitle,
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
                  if (!board.joined) ...[
                    const SizedBox(height: NanoSpacing.lg),
                    Text(copy.leagueMustJoin),
                  ] else ...[
                    const SizedBox(height: NanoSpacing.sm),
                    Text(
                      [
                        board.divisionTitleFor(urdu: copy.isUrdu),
                        board.weekKey,
                        if (board.myRank != null)
                          copy.leagueDivisionRank(
                            board.divisionTitleFor(urdu: copy.isUrdu),
                            board.myRank!,
                            board.entries.length,
                          ),
                      ].join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: NanoSpacing.md),
                    if (board.entries.isEmpty)
                      Text(copy.leagueBoardEmpty)
                    else
                      for (final entry in board.entries)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            '#${entry.rank}',
                            style: theme.textTheme.titleMedium,
                          ),
                          title: Text(
                            entry.isMe
                                ? '${entry.displayLabel} (you)'
                                : entry.displayLabel,
                          ),
                          trailing: Text(copy.leagueWeekXp(entry.weekXp)),
                        ),
                  ],
                ],
              ),
      ),
    );
  }
}
