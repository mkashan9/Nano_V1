import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'teacher_classes_repository.dart';

/// FBK-01 teacher structured feedback notes.
abstract class TeacherFeedbackRepository {
  Future<TeacherMyClasses> listAssignments();
  Future<TeacherClassRoster> loadRoster(String assignmentId);
  Future<TeacherFeedbackList> listForAssignment(String assignmentId);
  Future<TeacherFeedbackList> create({
    required String assignmentId,
    required TeacherFeedbackDraftInput input,
  });
  Future<TeacherFeedbackList> update({
    required String noteId,
    required TeacherFeedbackDraftInput input,
  });
}

class FakeTeacherFeedbackRepository implements TeacherFeedbackRepository {
  FakeTeacherFeedbackRepository({
    TeacherClassesRepository? classesRepository,
  }) : _classes = classesRepository ?? FakeTeacherClassesRepository();

  final TeacherClassesRepository _classes;
  final Map<String, List<TeacherFeedbackNote>> _byAssignment = {};
  var _seq = 0;
  var alwaysFail = false;

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

  @override
  Future<TeacherClassRoster> loadRoster(String assignmentId) =>
      _classes.loadRoster(assignmentId);

  Future<TeacherAssignmentScope> _requireScope(String assignmentId) async {
    final mine = await _classes.listMine();
    for (final a in mine.assignments) {
      if (a.id == assignmentId) return a;
    }
    throw StateError('Assignment is not in your active scope.');
  }

  Future<void> _requireRosterStudent({
    required String assignmentId,
    required String studentUserId,
  }) async {
    final roster = await _classes.loadRoster(assignmentId);
    final ok = roster.students.any((s) => s.id == studentUserId);
    if (!ok) {
      throw StateError('Student is not on this assignment roster.');
    }
  }

  String _displayName(TeacherClassRoster roster, String studentUserId) {
    for (final s in roster.students) {
      if (s.id == studentUserId) return s.displayName;
    }
    return 'Student';
  }

  @override
  Future<TeacherFeedbackList> listForAssignment(String assignmentId) async {
    if (alwaysFail) throw StateError('Feedback unavailable');
    final scope = await _requireScope(assignmentId);
    final mine = await _classes.listMine();
    final notes = _byAssignment[assignmentId] ?? const <TeacherFeedbackNote>[];
    return TeacherFeedbackList(
      assignmentId: assignmentId,
      schoolId: mine.schoolId,
      classLabel: scope.classLabel,
      subjectCode: scope.subjectCode,
      notes: List.unmodifiable(notes),
      generatedAt: DateTime.utc(2026, 8, 2),
    );
  }

  @override
  Future<TeacherFeedbackList> create({
    required String assignmentId,
    required TeacherFeedbackDraftInput input,
  }) async {
    if (alwaysFail) throw StateError('Feedback unavailable');
    final body = input.body.trim();
    if (body.isEmpty) throw StateError('Feedback body is required.');
    await _requireRosterStudent(
      assignmentId: assignmentId,
      studentUserId: input.studentUserId,
    );
    final list = await listForAssignment(assignmentId);
    final roster = await _classes.loadRoster(assignmentId);
    _seq += 1;
    final now = DateTime.utc(2026, 8, 2);
    final status = input.publishNow
        ? FeedbackNoteStatus.published
        : FeedbackNoteStatus.draft;
    final row = TeacherFeedbackNote(
      id: 'fbk-$_seq',
      schoolId: list.schoolId,
      teacherAssignmentId: assignmentId,
      studentUserId: input.studentUserId,
      studentDisplayName: _displayName(roster, input.studentUserId),
      category: input.category,
      body: body,
      status: status,
      publishedAt: input.publishNow ? now : null,
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
  Future<TeacherFeedbackList> update({
    required String noteId,
    required TeacherFeedbackDraftInput input,
  }) async {
    if (alwaysFail) throw StateError('Feedback unavailable');
    final body = input.body.trim();
    if (body.isEmpty) throw StateError('Feedback body is required.');
    for (final entry in _byAssignment.entries) {
      final idx = entry.value.indexWhere((n) => n.id == noteId);
      if (idx < 0) continue;
      final existing = entry.value[idx];
      if (!existing.isDraft) {
        throw StateError('Only draft feedback notes can be edited.');
      }
      await _requireRosterStudent(
        assignmentId: entry.key,
        studentUserId: input.studentUserId,
      );
      final roster = await _classes.loadRoster(entry.key);
      final now = DateTime.utc(2026, 8, 2);
      final status = input.publishNow
          ? FeedbackNoteStatus.published
          : FeedbackNoteStatus.draft;
      final copy = List<TeacherFeedbackNote>.from(entry.value);
      copy[idx] = TeacherFeedbackNote(
        id: existing.id,
        schoolId: existing.schoolId,
        teacherAssignmentId: existing.teacherAssignmentId,
        studentUserId: input.studentUserId,
        studentDisplayName: _displayName(roster, input.studentUserId),
        category: input.category,
        body: body,
        status: status,
        publishedAt: input.publishNow ? now : existing.publishedAt,
        createdAt: existing.createdAt,
        updatedAt: now,
      );
      _byAssignment[entry.key] = copy;
      return listForAssignment(entry.key);
    }
    throw StateError('Feedback note not found.');
  }
}

class SupabaseTeacherFeedbackRepository implements TeacherFeedbackRepository {
  SupabaseTeacherFeedbackRepository(this._client);

  final SupabaseClient _client;
  late final TeacherClassesRepository _classes =
      SupabaseTeacherClassesRepository(_client);

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

  @override
  Future<TeacherClassRoster> loadRoster(String assignmentId) =>
      _classes.loadRoster(assignmentId);

  @override
  Future<TeacherFeedbackList> listForAssignment(String assignmentId) async {
    final raw = await _client.rpc(
      'teacher_feedback_list',
      params: {'p_assignment_id': assignmentId},
    );
    if (raw is! Map) throw StateError('Feedback unavailable.');
    return TeacherFeedbackList.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherFeedbackList> create({
    required String assignmentId,
    required TeacherFeedbackDraftInput input,
  }) async {
    final raw = await _client.rpc(
      'teacher_feedback_create',
      params: {
        'p_assignment_id': assignmentId,
        'p_student_user_id': input.studentUserId,
        'p_category': input.category.wire,
        'p_body': input.body,
        'p_publish': input.publishNow,
      },
    );
    if (raw is! Map) throw StateError('Feedback create failed.');
    return TeacherFeedbackList.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherFeedbackList> update({
    required String noteId,
    required TeacherFeedbackDraftInput input,
  }) async {
    final raw = await _client.rpc(
      'teacher_feedback_update',
      params: {
        'p_note_id': noteId,
        'p_category': input.category.wire,
        'p_body': input.body,
        'p_publish': input.publishNow,
      },
    );
    if (raw is! Map) throw StateError('Feedback update failed.');
    return TeacherFeedbackList.fromJson(Map<String, dynamic>.from(raw));
  }
}
