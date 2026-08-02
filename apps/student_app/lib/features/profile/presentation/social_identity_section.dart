import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/friends_page.dart';

/// SOC-01/02: claim username, friend code, lookup, request, and open Friends.
class SocialIdentitySection extends StatefulWidget {
  const SocialIdentitySection({
    super.key,
    required this.repository,
    required this.copy,
    this.friendGraph,
  });

  final SocialIdentityRepository repository;
  final NanoCopy copy;
  final FriendGraphRepository? friendGraph;

  @override
  State<SocialIdentitySection> createState() => _SocialIdentitySectionState();
}

class _SocialIdentitySectionState extends State<SocialIdentitySection> {
  SocialIdentity? _identity;
  var _loading = true;
  var _busy = false;
  String? _error;
  final _usernameCtrl = TextEditingController();
  final _lookupCtrl = TextEditingController();
  LimitedProfile? _lookupResult;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _lookupCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final mine = await widget.repository.loadMine();
      if (!mounted) return;
      setState(() {
        _identity = mine;
        _usernameCtrl.text = mine.username ?? '';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load social identity';
      });
    }
  }

  Future<void> _claim() async {
    final raw = _usernameCtrl.text;
    final policyError = UsernamePolicy.validate(raw);
    if (policyError != null) {
      setState(() => _error = policyError);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = await widget.repository.claimUsername(raw);
      if (!mounted) return;
      setState(() {
        _identity = next;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _rotate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = await widget.repository.rotateFriendCode();
      if (!mounted) return;
      setState(() {
        _identity = next;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not rotate friend code';
      });
    }
  }

  Future<void> _copyCode() async {
    final code = _identity?.friendCode;
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.copy.friendCodeCopiedSnack)),
    );
  }

  Future<void> _lookup() async {
    setState(() {
      _busy = true;
      _error = null;
      _lookupResult = null;
    });
    try {
      final found = await widget.repository.lookup(_lookupCtrl.text);
      if (!mounted) return;
      setState(() {
        _lookupResult = found;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'No discoverable profile found.';
      });
    }
  }

  Future<void> _sendRequest() async {
    final graph = widget.friendGraph;
    final query = _lookupCtrl.text.trim();
    if (graph == null || query.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await graph.sendRequest(query);
      final found = await widget.repository.lookup(query);
      if (!mounted) return;
      setState(() {
        _lookupResult = found;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.copy.requestSentLabel)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _blockLookup() async {
    final graph = widget.friendGraph;
    final query = _lookupCtrl.text.trim();
    if (graph == null || query.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await graph.blockUser(query);
      if (!mounted) return;
      setState(() {
        _lookupResult = null;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Could not block';
      });
    }
  }

  void _openFriends() {
    final graph = widget.friendGraph;
    if (graph == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendsPage(repository: graph),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final copy = widget.copy;
    final identity = _identity;
    final lookup = _lookupResult;
    final graph = widget.friendGraph;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.socialIdentityLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        if (graph != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _openFriends,
              child: Text(copy.openFriendsLabel),
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: NanoSpacing.md),
            child: LinearProgressIndicator(),
          )
        else ...[
          TextField(
            controller: _usernameCtrl,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: copy.usernameLabel,
              hintText: copy.usernameHint,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _claim(),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _busy ? null : _claim,
              child: Text(copy.claimUsernameLabel),
            ),
          ),
          if (identity != null) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.qr_code_2_outlined),
              title: Text(copy.friendCodeLabel),
              subtitle: Text(identity.friendCode),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _busy ? null : _copyCode,
                    child: Text(copy.copyFriendCodeLabel),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _rotate,
                    child: Text(copy.rotateFriendCodeLabel),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: NanoSpacing.sm),
          Text(copy.findFriendsLabel, style: theme.textTheme.titleMedium),
          TextField(
            controller: _lookupCtrl,
            enabled: !_busy,
            decoration: InputDecoration(
              labelText: copy.findFriendsHint,
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _lookup(),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: _busy ? null : _lookup,
              child: Text(copy.lookupProfileLabel),
            ),
          ),
          if (lookup != null) ...[
            const SizedBox(height: NanoSpacing.sm),
            Text(copy.limitedProfileTitle, style: theme.textTheme.titleMedium),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(lookup.socialLabel),
              subtitle: Text(
                [
                  copy.levelLabel(lookup.level),
                  if (lookup.companionName != null) lookup.companionName!,
                  lookup.acceptsFriendRequests
                      ? copy.acceptsRequestsLabel
                      : copy.noRequestsLabel,
                  if (lookup.alreadyFriends) copy.alreadyFriendsLabel,
                ].join(' · '),
              ),
            ),
            for (final title in lookup.achievementTitles)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.emoji_events_outlined, size: 20),
                title: Text(title),
              ),
            if (graph != null)
              Row(
                children: [
                  if (!lookup.alreadyFriends &&
                      !lookup.pendingOutgoing &&
                      lookup.acceptsFriendRequests)
                    TextButton(
                      onPressed: _busy ? null : _sendRequest,
                      child: Text(copy.sendFriendRequestLabel),
                    ),
                  if (lookup.pendingOutgoing)
                    Text(copy.requestSentLabel, style: theme.textTheme.bodySmall),
                  TextButton(
                    onPressed: _busy ? null : _blockLookup,
                    child: Text(copy.blockUserLabel),
                  ),
                ],
              ),
          ],
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: NanoSpacing.sm),
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: NanoSpacing.md),
      ],
    );
  }
}
