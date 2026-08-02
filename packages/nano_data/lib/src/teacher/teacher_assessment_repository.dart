import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'teacher_classes_repository.dart';

/// MRK-01/MRK-02/MRK-03 assessments, marks grid, and CSV import.
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
  Future<TeacherMarksGrid> loadMarks(String assessmentId);
  Future<TeacherMarksGrid> saveMarks({
    required String assessmentId,
    required List<MarksEntryMark> entries,
    String? idempotencyKey,
  });
  Future<MarksImportTemplate> loadMarksTemplate(String assessmentId);
  Future<MarksImportPreview> previewMarksImport({
    required String assessmentId,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
  });
  Future<MarksImportCommitResult> commitMarksImport({
    required String assessmentId,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
  });
}

class FakeTeacherAssessmentRepository implements TeacherAssessmentRepository {
  FakeTeacherAssessmentRepository({
    TeacherClassesRepository? classesRepository,
  }) : _classes = classesRepository ?? FakeTeacherClassesRepository();

  final TeacherClassesRepository _classes;
  final Map<String, List<TeacherAssessment>> _byAssignment = {};
  final Map<String, TeacherMarksGrid> _grids = {};
  var allowBonus = false;
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

  TeacherAssessment? _findAssessment(String assessmentId) {
    for (final list in _byAssignment.values) {
      for (final a in list) {
        if (a.id == assessmentId) return a;
      }
    }
    return null;
  }

  @override
  Future<TeacherMarksGrid> loadMarks(String assessmentId) async {
    if (alwaysFail) throw StateError('Marks unavailable');
    final existing = _grids[assessmentId];
    if (existing != null) return existing;

    final assessment = _findAssessment(assessmentId);
    if (assessment == null) {
      throw StateError('Assessment not found.');
    }
    final roster = await _classes.loadRoster(assessment.teacherAssignmentId);
    final grid = TeacherMarksGrid(
      assessmentId: assessment.id,
      assignmentId: assessment.teacherAssignmentId,
      schoolId: assessment.schoolId,
      assessmentName: assessment.name,
      category: assessment.category,
      assessmentDate: assessment.assessmentDate,
      totalMarks: assessment.totalMarks,
      assessmentStatus: assessment.status,
      allowBonus: allowBonus,
      classLabel: (await listForAssignment(assessment.teacherAssignmentId))
          .classLabel,
      subjectCode: (await listForAssignment(assessment.teacherAssignmentId))
          .subjectCode,
      roster: [
        for (final s in roster.students)
          MarksRosterStudent(id: s.id, displayName: s.displayName),
      ],
      entries: const [],
      generatedAt: DateTime.utc(2026, 8, 2),
    );
    _grids[assessmentId] = grid;
    return grid;
  }

  @override
  Future<TeacherMarksGrid> saveMarks({
    required String assessmentId,
    required List<MarksEntryMark> entries,
    String? idempotencyKey,
  }) async {
    if (alwaysFail) throw StateError('Marks unavailable');
    final base = await loadMarks(assessmentId);
    if (!base.isDraft) {
      throw StateError('Marks can only be edited on draft assessments.');
    }
    final rosterIds = {for (final s in base.roster) s.id};
    for (final e in entries) {
      if (!rosterIds.contains(e.studentUserId)) {
        throw StateError('Student is not on the assigned roster.');
      }
      if (e.status == MarksEntryStatus.scored) {
        final obtained = e.obtainedMarks;
        if (obtained == null || obtained < 0) {
          throw StateError('Obtained marks required for scored entries.');
        }
        if (obtained > base.totalMarks && !base.allowBonus) {
          throw StateError(
            'Obtained marks cannot exceed total unless bonus is allowed.',
          );
        }
      }
    }
    final grid = TeacherMarksGrid(
      assessmentId: base.assessmentId,
      assignmentId: base.assignmentId,
      schoolId: base.schoolId,
      assessmentName: base.assessmentName,
      category: base.category,
      assessmentDate: base.assessmentDate,
      totalMarks: base.totalMarks,
      assessmentStatus: base.assessmentStatus,
      allowBonus: base.allowBonus,
      classLabel: base.classLabel,
      subjectCode: base.subjectCode,
      roster: base.roster,
      entries: entries,
      generatedAt: DateTime.utc(2026, 8, 2),
    );
    _grids[assessmentId] = grid;
    return grid;
  }

  @override
  Future<MarksImportTemplate> loadMarksTemplate(String assessmentId) async {
    final grid = await loadMarks(assessmentId);
    return MarksImportTemplate(
      assessmentId: grid.assessmentId,
      assignmentId: grid.assignmentId,
      assessmentName: grid.assessmentName,
      totalMarks: grid.totalMarks,
      classLabel: grid.classLabel,
      subjectCode: grid.subjectCode,
      headers: const [
        'student_user_id',
        'display_name',
        'status',
        'obtained_marks',
        'remarks',
      ],
      rows: [
        for (final s in grid.roster)
          {
            'student_user_id': s.id,
            'display_name': s.displayName,
            'status': (grid.entryByStudent[s.id]?.status ??
                    MarksEntryStatus.notSubmitted)
                .wire,
            'obtained_marks':
                grid.entryByStudent[s.id]?.obtainedMarks?.toString() ?? '',
            'remarks': grid.entryByStudent[s.id]?.remarks ?? '',
          },
      ],
    );
  }

  @override
  Future<MarksImportPreview> previewMarksImport({
    required String assessmentId,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
  }) async {
    if (alwaysFail) throw StateError('Marks unavailable');
    final grid = await loadMarks(assessmentId);
    if (!grid.isDraft) {
      throw StateError('Marks can only be imported on draft assessments.');
    }
    final rosterIds = {for (final s in grid.roster) s.id};
    final ok = <MarksImportOkRow>[];
    final fail = <MarksImportFailure>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final id = (row['student_user_id'] ?? '').trim();
      final status = (row['status'] ?? '').trim().toLowerCase();
      final obtainedText = (row['obtained_marks'] ?? '').trim();
      if (id.isEmpty || !rosterIds.contains(id)) {
        fail.add(MarksImportFailure(
          row: i + 1,
          studentUserId: id,
          error: 'student not on assigned roster',
        ));
        continue;
      }
      if (!{'scored', 'absent', 'exempt', 'not_submitted'}.contains(status)) {
        fail.add(MarksImportFailure(
          row: i + 1,
          studentUserId: id,
          error: 'invalid status',
        ));
        continue;
      }
      double? obtained;
      if (status == 'scored') {
        obtained = double.tryParse(obtainedText);
        if (obtained == null || obtained < 0) {
          fail.add(MarksImportFailure(
            row: i + 1,
            studentUserId: id,
            error: 'invalid obtained_marks',
          ));
          continue;
        }
        if (obtained > grid.totalMarks && !grid.allowBonus) {
          fail.add(MarksImportFailure(
            row: i + 1,
            studentUserId: id,
            error: 'obtained_marks exceeds total',
          ));
          continue;
        }
      }
      ok.add(MarksImportOkRow(
        row: i + 1,
        studentUserId: id,
        status: status,
        obtainedMarks: obtained,
        remarks: row['remarks'] ?? '',
      ));
    }
    return MarksImportPreview(
      jobId: 'job-$assessmentId',
      assessmentId: assessmentId,
      okCount: ok.length,
      failCount: fail.length,
      okRows: ok,
      failedRows: fail,
      canCommit: fail.isEmpty && ok.isNotEmpty,
    );
  }

  @override
  Future<MarksImportCommitResult> commitMarksImport({
    required String assessmentId,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
  }) async {
    final preview = await previewMarksImport(
      assessmentId: assessmentId,
      idempotencyKey: idempotencyKey,
      rows: rows,
    );
    if (!preview.canCommit) {
      throw StateError('Marks import has validation errors.');
    }
    final grid = await saveMarks(
      assessmentId: assessmentId,
      idempotencyKey: idempotencyKey,
      entries: [
        for (final r in preview.okRows)
          MarksEntryMark(
            studentUserId: r.studentUserId,
            status: MarksEntryStatus.parse(r.status),
            obtainedMarks: r.obtainedMarks,
            remarks: r.remarks,
          ),
      ],
    );
    return MarksImportCommitResult(
      committed: true,
      message: 'Marks import committed.',
      preview: preview,
      grid: grid,
    );
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

  @override
  Future<TeacherMarksGrid> loadMarks(String assessmentId) async {
    final raw = await _client.rpc(
      'teacher_marks_load',
      params: {'p_assessment_id': assessmentId},
    );
    if (raw is! Map) throw StateError('Marks unavailable.');
    return TeacherMarksGrid.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherMarksGrid> saveMarks({
    required String assessmentId,
    required List<MarksEntryMark> entries,
    String? idempotencyKey,
  }) async {
    final raw = await _client.rpc(
      'teacher_marks_save',
      params: {
        'p_assessment_id': assessmentId,
        'p_entries': [for (final e in entries) e.toWire()],
        'p_idempotency_key': idempotencyKey,
      },
    );
    if (raw is! Map) throw StateError('Marks save failed.');
    return TeacherMarksGrid.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<MarksImportTemplate> loadMarksTemplate(String assessmentId) async {
    final raw = await _client.rpc(
      'teacher_marks_template',
      params: {'p_assessment_id': assessmentId},
    );
    if (raw is! Map) throw StateError('Marks template unavailable.');
    return MarksImportTemplate.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<MarksImportPreview> previewMarksImport({
    required String assessmentId,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
  }) async {
    final raw = await _client.rpc(
      'preview_marks_import',
      params: {
        'p_assessment_id': assessmentId,
        'p_idempotency_key': idempotencyKey,
        'p_rows': rows,
      },
    );
    if (raw is! Map) throw StateError('Marks import preview failed.');
    return MarksImportPreview.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<MarksImportCommitResult> commitMarksImport({
    required String assessmentId,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
  }) async {
    final raw = await _client.rpc(
      'commit_marks_import',
      params: {
        'p_assessment_id': assessmentId,
        'p_idempotency_key': idempotencyKey,
        'p_rows': rows,
      },
    );
    if (raw is! Map) throw StateError('Marks import commit failed.');
    return MarksImportCommitResult.fromJson(Map<String, dynamic>.from(raw));
  }
}
