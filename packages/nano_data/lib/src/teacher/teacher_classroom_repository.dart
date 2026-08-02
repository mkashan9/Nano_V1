import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'teacher_classes_repository.dart';

/// CLS-01 classroom announcements scoped to teacher assignments.
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
}

class FakeTeacherClassroomRepository implements TeacherClassroomRepository {
  FakeTeacherClassroomRepository({
    TeacherClassesRepository? classesRepository,
  }) : _classes = classesRepository ?? FakeTeacherClassesRepository();

  final TeacherClassesRepository _classes;
  final Map<String, List<TeacherClassroomItem>> _byAssignment = {};
  var _seq = 0;
  var alwaysFail = false;

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

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
    return TeacherClassroomList(
      assignmentId: assignmentId,
      schoolId: mine.schoolId,
      classLabel: scope.classLabel,
      subjectCode: scope.subjectCode,
      items: List.unmodifiable(_byAssignment[assignmentId] ?? const []),
      generatedAt: DateTime.utc(2026, 8, 2),
    );
  }

  @override
  Future<TeacherClassroomList> create({
    required String assignmentId,
    required TeacherClassroomDraftInput input,
  }) async {
    if (alwaysFail) throw StateError('Classroom unavailable');
    final title = input.title.trim();
    if (title.isEmpty) throw StateError('Title is required.');
    final list = await listForAssignment(assignmentId);
    _seq += 1;
    final status = input.publishNow
        ? ClassroomItemStatus.published
        : ClassroomItemStatus.draft;
    final row = TeacherClassroomItem(
      id: 'cls-$_seq',
      schoolId: list.schoolId,
      teacherAssignmentId: assignmentId,
      title: title,
      body: input.body,
      status: status,
      publishedAt: input.publishNow ? DateTime.utc(2026, 8, 2) : null,
      createdAt: DateTime.utc(2026, 8, 2),
      updatedAt: DateTime.utc(2026, 8, 2),
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
    for (final entry in _byAssignment.entries) {
      final idx = entry.value.indexWhere((i) => i.id == itemId);
      if (idx < 0) continue;
      final existing = entry.value[idx];
      if (!existing.isDraft) {
        throw StateError('Only draft announcements can be edited.');
      }
      final copy = List<TeacherClassroomItem>.from(entry.value);
      copy[idx] = TeacherClassroomItem(
        id: existing.id,
        schoolId: existing.schoolId,
        teacherAssignmentId: existing.teacherAssignmentId,
        title: title,
        body: input.body,
        status: existing.status,
        publishedAt: existing.publishedAt,
        createdAt: existing.createdAt,
        updatedAt: DateTime.utc(2026, 8, 2),
      );
      _byAssignment[entry.key] = copy;
      return listForAssignment(entry.key);
    }
    throw StateError('Announcement not found.');
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
      },
    );
    if (raw is! Map) throw StateError('Classroom update failed.');
    return TeacherClassroomList.fromJson(Map<String, dynamic>.from(raw));
  }
}
