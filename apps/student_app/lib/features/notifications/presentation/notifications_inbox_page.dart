import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// STU-06 inbox + NOT-01 push ingest / permission-aware deep links.
class NotificationsInboxPage extends StatefulWidget {
  const NotificationsInboxPage({
    super.key,
    required this.repository,
    this.principal,
    this.pushDelivery,
    this.onOpenDeepLink,
  });

  final StudentNotificationInboxRepository repository;
  final SessionPrincipal? principal;
  final PushDeliveryRepository? pushDelivery;
  final ValueChanged<String>? onOpenDeepLink;

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> {
  NanoViewState _state = const NanoViewLoading();
  InboxFilter _filter = InboxFilter.all;
  List<InboxItem> _items = const [];
  var _busy = false;
  late final PushDeliveryRepository _push;
  late final SessionPrincipal _principal;

  @override
  void initState() {
    super.initState();
    _principal = widget.principal ?? SessionPrincipal.seniorSchool();
    final inbox = widget.repository;
    _push = widget.pushDelivery ??
        FakePushDeliveryRepository(inbox: inbox);
    _bootstrapToken();
    _load();
  }

  Future<void> _bootstrapToken() async {
    try {
      await _push.registerToken(
        userId: _principal.userId ?? 'local-student',
        token: 'fake-device-token-01',
        platform: 'fake',
      );
    } catch (_) {
      // Preview shells can still list the inbox without a token.
    }
  }

  @override
  void didUpdateWidget(covariant NotificationsInboxPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final items = await widget.repository.listInbox(filter: _filter);
      if (!mounted) return;
      setState(() {
        _items = items;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() => _state = NanoViewError(message: copy.inboxLoadError));
    }
  }

  Future<void> _setFilter(InboxFilter filter) async {
    if (filter == _filter) return;
    setState(() => _filter = filter);
    await _load();
  }

  Future<void> _openItem(InboxItem item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (item.isUnread) {
        await widget.repository.markRead(item.id);
      }
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      final resolution =
          DeepLinkResolver.resolve(_principal, item.deepLinkPath);
      widget.onOpenDeepLink?.call(resolution.location);
      final message = resolution.fellBack
          ? '${copy.inboxDeepLinkFallback}: ${resolution.location}'
          : '${copy.inboxDeepLinkHint}: ${resolution.location}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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

  Future<void> _simulatePush() async {
    if (_busy) return;
    setState(() => _busy = true);
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    try {
      final result = await _push.deliver(
        PushEvent(
          eventId: 'evt-learning-force',
          recipientUserId: _principal.userId ?? 'local-student',
          category: 'learning',
          title: 'Push: topic ready',
          body: 'Forces is waiting in Learning.',
          deepLinkPath: '/learning',
        ),
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      final message = switch (result.outcome) {
        PushDeliveryOutcome.delivered => copy.inboxPushDelivered,
        PushDeliveryOutcome.duplicated => copy.inboxPushDuplicated,
        PushDeliveryOutcome.noActiveToken => 'No active device token',
        PushDeliveryOutcome.rejected => 'Push rejected',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return Scaffold(
      appBar: AppBar(
        title: Text(copy.notificationsLabel),
        actions: [
          TextButton(
            onPressed: _busy ? null : _simulatePush,
            child: Text(copy.inboxSimulatePush),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NanoSpacing.md,
              NanoSpacing.md,
              NanoSpacing.md,
              NanoSpacing.sm,
            ),
            child: SegmentedButton<InboxFilter>(
              segments: [
                ButtonSegment(
                  value: InboxFilter.all,
                  label: Text(copy.inboxFilterAll),
                ),
                ButtonSegment(
                  value: InboxFilter.unread,
                  label: Text(copy.inboxFilterUnread),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: _busy
                  ? null
                  : (next) => _setFilter(next.first),
            ),
          ),
          Expanded(
            child: NanoViewStateHost(
              state: _state,
              onRetry: _load,
              child: _items.isEmpty
                  ? Center(child: Text(copy.inboxEmpty))
                  : ListView.separated(
                      padding: const EdgeInsets.all(NanoSpacing.md),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return ListTile(
                          leading: Icon(
                            item.isUnread
                                ? Icons.mark_email_unread_outlined
                                : Icons.mark_email_read_outlined,
                          ),
                          title: Text(
                            item.title,
                            style: item.isUnread
                                ? const TextStyle(fontWeight: FontWeight.w600)
                                : null,
                          ),
                          subtitle: Text(
                            item.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(item.category),
                          onTap: _busy ? null : () => _openItem(item),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
