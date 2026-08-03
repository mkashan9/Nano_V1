import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// COM-04 community text chat: messages, replies, mentions, reactions.
class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.messagingRepository,
    this.discoveryRepository,
  });

  final String communityId;
  final String communityName;
  final CommunityMessagingRepository messagingRepository;
  final CommunityDiscoveryRepository? discoveryRepository;

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  static const _reactionChoices = ['👍', '❤️', '😂', '🎉', '🙏'];

  final _composer = TextEditingController();
  NanoViewState _state = const NanoViewLoading();
  List<CommunityMessage> _messages = const [];
  List<CommunityMember> _members = const [];
  CommunityMessage? _replyTo;
  CommunityMember? _mention;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final messages =
          await widget.messagingRepository.listMessages(widget.communityId);
      List<CommunityMember> members = const [];
      final discovery = widget.discoveryRepository;
      if (discovery != null) {
        members = await discovery.listMembers(widget.communityId);
      }
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _members = members.where((m) => !m.isSelf).toList();
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final mentions = <String>[
        if (_mention != null) _mention!.userId,
      ];
      await widget.messagingRepository.sendMessage(
        communityId: widget.communityId,
        body: body,
        parentMessageId: _replyTo?.id,
        mentionUserIds: mentions,
      );
      if (!mounted) return;
      _composer.clear();
      setState(() {
        _replyTo = null;
        _mention = null;
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _react(CommunityMessage message, String emoji) async {
    setState(() => _busy = true);
    try {
      final updated = await widget.messagingRepository.toggleReaction(
        messageId: message.id,
        emoji: emoji,
      );
      if (!mounted) return;
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m.id == updated.id) updated else m,
        ];
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _pickReaction(CommunityMessage message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(NanoSpacing.lg),
            child: Wrap(
              spacing: NanoSpacing.sm,
              children: [
                for (final emoji in _reactionChoices)
                  ActionChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 22)),
                    onPressed: () {
                      Navigator.pop(context);
                      _react(message, emoji);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: Text(widget.communityName)),
      body: Column(
        children: [
          Expanded(
            child: NanoViewStateHost(
              state: _state,
              onRetry: _load,
              child: _messages.isEmpty
                  ? Center(child: Text(copy.communitiesChatEmpty))
                  : ListView.builder(
                      padding: const EdgeInsets.all(NanoSpacing.md),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _MessageTile(
                          message: message,
                          messages: _messages,
                          copy: copy,
                          onReply: () => setState(() => _replyTo = message),
                          onReact: () => _pickReaction(message),
                          onToggle: (emoji) => _react(message, emoji),
                        );
                      },
                    ),
            ),
          ),
          if (_replyTo != null)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                dense: true,
                title: Text(
                  '${copy.communitiesReplyingTo}: ${_replyTo!.authorDisplayName}',
                ),
                subtitle: Text(
                  _replyTo!.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _replyTo = null),
                ),
              ),
            ),
          if (_mention != null)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                dense: true,
                title: Text('@${_mention!.displayName}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _mention = null),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              NanoSpacing.md,
              NanoSpacing.sm,
              NanoSpacing.md,
              NanoSpacing.md + bottom,
            ),
            child: Row(
              children: [
                if (_members.isNotEmpty)
                  IconButton(
                    tooltip: copy.communitiesMention,
                    onPressed: _busy
                        ? null
                        : () async {
                            final picked =
                                await showModalBottomSheet<CommunityMember>(
                              context: context,
                              builder: (context) => SafeArea(
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    for (final member in _members)
                                      ListTile(
                                        title: Text(member.displayName),
                                        onTap: () =>
                                            Navigator.pop(context, member),
                                      ),
                                  ],
                                ),
                              ),
                            );
                            if (picked != null && mounted) {
                              setState(() => _mention = picked);
                            }
                          },
                    icon: const Icon(Icons.alternate_email),
                  ),
                Expanded(
                  child: TextField(
                    controller: _composer,
                    enabled: !_busy,
                    decoration: InputDecoration(
                      hintText: copy.communitiesChatHint,
                    ),
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: NanoSpacing.sm),
                FilledButton(
                  onPressed: _busy ? null : _send,
                  child: Text(copy.communitiesSend),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.messages,
    required this.copy,
    required this.onReply,
    required this.onReact,
    required this.onToggle,
  });

  final CommunityMessage message;
  final List<CommunityMessage> messages;
  final NanoCopy copy;
  final VoidCallback onReply;
  final VoidCallback onReact;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    CommunityMessage? parent;
    if (message.isReply) {
      for (final m in messages) {
        if (m.id == message.parentMessageId) {
          parent = m;
          break;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: NanoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message.isSelf
                ? '${message.authorDisplayName} (${copy.communitiesYou})'
                : message.authorDisplayName,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (parent != null) ...[
            const SizedBox(height: NanoSpacing.xs),
            Text(
              '${copy.communitiesReplyingTo} ${parent.authorDisplayName}: ${parent.body}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: NanoSpacing.xs),
          Text(message.body),
          if (message.mentionUserIds.isNotEmpty) ...[
            const SizedBox(height: NanoSpacing.xs),
            Text(
              '@${message.mentionUserIds.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (message.reactions.isNotEmpty) ...[
            const SizedBox(height: NanoSpacing.xs),
            Wrap(
              spacing: NanoSpacing.xs,
              children: [
                for (final reaction in message.reactions)
                  ActionChip(
                    label: Text('${reaction.emoji} ${reaction.count}'),
                    onPressed: () => onToggle(reaction.emoji),
                  ),
              ],
            ),
          ],
          Row(
            children: [
              TextButton(
                onPressed: onReply,
                child: Text(copy.communitiesReply),
              ),
              TextButton(
                onPressed: onReact,
                child: Text(copy.communitiesReact),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
