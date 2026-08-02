import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'teacher_classes_repository.dart';

/// MRK-01 teacher assessment create/list/update (draft).
abstract class TeacherAssessmentRepository {
  Future<TeacherMyClasses> listAssignments();
  Future<TeacherAssessmentList> listForAssignment(String assignmentId);
  Future<TeacherAssessmentList> create({
    required String assignmentId,
    required TeacherAssessmentDraftInput input,
  });
  Future<TeacherAssessmentList> update({
    required String assessmentId,
    required TeacherAssessmentDraftInput input,
  });
}

class FakeTeacherAssessmentRepository implements TeacherAssessmentRepository {
  FakeTeacherAssessmentRepository({
    TeacherClassesRepository? classesRepository,
  }) : _classes = classesRepository ?? FakeTeacherClassesRepository();

  final TeacherClassesRepository _classes;
  final Map<String, List<TeacherAssessment>> _byAssignment = {};
  var _seq = 0;
  var alwaysFail = false;

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

  @override
  Future<TeacherAssessmentList> listForAssignment(String assignmentId) async {
    if (alwaysFail) throw StateError('Assessments unavailable');
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
    return TeacherAssessmentList(
      assignmentId: assignmentId,
      schoolId: mine.schoolId,
      classLabel: scope.classLabel,
      subjectCode: scope.subjectCode,
      assessments: List.unmodifiable(_byAssignment[assignmentId] ?? const []),
      generatedAt: DateTime.utc(2026, 8, 2),
    );
  }

  @override
  Future<TeacherAssessmentList> create({
    required String assignmentId,
    required TeacherAssessmentDraftInput input,
  }) async {
    if (alwaysFail) throw StateError('Assessments unavailable');
    _validate(input);
    final list = await listForAssignment(assignmentId);
    _seq += 1;
    final row = TeacherAssessment(
      id: 'asm-$_seq',
      schoolId: list.schoolId,
      teacherAssignmentId: assignmentId,
      category: input.category.trim(),
      name: input.name.trim(),
      assessmentDate: input.assessmentDate,
      totalMarks: input.totalMarks,
      weight: input.weight,
      description: input.description,
      status: AssessmentStatus.draft,
      resultPeriodId: input.resultPeriodId,
      createdAt: DateTime.utc(2026, 8, 2),
      updatedAt: DateTime.utc(2026, 8, 2),
    );
    _byAssignment[assignmentId] = [row, ...(_byAssignment[assignmentId] ?? const [])];
    return listForAssignment(assignmentId);
  }

  @override
  Future<TeacherAssessmentList> update({
    required String assessmentId,
    required TeacherAssessmentDraftInput input,
  }) async {
    if (alwaysFail) throw StateError('Assessments unavailable');
    _validate(input);
    for (final entry in _byAssignment.entries) {
      final idx = entry.value.indexWhere((a) => a.id == assessmentId);
      if (idx < 0) continue;
      final existing = entry.value[idx];
      if (!existing.isDraft) {
        throw StateError('Only draft assessments can be edited.');
      }
      final updated = TeacherAssessment(
        id: existing.id,
        schoolId: existing.schoolId,
        teacherAssignmentId: existing.teacherAssignmentId,
        category: input.category.trim(),
        name: input.name.trim(),
        assessmentDate: input.assessmentDate,
        totalMarks: input.totalMarks,
        weight: input.weight,
        description: input.description,
        status: AssessmentStatus.draft,
        resultPeriodId: input.resultPeriodId,
        createdAt: existing.createdAt,
        updatedAt: DateTime.utc(2026, 8, 2, 13),
      );
      final next = [...entry.value];
      next[idx] = updated;
      _byAssignment[entry.key] = next;
      return listForAssignment(entry.key);
    }
    throw StateError('Assessment not found.');
  }

  void _validate(TeacherAssessmentDraftInput input) {
    if (input.category.trim().isEmpty) {
      throw StateError('Category is required.');
    }
    if (input.name.trim().isEmpty) {
      throw StateError('Assessment name is required.');
    }
    if (input.assessmentDate.trim().isEmpty) {
      throw StateError('Assessment date is required.');
    }
    if (input.totalMarks <= 0) {
      throw StateError('Total marks must be greater than zero.');
    }
    if (input.weight != null && input.weight! < 0) {
      throw StateError('Weight cannot be negative.');
    }
  }
}

class SupabaseTeacherAssessmentRepository
    implements TeacherAssessmentRepository {
  SupabaseTeacherAssessmentRepository(this._client);

  final SupabaseClient _client;
  late final TeacherClassesRepository _classes =
      SupabaseTeacherClassesRepository(_client);

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

  @override
  Future<TeacherAssessmentList> listForAssignment(String assignmentId) async {
    final raw = await _client.rpc(
      'teacher_assessments_list',
      params: {'p_assignment_id': assignmentId},
    );
    if (raw is! Map) throw StateError('Assessments unavailable.');
    return TeacherAssessmentList.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherAssessmentList> create({
    required String assignmentId,
    required TeacherAssessmentDraftInput input,
  }) async {
    final raw = await _client.rpc(
      'teacher_assessment_create',
      params: {
        'p_assignment_id': assignmentId,
        'p_category': input.category,
        'p_name': input.name,
        'p_assessment_date': input.assessmentDate,
        'p_total_marks': input.totalMarks,
        'p_weight': input.weight,
        'p_description': input.description,
        'p_result_period_id': input.resultPeriodId,
      },
    );
    if (raw is! Map) throw StateError('Assessment create failed.');
    return TeacherAssessmentList.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherAssessmentList> update({
    required String assessmentId,
    required TeacherAssessmentDraftInput input,
  }) async {
    final raw = await _client.rpc(
      'teacher_assessment_update',
      params: {
        'p_assessment_id': assessmentId,
        'p_category': input.category,
        'p_name': input.name,
        'p_assessment_date': input.assessmentDate,
        'p_total_marks': input.totalMarks,
        'p_weight': input.weight,
        'p_description': input.description,
        'p_result_period_id': input.resultPeriodId,
      },
    );
    if (raw is! Map) throw StateError('Assessment update failed.');
    return TeacherAssessmentList.fromJson(Map<String, dynamic>.from(raw));
  }
}
