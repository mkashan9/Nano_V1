import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'teacher_classes_repository.dart';

/// CLS-01/CLS-02/CLS-03 classroom announcements, attachments, schedule/ack.
abstract class TeacherClassroomRepository {
  Future<TeacherMyClasses> listAssignments();
  Future<TeacherClassroomList> listForAssignment(String assignmentId);
  Future<TeacherClassroomList> create({
    required String assignmentId,
    required TeacherClassroomDraftInput input,
  });
  Future<TeacherClassroomList> update({
    required String itemId,
    required TeacherClassroomDraftInput input,
  });
  Future<TeacherClassroomList> addAttachment({
    required String itemId,
    required TeacherClassroomAttachmentInput input,
  });
  Future<TeacherClassroomList> removeAttachment(String attachmentId);
}

class FakeTeacherClassroomRepository implements TeacherClassroomRepository {
  FakeTeacherClassroomRepository({
    TeacherClassesRepository? classesRepository,
  }) : _classes = classesRepository ?? FakeTeacherClassesRepository();

  final TeacherClassesRepository _classes;
  final Map<String, List<TeacherClassroomItem>> _byAssignment = {};
  final Map<String, Set<String>> _acksByItem = {};
  var _seq = 0;
  var _attSeq = 0;
  var alwaysFail = false;

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

  Future<int> _rosterCount(String assignmentId) async {
    try {
      final roster = await _classes.loadRoster(assignmentId);
      return roster.studentCount;
    } catch (_) {
      return 0;
    }
  }

  TeacherClassroomItem _withCounts(TeacherClassroomItem item, int roster) {
    final now = DateTime.now().toUtc();
    var status = item.status;
    var publishedAt = item.publishedAt;
    if (status.isDraft &&
        item.scheduledPublishAt != null &&
        !item.scheduledPublishAt!.isAfter(now)) {
      status = ClassroomItemStatus.published;
      publishedAt = publishedAt ?? item.scheduledPublishAt;
    }
    final expired =
        item.expiresAt != null && !item.expiresAt!.isAfter(now);
    return TeacherClassroomItem(
      id: item.id,
      schoolId: item.schoolId,
      teacherAssignmentId: item.teacherAssignmentId,
      title: item.title,
      body: item.body,
      status: status,
      attachments: item.attachments,
      scheduledPublishAt: item.scheduledPublishAt,
      expiresAt: item.expiresAt,
      requiresAcknowledgement: item.requiresAcknowledgement,
      isExpired: expired,
      ackCount: _acksByItem[item.id]?.length ?? 0,
      rosterCount: roster,
      publishedAt: publishedAt,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
    );
  }

  /// Test helper: record a student acknowledgement (FLX-04 will call server RPC).
  Future<void> recordAck({
    required String itemId,
    required String studentUserId,
  }) async {
    for (final entry in _byAssignment.entries) {
      final idx = entry.value.indexWhere((i) => i.id == itemId);
      if (idx < 0) continue;
      final enriched =
          _withCounts(entry.value[idx], await _rosterCount(entry.key));
      if (enriched.status != ClassroomItemStatus.published) {
        throw StateError('Only published announcements can be acknowledged.');
      }
      if (enriched.isExpired) {
        throw StateError('This announcement has expired.');
      }
      (_acksByItem[itemId] ??= {}).add(studentUserId);
      return;
    }
    throw StateError('Announcement not found.');
  }

  @override
  Future<TeacherClassroomList> listForAssignment(String assignmentId) async {
    if (alwaysFail) throw StateError('Classroom unavailable');
    final mine = await _classes.listMine();
    TeacherAssignmentScope? scope;
    for (final a in mine.assignments) {
      if (a.id == assignmentId) {
        scope = a;
        break;
      }
    }
    if (scope == null) {
      throw StateError('Assignment is not in your active scope.');
    }
    final roster = await _rosterCount(assignmentId);
    final raw = _byAssignment[assignmentId] ?? const <TeacherClassroomItem>[];
    final items = [
      for (final item in raw) _withCounts(item, roster),
    ];
    // Persist promotions
    _byAssignment[assignmentId] = items;
    return TeacherClassroomList(
      assignmentId: assignmentId,
      schoolId: mine.schoolId,
      classLabel: scope.classLabel,
      subjectCode: scope.subjectCode,
      items: List.unmodifiable(items),
      generatedAt: DateTime.utc(2026, 8, 2),
    );
  }

  void _validateSchedule(TeacherClassroomDraftInput input) {
    if (input.publishNow && input.scheduledPublishAt != null) {
      throw StateError('Choose either publish now or a schedule, not both.');
    }
    final scheduled = input.scheduledPublishAt;
    final expires = input.expiresAt;
    if (scheduled != null && expires != null && !expires.isAfter(scheduled)) {
      throw StateError('Expiry must be after the scheduled publish time.');
    }
  }

  @override
  Future<TeacherClassroomList> create({
    required String assignmentId,
    required TeacherClassroomDraftInput input,
  }) async {
    if (alwaysFail) throw StateError('Classroom unavailable');
    final title = input.title.trim();
    if (title.isEmpty) throw StateError('Title is required.');
    _validateSchedule(input);
    final list = await listForAssignment(assignmentId);
    _seq += 1;
    final now = DateTime.utc(2026, 8, 2);
    var status = ClassroomItemStatus.draft;
    DateTime? publishedAt;
    var scheduled = input.scheduledPublishAt;
    if (input.publishNow) {
      status = ClassroomItemStatus.published;
      publishedAt = now;
      scheduled = null;
    } else if (scheduled != null && !scheduled.isAfter(now)) {
      status = ClassroomItemStatus.published;
      publishedAt = scheduled;
    }
    final row = TeacherClassroomItem(
      id: 'cls-$_seq',
      schoolId: list.schoolId,
      teacherAssignmentId: assignmentId,
      title: title,
      body: input.body,
      status: status,
      scheduledPublishAt: scheduled,
      expiresAt: input.expiresAt,
      requiresAcknowledgement: input.requiresAcknowledgement,
      publishedAt: publishedAt,
      createdAt: now,
      updatedAt: now,
    );
    _byAssignment[assignmentId] = [
      row,
      ...(_byAssignment[assignmentId] ?? const []),
    ];
    return listForAssignment(assignmentId);
  }

  @override
  Future<TeacherClassroomList> update({
    required String itemId,
    required TeacherClassroomDraftInput input,
  }) async {
    if (alwaysFail) throw StateError('Classroom unavailable');
    final title = input.title.trim();
    if (title.isEmpty) throw StateError('Title is required.');
    _validateSchedule(input);
    for (final entry in _byAssignment.entries) {
      final idx = entry.value.indexWhere((i) => i.id == itemId);
      if (idx < 0) continue;
      final existing = entry.value[idx];
      if (!existing.isDraft) {
        throw StateError('Only draft announcements can be edited.');
      }
      final scheduled = input.clearSchedule
          ? null
          : (input.scheduledPublishAt ?? existing.scheduledPublishAt);
      final expires = input.clearExpiry
          ? null
          : (input.expiresAt ?? existing.expiresAt);
      if (scheduled != null && expires != null && !expires.isAfter(scheduled)) {
        throw StateError('Expiry must be after the scheduled publish time.');
      }
      final now = DateTime.utc(2026, 8, 2);
      var status = existing.status;
      var publishedAt = existing.publishedAt;
      if (scheduled != null && !scheduled.isAfter(now)) {
        status = ClassroomItemStatus.published;
        publishedAt = publishedAt ?? scheduled;
      }
      final copy = List<TeacherClassroomItem>.from(entry.value);
      copy[idx] = TeacherClassroomItem(
        id: existing.id,
        schoolId: existing.schoolId,
        teacherAssignmentId: existing.teacherAssignmentId,
        title: title,
        body: input.body,
        status: status,
        attachments: existing.attachments,
        scheduledPublishAt: scheduled,
        expiresAt: expires,
        requiresAcknowledgement: input.requiresAcknowledgement,
        publishedAt: publishedAt,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
      _byAssignment[entry.key] = copy;
      return listForAssignment(entry.key);
    }
    throw StateError('Announcement not found.');
  }

  @override
  Future<TeacherClassroomList> addAttachment({
    required String itemId,
    required TeacherClassroomAttachmentInput input,
  }) async {
    if (alwaysFail) throw StateError('Classroom unavailable');
    final title = input.title.trim();
    if (title.isEmpty) throw StateError('Attachment title is required.');
    final url = input.url?.trim();
    if (input.kind == ClassroomAttachmentKind.link) {
      if (url == null ||
          !(url.startsWith('http://') || url.startsWith('https://'))) {
        throw StateError('Link attachments require an http(s) URL.');
      }
    }
    for (final entry in _byAssignment.entries) {
      final idx = entry.value.indexWhere((i) => i.id == itemId);
      if (idx < 0) continue;
      final existing = entry.value[idx];
      if (!existing.isDraft) {
        throw StateError(
          'Attachments can only be changed on draft announcements.',
        );
      }
      _attSeq += 1;
      final att = TeacherClassroomAttachment(
        id: 'att-$_attSeq',
        classroomItemId: existing.id,
        kind: input.kind,
        title: title,
        url: url,
        storageBucket: input.storageBucket,
        storagePath: input.storagePath,
        contentType: input.contentType,
        byteSize: input.byteSize,
        checksum: input.checksum,
        sortOrder: existing.attachments.length + 1,
      );
      final copy = List<TeacherClassroomItem>.from(entry.value);
      copy[idx] = TeacherClassroomItem(
        id: existing.id,
        schoolId: existing.schoolId,
        teacherAssignmentId: existing.teacherAssignmentId,
        title: existing.title,
        body: existing.body,
        status: existing.status,
        attachments: [...existing.attachments, att],
        scheduledPublishAt: existing.scheduledPublishAt,
        expiresAt: existing.expiresAt,
        requiresAcknowledgement: existing.requiresAcknowledgement,
        publishedAt: existing.publishedAt,
        createdAt: existing.createdAt,
        updatedAt: DateTime.utc(2026, 8, 2),
      );
      _byAssignment[entry.key] = copy;
      return listForAssignment(entry.key);
    }
    throw StateError('Announcement not found.');
  }

  @override
  Future<TeacherClassroomList> removeAttachment(String attachmentId) async {
    if (alwaysFail) throw StateError('Classroom unavailable');
    for (final entry in _byAssignment.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final existing = entry.value[i];
        if (!existing.attachments.any((a) => a.id == attachmentId)) continue;
        if (!existing.isDraft) {
          throw StateError(
            'Attachments can only be changed on draft announcements.',
          );
        }
        final copy = List<TeacherClassroomItem>.from(entry.value);
        copy[i] = TeacherClassroomItem(
          id: existing.id,
          schoolId: existing.schoolId,
          teacherAssignmentId: existing.teacherAssignmentId,
          title: existing.title,
          body: existing.body,
          status: existing.status,
          attachments: [
            for (final a in existing.attachments)
              if (a.id != attachmentId) a,
          ],
          scheduledPublishAt: existing.scheduledPublishAt,
          expiresAt: existing.expiresAt,
          requiresAcknowledgement: existing.requiresAcknowledgement,
          publishedAt: existing.publishedAt,
          createdAt: existing.createdAt,
          updatedAt: DateTime.utc(2026, 8, 2),
        );
        _byAssignment[entry.key] = copy;
        return listForAssignment(entry.key);
      }
    }
    throw StateError('Attachment not found.');
  }
}

class SupabaseTeacherClassroomRepository
    implements TeacherClassroomRepository {
  SupabaseTeacherClassroomRepository(this._client);

  final SupabaseClient _client;
  late final TeacherClassesRepository _classes =
      SupabaseTeacherClassesRepository(_client);

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

  @override
  Future<TeacherClassroomList> listForAssignment(String assignmentId) async {
    final raw = await _client.rpc(
      'teacher_classroom_list',
      params: {'p_assignment_id': assignmentId},
    );
    if (raw is! Map) throw StateError('Classroom unavailable.');
    return TeacherClassroomList.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherClassroomList> create({
    required String assignmentId,
    required TeacherClassroomDraftInput input,
  }) async {
    final raw = await _client.rpc(
      'teacher_classroom_create',
      params: {
        'p_assignment_id': assignmentId,
        'p_title': input.title,
        'p_body': input.body,
        'p_publish': input.publishNow,
        'p_scheduled_publish_at': input.scheduledPublishAt?.toUtc().toIso8601String(),
        'p_expires_at': input.expiresAt?.toUtc().toIso8601String(),
        'p_requires_acknowledgement': input.requiresAcknowledgement,
      },
    );
    if (raw is! Map) throw StateError('Classroom create failed.');
    return TeacherClassroomList.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherClassroomList> update({
    required String itemId,
    required TeacherClassroomDraftInput input,
  }) async {
    final raw = await _client.rpc(
      'teacher_classroom_update',
      params: {
        'p_item_id': itemId,
        'p_title': input.title,
        'p_body': input.body,
        'p_scheduled_publish_at': input.scheduledPublishAt?.toUtc().toIso8601String(),
        'p_expires_at': input.expiresAt?.toUtc().toIso8601String(),
        'p_requires_acknowledgement': input.requiresAcknowledgement,
        'p_clear_schedule': input.clearSchedule,
        'p_clear_expiry': input.clearExpiry,
      },
    );
    if (raw is! Map) throw StateError('Classroom update failed.');
    return TeacherClassroomList.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherClassroomList> addAttachment({
    required String itemId,
    required TeacherClassroomAttachmentInput input,
  }) async {
    final raw = await _client.rpc(
      'teacher_classroom_attachment_add',
      params: {
        'p_item_id': itemId,
        'p_kind': input.kind.wire,
        'p_title': input.title,
        'p_url': input.url,
        'p_storage_bucket': input.storageBucket,
        'p_storage_path': input.storagePath,
        'p_content_type': input.contentType,
        'p_byte_size': input.byteSize,
        'p_checksum': input.checksum,
      },
    );
    if (raw is! Map) throw StateError('Classroom attachment add failed.');
    return TeacherClassroomList.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherClassroomList> removeAttachment(String attachmentId) async {
    final raw = await _client.rpc(
      'teacher_classroom_attachment_remove',
      params: {'p_attachment_id': attachmentId},
    );
    if (raw is! Map) throw StateError('Classroom attachment remove failed.');
    return TeacherClassroomList.fromJson(Map<String, dynamic>.from(raw));
  }
}
