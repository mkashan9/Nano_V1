import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SOC-02/03 inbox: friends, requests, blocks, and weekly ranking.
class FriendsPage extends StatefulWidget {
  const FriendsPage({
    super.key,
    required this.repository,
  });

  final FriendGraphRepository repository;

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  var _loading = true;
  String? _error;
  List<FriendPeer> _friends = const [];
  List<FriendRequest> _requests = const [];
  List<BlockedPeer> _blocks = const [];
  FriendsLeaderboard _board = FriendsLeaderboard.empty;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final friends = await widget.repository.listFriends();
      final requests = await widget.repository.listRequests();
      final blocks = await widget.repository.listBlocks();
      final board = await widget.repository.friendsLeaderboard();
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _requests = requests;
        _blocks = blocks;
        _board = board;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load friends';
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    return Scaffold(
      appBar: AppBar(
        title: Text(copy.friendsTitle),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: copy.friendsTab),
            Tab(text: copy.requestsTab),
            Tab(text: copy.blockedTab),
            Tab(text: copy.rankingTab),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      TextButton(onPressed: _load, child: Text(copy.retryLabel)),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _FriendsList(
                      friends: _friends,
                      copy: copy,
                      busy: _busy,
                      onRemove: (peer) => _run(
                        () => widget.repository.removeFriend(peer.peerToken),
                      ),
                    ),
                    _RequestsList(
                      requests: _requests,
                      copy: copy,
                      busy: _busy,
                      onAccept: (req) => _run(
                        () async {
                          await widget.repository
                              .respond(req.id, accept: true);
                        },
                      ),
                      onDecline: (req) => _run(
                        () async {
                          await widget.repository
                              .respond(req.id, accept: false);
                        },
                      ),
                      onCancel: (req) => _run(
                        () async {
                          await widget.repository.cancel(req.id);
                        },
                      ),
                    ),
                    _BlocksList(
                      blocks: _blocks,
                      copy: copy,
                      busy: _busy,
                      onUnblock: (peer) => _run(
                        () => widget.repository.unblock(peer.peerToken),
                      ),
                    ),
                    _RankingList(board: _board, copy: copy),
                  ],
                ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  const _FriendsList({
    required this.friends,
    required this.copy,
    required this.busy,
    required this.onRemove,
  });

  final List<FriendPeer> friends;
  final NanoCopy copy;
  final bool busy;
  final ValueChanged<FriendPeer> onRemove;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) {
      return Center(child: Text(copy.friendsEmpty));
    }
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final peer = friends[index];
        return ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(peer.peerLabel),
          subtitle: peer.username == null ? null : Text('@${peer.username}'),
          trailing: TextButton(
            onPressed: busy ? null : () => onRemove(peer),
            child: Text(copy.removeFriendLabel),
          ),
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({
    required this.requests,
    required this.copy,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  final List<FriendRequest> requests;
  final NanoCopy copy;
  final bool busy;
  final ValueChanged<FriendRequest> onAccept;
  final ValueChanged<FriendRequest> onDecline;
  final ValueChanged<FriendRequest> onCancel;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(child: Text(copy.requestsEmpty));
    }
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final incoming = req.direction == FriendRequestDirection.incoming;
        return ListTile(
          leading: Icon(
            incoming ? Icons.mark_email_unread_outlined : Icons.outbox_outlined,
          ),
          title: Text(req.peerLabel),
          subtitle: Text(
            incoming ? copy.incomingRequestHint : copy.outgoingRequestHint,
          ),
          trailing: incoming
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: busy ? null : () => onAccept(req),
                      child: Text(copy.acceptRequestLabel),
                    ),
                    TextButton(
                      onPressed: busy ? null : () => onDecline(req),
                      child: Text(copy.declineRequestLabel),
                    ),
                  ],
                )
              : TextButton(
                  onPressed: busy ? null : () => onCancel(req),
                  child: Text(copy.cancelRequestLabel),
                ),
        );
      },
    );
  }
}

class _BlocksList extends StatelessWidget {
  const _BlocksList({
    required this.blocks,
    required this.copy,
    required this.busy,
    required this.onUnblock,
  });

  final List<BlockedPeer> blocks;
  final NanoCopy copy;
  final bool busy;
  final ValueChanged<BlockedPeer> onUnblock;

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return Center(child: Text(copy.blocksEmpty));
    }
    return ListView.builder(
      itemCount: blocks.length,
      itemBuilder: (context, index) {
        final peer = blocks[index];
        return ListTile(
          leading: const Icon(Icons.block),
          title: Text(peer.peerLabel),
          trailing: TextButton(
            onPressed: busy ? null : () => onUnblock(peer),
            child: Text(copy.unblockLabel),
          ),
        );
      },
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({
    required this.board,
    required this.copy,
  });

  final FriendsLeaderboard board;
  final NanoCopy copy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (board.friendCount == 0 && board.entries.length <= 1) {
      return Center(child: Text(copy.friendsRankingEmpty));
    }
    return ListView(
      padding: const EdgeInsets.all(NanoSpacing.md),
      children: [
        Text(
          copy.friendsRankingSubtitle(board.weekKey, board.friendCount),
          style: theme.textTheme.titleMedium,
        ),
        if (board.myRank != null) ...[
          const SizedBox(height: NanoSpacing.sm),
          Text(
            copy.friendsMyRank(board.myRank!, board.myWeekXp),
            style: theme.textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: NanoSpacing.md),
        for (final entry in board.entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(child: Text('#${entry.rank}')),
            title: Text(
              entry.isMe ? '${entry.displayLabel} (you)' : entry.displayLabel,
            ),
            trailing: Text('${entry.weekXp} XP'),
          ),
      ],
    );
  }
}
