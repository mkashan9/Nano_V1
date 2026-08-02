import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// FLX-04 student classroom feed with optional acknowledgement.
class StudentClassroomPage extends StatefulWidget {
  const StudentClassroomPage({
    super.key,
    required this.repository,
  });

  final StudentClassroomRepository repository;

  @override
  State<StudentClassroomPage> createState() => _StudentClassroomPageState();
}

class _StudentClassroomPageState extends State<StudentClassroomPage> {
  NanoViewState _state = const NanoViewLoading();
  StudentClassroomFeed? _feed;
  String? _message;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _state = const NanoViewLoading();
      _message = null;
    });
    try {
      final feed = await widget.repository.loadFeed();
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _acknowledge(String itemId) async {
    if (_busy) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final feed = await widget.repository.acknowledge(itemId);
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _busy = false;
        _message = copy.studentClassroomAckDone;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = copy.studentClassroomAckFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final feed = _feed;

    return NanoScaffold(
      padBody: true,
      appBar: AppBar(title: Text(copy.flexClassroomTitle)),
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: NanoResponsiveBuilder(
          builder: (context, windowSize, _) {
            return NanoMaxContentWidth(
              maxWidth: windowSize == NanoWindowSize.desktop ? 960 : 720,
              child: ListView(
                children: [
                  Text(
                    copy.studentClassroomSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (feed != null) ...[
                    const SizedBox(height: NanoSpacing.sm),
                    Text(
                      copy.studentClassroomPendingAck(feed.pendingAckCount),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: NanoSpacing.md),
                    if (feed.items.isEmpty)
                      Text(copy.studentClassroomEmpty)
                    else
                      for (final item in feed.items) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.title),
                          subtitle: Text(
                            [
                              if (item.classLabel != null &&
                                  item.classLabel!.isNotEmpty)
                                item.classLabel!,
                              if (item.subjectCode != null &&
                                  item.subjectCode!.isNotEmpty)
                                item.subjectCode!,
                              if (item.isExpired)
                                copy.studentClassroomExpired
                              else if (item.acknowledged)
                                copy.studentClassroomAcknowledged
                              else if (item.requiresAcknowledgement)
                                copy.studentClassroomNeedsAck,
                              if (item.body.trim().isNotEmpty) item.body,
                              if (item.attachments.isNotEmpty)
                                copy.teacherClassroomAttachmentCount(
                                  item.attachments.length,
                                ),
                            ].join(' · '),
                          ),
                          trailing: item.canAcknowledge
                              ? TextButton(
                                  onPressed: _busy
                                      ? null
                                      : () => _acknowledge(item.id),
                                  child: Text(copy.studentClassroomAckAction),
                                )
                              : null,
                        ),
                        if (item.attachments.isNotEmpty)
                          for (final att in item.attachments)
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                bottom: 4,
                              ),
                              child: Text(
                                '${att.title}${att.url == null ? '' : ' — ${att.url}'}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                      ],
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: NanoSpacing.sm),
                    Text(_message!, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
