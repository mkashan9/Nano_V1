import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('creates grade class subject and reports missing maps', () async {
    final repo = FakeAcademicStructureRepository(
      seed: AcademicStructure(
        schoolId: TenancyFixtures.alphaSchoolId,
        gradeLevels: const [],
        classes: const [],
        sections: const [],
        subjects: const [],
        classSubjects: const [],
      ),
    );

    var structure = await repo.createGradeLevel(name: 'Grade 4');
    expect(structure.activeGrades, hasLength(1));

    structure = await repo.createClass(
      gradeLevelId: structure.activeGrades.first.id,
      name: '4-B',
    );
    expect(structure.activeClasses, hasLength(1));
    expect(structure.mappingIssues, isNotEmpty);

    structure = await repo.createSubject(name: 'Science', code: 'sci');
    expect(structure.subjects.single.code, 'SCI');

    structure = await repo.assignSubject(
      classId: structure.activeClasses.first.id,
      schoolSubjectId: structure.subjects.single.id,
    );
    expect(structure.mappingIssues, isEmpty);

    structure = await repo.archive(
      kind: AcademicStructureKind.classUnit,
      id: structure.activeClasses.first.id,
    );
    expect(structure.activeClasses, isEmpty);
  });

  test('rejects empty grade name', () async {
    final repo = FakeAcademicStructureRepository();
    expect(
      () => repo.createGradeLevel(name: '  '),
      throwsStateError,
    );
  });
}
