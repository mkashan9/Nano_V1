import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// COM-04..06 community chat: text, media, pins, search, gallery.
class CommunityChatPage extends StatefulWidget {
  const CommunityChatPage({
    super.key,
    required this.communityId,
    required this.communityName,
    required this.messagingRepository,
    this.discoveryRepository,
    this.canPin = false,
  });

  final String communityId;
  final String communityName;
  final CommunityMessagingRepository messagingRepository;
  final CommunityDiscoveryRepository? discoveryRepository;
  final bool canPin;

  @override
  State<CommunityChatPage> createState() => _CommunityChatPageState();
}

class _CommunityChatPageState extends State<CommunityChatPage> {
  static const _reactionChoices = ['👍', '❤️', '😂', '🎉', '🙏'];

  final _composer = TextEditingController();
  NanoViewState _state = const NanoViewLoading();
  List<CommunityMessage> _messages = const [];
  List<CommunityMessage> _pins = const [];
  List<CommunityMember> _members = const [];
  final List<CommunityMessageAttachment> _pendingAttachments = [];
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
      final pins =
          await widget.messagingRepository.listPins(widget.communityId);
      List<CommunityMember> members = const [];
      final discovery = widget.discoveryRepository;
      if (discovery != null) {
        members = await discovery.listMembers(widget.communityId);
      }
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _pins = pins;
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
    if ((body.isEmpty && _pendingAttachments.isEmpty) || _busy) return;
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
        attachmentIds: [
          for (final a in _pendingAttachments) a.id,
        ],
      );
      if (!mounted) return;
      _composer.clear();
      setState(() {
        _replyTo = null;
        _mention = null;
        _pendingAttachments.clear();
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

  Future<void> _attach(CommunityMediaKind kind) async {
    setState(() => _busy = true);
    try {
      final contentType = switch (kind) {
        CommunityMediaKind.photo => 'image/jpeg',
        CommunityMediaKind.voice => 'audio/mp4',
        CommunityMediaKind.video => 'video/mp4',
        CommunityMediaKind.file => 'application/pdf',
      };
      final prepared = await widget.messagingRepository.prepareMediaUpload(
        communityId: widget.communityId,
        kind: kind,
        contentType: contentType,
        byteSize: 128,
        originalFilename: '${kind.wire}-demo',
        durationMs: kind == CommunityMediaKind.voice ? 3000 : null,
      );
      // Fake-first fixture bytes; live path uploads the same tiny payload.
      await widget.messagingRepository.uploadMediaBytes(
        bucket: prepared.storageBucket,
        path: prepared.storagePath,
        bytes: utf8.encode('nano-community-media'),
        contentType: contentType,
      );
      if (!mounted) return;
      setState(() => _pendingAttachments.add(prepared));
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

  Future<void> _pin(CommunityMessage message, bool pinned) async {
    setState(() => _busy = true);
    try {
      await widget.messagingRepository.pinMessage(
        messageId: message.id,
        pinned: pinned,
      );
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

  Future<void> _openSearch(NanoCopy copy) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _SearchSheet(
          copy: copy,
          onSearch: (query) => widget.messagingRepository.searchMessages(
            communityId: widget.communityId,
            query: query,
          ),
        );
      },
    );
  }

  Future<void> _openGallery(NanoCopy copy) async {
    final items = await widget.messagingRepository.listGallery(
      communityId: widget.communityId,
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.5,
            child: Padding(
              padding: const EdgeInsets.all(NanoSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    copy.communitiesGallery,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  Expanded(
                    child: items.isEmpty
                        ? Center(child: Text(copy.communitiesNoGallery))
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return ListTile(
                                leading: Icon(_iconFor(item.kind)),
                                title: Text(item.displayLabel),
                                subtitle: Text(item.kind.wire),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

  void _pickAttach(NanoCopy copy) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: Text(copy.communitiesAttachPhoto),
                onTap: () {
                  Navigator.pop(context);
                  _attach(CommunityMediaKind.photo);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic_none),
                title: Text(copy.communitiesAttachVoice),
                onTap: () {
                  Navigator.pop(context);
                  _attach(CommunityMediaKind.voice);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: Text(copy.communitiesAttachVideo),
                onTap: () {
                  Navigator.pop(context);
                  _attach(CommunityMediaKind.video);
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(copy.communitiesAttachFile),
                onTap: () {
                  Navigator.pop(context);
                  _attach(CommunityMediaKind.file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconFor(CommunityMediaKind kind) => switch (kind) {
        CommunityMediaKind.photo => Icons.image_outlined,
        CommunityMediaKind.voice => Icons.mic_none,
        CommunityMediaKind.video => Icons.videocam_outlined,
        CommunityMediaKind.file => Icons.insert_drive_file_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.communityName),
        actions: [
          IconButton(
            tooltip: copy.communitiesSearchMessages,
            onPressed: _busy ? null : () => _openSearch(copy),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: copy.communitiesGallery,
            onPressed: _busy ? null : () => _openGallery(copy),
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_pins.isNotEmpty)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.push_pin),
                title: Text(copy.communitiesPins),
                subtitle: Text(
                  _pins.first.body.isEmpty && _pins.first.attachments.isNotEmpty
                      ? _pins.first.attachments.first.displayLabel
                      : _pins.first.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
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
                          iconFor: _iconFor,
                          canPin: widget.canPin,
                          onReply: () => setState(() => _replyTo = message),
                          onReact: () => _pickReaction(message),
                          onToggle: (emoji) => _react(message, emoji),
                          onPin: () => _pin(message, !message.isPinned),
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
                  _replyTo!.body.isEmpty
                      ? (_replyTo!.attachments.isNotEmpty
                          ? _replyTo!.attachments.first.displayLabel
                          : '')
                      : _replyTo!.body,
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
          if (_pendingAttachments.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                children: [
                  for (final attachment in _pendingAttachments)
                    Padding(
                      padding: const EdgeInsets.only(right: NanoSpacing.sm),
                      child: InputChip(
                        avatar: Icon(_iconFor(attachment.kind), size: 18),
                        label: Text(attachment.displayLabel),
                        onDeleted: _busy
                            ? null
                            : () => setState(
                                  () => _pendingAttachments.remove(attachment),
                                ),
                      ),
                    ),
                ],
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
                IconButton(
                  tooltip: copy.communitiesAttach,
                  onPressed: _busy ? null : () => _pickAttach(copy),
                  icon: const Icon(Icons.add_circle_outline),
                ),
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
    required this.iconFor,
    required this.canPin,
    required this.onReply,
    required this.onReact,
    required this.onToggle,
    required this.onPin,
  });

  final CommunityMessage message;
  final List<CommunityMessage> messages;
  final NanoCopy copy;
  final IconData Function(CommunityMediaKind kind) iconFor;
  final bool canPin;
  final VoidCallback onReply;
  final VoidCallback onReact;
  final ValueChanged<String> onToggle;
  final VoidCallback onPin;

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
          if (message.isPinned) ...[
            const SizedBox(height: NanoSpacing.xs),
            Text(
              copy.communitiesPins,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
          if (parent != null) ...[
            const SizedBox(height: NanoSpacing.xs),
            Text(
              '${copy.communitiesReplyingTo} ${parent.authorDisplayName}: ${parent.body.isEmpty && parent.attachments.isNotEmpty ? parent.attachments.first.displayLabel : parent.body}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (message.body.isNotEmpty) ...[
            const SizedBox(height: NanoSpacing.xs),
            Text(message.body),
          ],
          if (message.attachments.isNotEmpty) ...[
            const SizedBox(height: NanoSpacing.xs),
            Wrap(
              spacing: NanoSpacing.xs,
              runSpacing: NanoSpacing.xs,
              children: [
                for (final attachment in message.attachments)
                  Chip(
                    avatar: Icon(iconFor(attachment.kind), size: 18),
                    label: Text(attachment.displayLabel),
                  ),
              ],
            ),
          ],
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
              if (canPin)
                TextButton(
                  onPressed: onPin,
                  child: Text(
                    message.isPinned
                        ? copy.communitiesUnpin
                        : copy.communitiesPin,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.copy,
    required this.onSearch,
  });

  final NanoCopy copy;
  final Future<List<CommunityMessage>> Function(String query) onSearch;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  List<CommunityMessage> _results = const [];
  var _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      final results = await widget.onSearch(_controller.text);
      if (!mounted) return;
      setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        NanoSpacing.lg,
        NanoSpacing.lg,
        NanoSpacing.lg,
        NanoSpacing.lg + bottom,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.55,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.copy.communitiesSearchMessages,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _busy ? null : _run,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _run(),
            ),
            const SizedBox(height: NanoSpacing.md),
            Expanded(
              child: _results.isEmpty
                  ? Center(child: Text(widget.copy.communitiesChatEmpty))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final message = _results[index];
                        return ListTile(
                          title: Text(message.authorDisplayName),
                          subtitle: Text(message.body),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
