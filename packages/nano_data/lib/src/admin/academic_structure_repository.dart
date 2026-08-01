import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SCH-02 school-admin grades / classes / sections / subjects.
abstract class AcademicStructureRepository {
  Future<AcademicStructure> load();

  Future<AcademicStructure> createGradeLevel({
    required String name,
    int sortOrder = 0,
  });

  Future<AcademicStructure> createClass({
    required String gradeLevelId,
    required String name,
  });

  Future<AcademicStructure> createSection({
    required String classId,
    required String name,
  });

  Future<AcademicStructure> createSubject({
    required String name,
    required String code,
    String? learningSubjectId,
  });

  Future<AcademicStructure> assignSubject({
    required String classId,
    required String schoolSubjectId,
    String? sectionId,
  });

  Future<AcademicStructure> archive({
    required String kind,
    required String id,
  });
}

class FakeAcademicStructureRepository implements AcademicStructureRepository {
  FakeAcademicStructureRepository({AcademicStructure? seed})
      : _structure = seed ??
            AcademicStructure(
              schoolId: TenancyFixtures.alphaSchoolId,
              gradeLevels: const [
                GradeLevelRow(
                  id: 'grade-5',
                  name: 'Grade 5',
                  sortOrder: 5,
                  status: 'active',
                ),
              ],
              classes: const [
                SchoolClassRow(
                  id: 'class-5a',
                  gradeLevelId: 'grade-5',
                  name: '5-A',
                  status: 'active',
                ),
              ],
              sections: const [
                SectionRow(
                  id: 'sec-1',
                  classId: 'class-5a',
                  name: 'Morning',
                  status: 'active',
                ),
              ],
              subjects: const [
                SchoolSubjectRow(
                  id: 'subj-math',
                  name: 'Mathematics',
                  code: 'MATH',
                  status: 'active',
                ),
              ],
              classSubjects: const [
                ClassSubjectRow(
                  id: 'map-1',
                  classId: 'class-5a',
                  schoolSubjectId: 'subj-math',
                  status: 'active',
                ),
              ],
            );

  AcademicStructure _structure;
  var alwaysFail = false;
  var createCount = 0;

  @override
  Future<AcademicStructure> load() async {
    if (alwaysFail) throw StateError('Academic structure unavailable');
    return _withIssues(_structure);
  }

  @override
  Future<AcademicStructure> createGradeLevel({
    required String name,
    int sortOrder = 0,
  }) async {
    _guard();
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw StateError('Grade name is required.');
    createCount++;
    _structure = AcademicStructure(
      schoolId: _structure.schoolId,
      gradeLevels: [
        ..._structure.gradeLevels,
        GradeLevelRow(
          id: 'grade-${_structure.gradeLevels.length + 1}',
          name: trimmed,
          sortOrder: sortOrder,
          status: 'active',
        ),
      ],
      classes: _structure.classes,
      sections: _structure.sections,
      subjects: _structure.subjects,
      classSubjects: _structure.classSubjects,
    );
    return _withIssues(_structure);
  }

  @override
  Future<AcademicStructure> createClass({
    required String gradeLevelId,
    required String name,
  }) async {
    _guard();
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw StateError('Class name is required.');
    GradeLevelRow? grade;
    for (final g in _structure.gradeLevels) {
      if (g.id == gradeLevelId) {
        grade = g;
        break;
      }
    }
    if (grade == null || !grade.isActive) {
      throw StateError('Unknown grade level.');
    }
    createCount++;
    _structure = AcademicStructure(
      schoolId: _structure.schoolId,
      gradeLevels: _structure.gradeLevels,
      classes: [
        ..._structure.classes,
        SchoolClassRow(
          id: 'class-${_structure.classes.length + 1}',
          gradeLevelId: gradeLevelId,
          name: trimmed,
          status: 'active',
        ),
      ],
      sections: _structure.sections,
      subjects: _structure.subjects,
      classSubjects: _structure.classSubjects,
    );
    return _withIssues(_structure);
  }

  @override
  Future<AcademicStructure> createSection({
    required String classId,
    required String name,
  }) async {
    _guard();
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw StateError('Section name is required.');
    createCount++;
    _structure = AcademicStructure(
      schoolId: _structure.schoolId,
      gradeLevels: _structure.gradeLevels,
      classes: _structure.classes,
      sections: [
        ..._structure.sections,
        SectionRow(
          id: 'sec-${_structure.sections.length + 1}',
          classId: classId,
          name: trimmed,
          status: 'active',
        ),
      ],
      subjects: _structure.subjects,
      classSubjects: _structure.classSubjects,
    );
    return _withIssues(_structure);
  }

  @override
  Future<AcademicStructure> createSubject({
    required String name,
    required String code,
    String? learningSubjectId,
  }) async {
    _guard();
    final trimmedName = name.trim();
    final trimmedCode = code.trim().toUpperCase();
    if (trimmedName.isEmpty) throw StateError('Subject name is required.');
    if (trimmedCode.isEmpty) throw StateError('Subject code is required.');
    createCount++;
    _structure = AcademicStructure(
      schoolId: _structure.schoolId,
      gradeLevels: _structure.gradeLevels,
      classes: _structure.classes,
      sections: _structure.sections,
      subjects: [
        ..._structure.subjects,
        SchoolSubjectRow(
          id: 'subj-${_structure.subjects.length + 1}',
          name: trimmedName,
          code: trimmedCode,
          status: 'active',
          learningSubjectId: learningSubjectId,
        ),
      ],
      classSubjects: _structure.classSubjects,
    );
    return _withIssues(_structure);
  }

  @override
  Future<AcademicStructure> assignSubject({
    required String classId,
    required String schoolSubjectId,
    String? sectionId,
  }) async {
    _guard();
    createCount++;
    _structure = AcademicStructure(
      schoolId: _structure.schoolId,
      gradeLevels: _structure.gradeLevels,
      classes: _structure.classes,
      sections: _structure.sections,
      subjects: _structure.subjects,
      classSubjects: [
        ..._structure.classSubjects,
        ClassSubjectRow(
          id: 'map-${_structure.classSubjects.length + 1}',
          classId: classId,
          sectionId: sectionId,
          schoolSubjectId: schoolSubjectId,
          status: 'active',
        ),
      ],
    );
    return _withIssues(_structure);
  }

  @override
  Future<AcademicStructure> archive({
    required String kind,
    required String id,
  }) async {
    _guard();
    List<GradeLevelRow> grades = _structure.gradeLevels;
    List<SchoolClassRow> classes = _structure.classes;
    List<SectionRow> sections = _structure.sections;
    List<SchoolSubjectRow> subjects = _structure.subjects;
    List<ClassSubjectRow> maps = _structure.classSubjects;

    switch (kind) {
      case AcademicStructureKind.gradeLevel:
        grades = [
          for (final g in grades)
            if (g.id == id)
              GradeLevelRow(
                id: g.id,
                name: g.name,
                sortOrder: g.sortOrder,
                status: 'archived',
              )
            else
              g,
        ];
      case AcademicStructureKind.classUnit:
        classes = [
          for (final c in classes)
            if (c.id == id)
              SchoolClassRow(
                id: c.id,
                gradeLevelId: c.gradeLevelId,
                name: c.name,
                status: 'archived',
              )
            else
              c,
        ];
      case AcademicStructureKind.section:
        sections = [
          for (final s in sections)
            if (s.id == id)
              SectionRow(
                id: s.id,
                classId: s.classId,
                name: s.name,
                status: 'archived',
              )
            else
              s,
        ];
      case AcademicStructureKind.schoolSubject:
        subjects = [
          for (final s in subjects)
            if (s.id == id)
              SchoolSubjectRow(
                id: s.id,
                name: s.name,
                code: s.code,
                status: 'archived',
                learningSubjectId: s.learningSubjectId,
              )
            else
              s,
        ];
      case AcademicStructureKind.classSubject:
        maps = [
          for (final m in maps)
            if (m.id == id)
              ClassSubjectRow(
                id: m.id,
                classId: m.classId,
                sectionId: m.sectionId,
                schoolSubjectId: m.schoolSubjectId,
                status: 'archived',
              )
            else
              m,
        ];
      default:
        throw StateError('Unknown academic structure kind.');
    }

    _structure = AcademicStructure(
      schoolId: _structure.schoolId,
      gradeLevels: grades,
      classes: classes,
      sections: sections,
      subjects: subjects,
      classSubjects: maps,
    );
    return _withIssues(_structure);
  }

  void _guard() {
    if (alwaysFail) throw StateError('Academic structure write failed');
  }

  AcademicStructure _withIssues(AcademicStructure structure) {
    final issues = <MappingIssue>[
      for (final c in structure.activeClasses)
        if (!structure.classSubjects
            .any((m) => m.classId == c.id && m.isActive))
          MappingIssue(
            kind: 'missing_subjects',
            classId: c.id,
            className: c.name,
          ),
    ];
    return AcademicStructure(
      schoolId: structure.schoolId,
      gradeLevels: structure.gradeLevels,
      classes: structure.classes,
      sections: structure.sections,
      subjects: structure.subjects,
      classSubjects: structure.classSubjects,
      mappingIssues: issues,
    );
  }
}

class SupabaseAcademicStructureRepository
    implements AcademicStructureRepository {
  SupabaseAcademicStructureRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AcademicStructure> load() async {
    final raw = await _client.rpc('list_academic_structure');
    return _parse(raw);
  }

  @override
  Future<AcademicStructure> createGradeLevel({
    required String name,
    int sortOrder = 0,
  }) async {
    final raw = await _client.rpc(
      'create_grade_level',
      params: {'p_name': name, 'p_sort_order': sortOrder},
    );
    return _parse(raw);
  }

  @override
  Future<AcademicStructure> createClass({
    required String gradeLevelId,
    required String name,
  }) async {
    final raw = await _client.rpc(
      'create_class',
      params: {'p_grade_level_id': gradeLevelId, 'p_name': name},
    );
    return _parse(raw);
  }

  @override
  Future<AcademicStructure> createSection({
    required String classId,
    required String name,
  }) async {
    final raw = await _client.rpc(
      'create_section',
      params: {'p_class_id': classId, 'p_name': name},
    );
    return _parse(raw);
  }

  @override
  Future<AcademicStructure> createSubject({
    required String name,
    required String code,
    String? learningSubjectId,
  }) async {
    final raw = await _client.rpc(
      'create_school_subject',
      params: {
        'p_name': name,
        'p_code': code,
        'p_learning_subject_id': learningSubjectId,
      },
    );
    return _parse(raw);
  }

  @override
  Future<AcademicStructure> assignSubject({
    required String classId,
    required String schoolSubjectId,
    String? sectionId,
  }) async {
    final raw = await _client.rpc(
      'assign_class_subject',
      params: {
        'p_class_id': classId,
        'p_school_subject_id': schoolSubjectId,
        'p_section_id': sectionId,
      },
    );
    return _parse(raw);
  }

  @override
  Future<AcademicStructure> archive({
    required String kind,
    required String id,
  }) async {
    final raw = await _client.rpc(
      'archive_academic_structure',
      params: {'p_kind': kind, 'p_id': id},
    );
    return _parse(raw);
  }

  AcademicStructure _parse(Object? raw) {
    if (raw is! Map) {
      throw StateError('Academic structure unavailable.');
    }
    return AcademicStructure.fromJson(Map<String, dynamic>.from(raw));
  }
}
