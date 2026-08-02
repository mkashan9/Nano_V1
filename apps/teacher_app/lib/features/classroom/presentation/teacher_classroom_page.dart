import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// CLS-01/02/03 Classroom: announcements, attachments, schedule/expiry/ack.
class TeacherClassroomPage extends StatefulWidget {
  const TeacherClassroomPage({
    super.key,
    required this.repository,
    this.initialAssignmentId,
  });

  final TeacherClassroomRepository repository;
  final String? initialAssignmentId;

  @override
  State<TeacherClassroomPage> createState() => _TeacherClassroomPageState();
}

class _TeacherClassroomPageState extends State<TeacherClassroomPage> {
  NanoViewState _state = const NanoViewLoading();
  TeacherMyClasses? _mine;
  TeacherClassroomList? _list;
  String? _assignmentId;
  String? _editingId;
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _attTitle = TextEditingController();
  final _attUrl = TextEditingController();
  var _publishNow = false;
  var _requiresAck = true;
  DateTime? _scheduledAt;
  DateTime? _expiresAt;
  var _saving = false;
  var _attBusy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _assignmentId = widget.initialAssignmentId;
    _bootstrap();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _attTitle.dispose();
    _attUrl.dispose();
    super.dispose();
  }

  TeacherClassroomItem? get _editingItem {
    final id = _editingId;
    final list = _list;
    if (id == null || list == null) return null;
    for (final item in list.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _bootstrap() async {
    setState(() {
      _state = const NanoViewLoading();
      _message = null;
    });
    try {
      final mine = await widget.repository.listAssignments();
      if (!mounted) return;
      final selected = _assignmentId ??
          (mine.assignments.isEmpty ? null : mine.assignments.first.id);
      setState(() {
        _mine = mine;
        _assignmentId = selected;
      });
      if (selected != null) {
        await _loadList(selected);
      } else {
        setState(() => _state = const NanoViewReady());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _loadList(String assignmentId) async {
    setState(() {
      _state = const NanoViewLoading();
      _message = null;
    });
    try {
      final list = await widget.repository.listForAssignment(assignmentId);
      if (!mounted) return;
      setState(() {
        _assignmentId = assignmentId;
        _list = list;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  void _resetForm() {
    _editingId = null;
    _title.clear();
    _body.clear();
    _attTitle.clear();
    _attUrl.clear();
    _publishNow = false;
    _requiresAck = true;
    _scheduledAt = null;
    _expiresAt = null;
  }

  void _edit(TeacherClassroomItem item) {
    setState(() {
      _editingId = item.id;
      _title.text = item.title;
      _body.text = item.body;
      _publishNow = false;
      _requiresAck = item.requiresAcknowledgement;
      _scheduledAt = item.scheduledPublishAt;
      _expiresAt = item.expiresAt;
      _attTitle.clear();
      _attUrl.clear();
      _message = null;
    });
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return '—';
    final d = value.toUtc();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _scheduledAt = DateTime.utc(picked.year, picked.month, picked.day);
      _publishNow = false;
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final initial = _expiresAt ?? now.add(const Duration(days: 14));
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _expiresAt = DateTime.utc(picked.year, picked.month, picked.day);
    });
  }

  Future<void> _save() async {
    final assignmentId = _assignmentId;
    if (assignmentId == null || _saving) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      final input = TeacherClassroomDraftInput(
        title: _title.text,
        body: _body.text,
        publishNow: _editingId == null && _publishNow,
        scheduledPublishAt: _scheduledAt,
        expiresAt: _expiresAt,
        requiresAcknowledgement: _requiresAck,
        clearSchedule: _editingId != null && _scheduledAt == null,
        clearExpiry: _editingId != null && _expiresAt == null,
      );
      final list = _editingId == null
          ? await widget.repository.create(
              assignmentId: assignmentId,
              input: input,
            )
          : await widget.repository.update(
              itemId: _editingId!,
              input: input,
            );
      if (!mounted) return;
      setState(() {
        _list = list;
        _saving = false;
        _message = copy.teacherClassroomSaved;
        if (_editingId == null) {
          _resetForm();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _message = copy.teacherClassroomSaveFailed;
      });
    }
  }

  Future<void> _addLink() async {
    final itemId = _editingId;
    if (itemId == null || _attBusy) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() {
      _attBusy = true;
      _message = null;
    });
    try {
      final list = await widget.repository.addAttachment(
        itemId: itemId,
        input: TeacherClassroomAttachmentInput(
          title: _attTitle.text,
          url: _attUrl.text,
        ),
      );
      if (!mounted) return;
      setState(() {
        _list = list;
        _attBusy = false;
        _attTitle.clear();
        _attUrl.clear();
        _message = copy.teacherClassroomAttachmentAdded;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attBusy = false;
        _message = copy.teacherClassroomAttachmentFailed;
      });
    }
  }

  Future<void> _removeAttachment(String attachmentId) async {
    if (_attBusy) return;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    setState(() {
      _attBusy = true;
      _message = null;
    });
    try {
      final list = await widget.repository.removeAttachment(attachmentId);
      if (!mounted) return;
      setState(() {
        _list = list;
        _attBusy = false;
        _message = copy.teacherClassroomAttachmentRemoved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _attBusy = false;
        _message = copy.teacherClassroomAttachmentFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final mine = _mine;
    final list = _list;
    final editing = _editingItem;

    return NanoViewStateHost(
      state: _state,
      onRetry: _bootstrap,
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(copy.teacherClassroomTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              copy.teacherClassroomSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (mine == null || mine.assignments.isEmpty)
              Text(copy.teacherClassroomNoAssignments)
            else ...[
              DropdownButtonFormField<String>(
                value: _assignmentId,
                decoration: InputDecoration(
                  labelText: copy.teacherClassroomAssignmentLabel,
                ),
                items: [
                  for (final a in mine.assignments)
                    DropdownMenuItem(
                      value: a.id,
                      child: Text('${a.classLabel} · ${a.subjectCode}'),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (id) {
                        if (id == null) return;
                        _resetForm();
                        _loadList(id);
                      },
              ),
              if (list != null) ...[
                const SizedBox(height: 16),
                Text(
                  _editingId == null
                      ? copy.teacherClassroomCreateTitle
                      : copy.teacherClassroomEditTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _title,
                  decoration: InputDecoration(
                    labelText: copy.teacherClassroomTitleLabel,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _body,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: copy.teacherClassroomBodyLabel,
                    alignLabelWithHint: true,
                  ),
                ),
                if (_editingId == null) ...[
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _publishNow,
                    onChanged: _saving
                        ? null
                        : (v) => setState(() {
                              _publishNow = v ?? false;
                              if (_publishNow) _scheduledAt = null;
                            }),
                    title: Text(copy.teacherClassroomPublishNow),
                  ),
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _requiresAck,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _requiresAck = v ?? true),
                  title: Text(copy.teacherClassroomRequiresAck),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.teacherClassroomScheduleLabel),
                  subtitle: Text(_dateLabel(_scheduledAt)),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: _saving || _publishNow ? null : _pickSchedule,
                        child: Text(copy.teacherClassroomScheduleLabel),
                      ),
                      if (_scheduledAt != null)
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _scheduledAt = null),
                          child: Text(copy.teacherClassroomClearSchedule),
                        ),
                    ],
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.teacherClassroomExpiryLabel),
                  subtitle: Text(_dateLabel(_expiresAt)),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      TextButton(
                        onPressed: _saving ? null : _pickExpiry,
                        child: Text(copy.teacherClassroomExpiryLabel),
                      ),
                      if (_expiresAt != null)
                        TextButton(
                          onPressed: _saving
                              ? null
                              : () => setState(() => _expiresAt = null),
                          child: Text(copy.teacherClassroomClearExpiry),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(
                        _editingId == null
                            ? copy.teacherClassroomSaveDraft
                            : copy.teacherClassroomUpdateDraft,
                      ),
                    ),
                    if (_editingId != null)
                      OutlinedButton(
                        onPressed: _saving ? null : () => setState(_resetForm),
                        child: Text(copy.teacherClassroomCancelEdit),
                      ),
                  ],
                ),
                if (editing != null && editing.isDraft) ...[
                  const SizedBox(height: 16),
                  Text(
                    copy.teacherClassroomAttachmentsTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    copy.teacherClassroomAttachmentsSubtitle,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _attTitle,
                    decoration: InputDecoration(
                      labelText: copy.teacherClassroomAttachmentTitleLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _attUrl,
                    decoration: InputDecoration(
                      labelText: copy.teacherClassroomAttachmentUrlLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: _attBusy ? null : _addLink,
                    child: Text(copy.teacherClassroomAddLink),
                  ),
                  if (editing.attachments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(copy.teacherClassroomAttachmentsEmpty),
                    )
                  else
                    for (final att in editing.attachments)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(att.title),
                        subtitle: Text(att.url ?? att.storagePath ?? ''),
                        trailing: TextButton(
                          onPressed: _attBusy
                              ? null
                              : () => _removeAttachment(att.id),
                          child: Text(copy.teacherClassroomRemoveAttachment),
                        ),
                      ),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 24),
                Text(
                  copy.teacherClassroomListTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (list.items.isEmpty)
                  Text(copy.teacherClassroomListEmpty)
                else
                  for (final item in list.items)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title),
                      subtitle: Text(
                        copy.teacherClassroomListSubtitle(
                          item.displayStatus,
                          [
                            if (item.body.trim().isEmpty)
                              copy.teacherClassroomBodyEmpty
                            else
                              item.body,
                            if (item.attachments.isNotEmpty)
                              copy.teacherClassroomAttachmentCount(
                                item.attachments.length,
                              ),
                            if (item.status == ClassroomItemStatus.published &&
                                item.requiresAcknowledgement)
                              copy.teacherClassroomAckSummary(
                                item.ackCount,
                                item.rosterCount,
                              ),
                          ].join(' · '),
                        ),
                      ),
                      trailing: item.isDraft
                          ? TextButton(
                              onPressed: () => _edit(item),
                              child: Text(copy.teacherClassroomEditAction),
                            )
                          : null,
                    ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
