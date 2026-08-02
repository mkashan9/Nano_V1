import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/league/presentation/league_challenges_page.dart';

/// LGE-02/03 privacy-safe weekly leaderboard with Challenge CTAs.
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
  String? _busyToken;

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

  Future<void> _challenge(LeagueBoardEntry entry) async {
    final token = entry.targetToken;
    if (token == null || _busyToken != null) return;
    setState(() => _busyToken = token);
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    try {
      await widget.repository.createChallenge(token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.leagueChallengeSent)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send challenge')),
      );
    } finally {
      if (mounted) setState(() => _busyToken = null);
    }
  }

  void _openChallenges() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeagueChallengesPage(repository: widget.repository),
      ),
    );
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
                        onPressed: _openChallenges,
                        child: Text(copy.leagueChallengesTitle),
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
                          subtitle: Text(copy.leagueWeekXp(entry.weekXp)),
                          trailing: entry.canChallenge
                              ? TextButton(
                                  onPressed: _busyToken == entry.targetToken
                                      ? null
                                      : () => _challenge(entry),
                                  child: Text(copy.leagueChallenge),
                                )
                              : null,
                        ),
                  ],
                ],
              ),
      ),
    );
  }
}
