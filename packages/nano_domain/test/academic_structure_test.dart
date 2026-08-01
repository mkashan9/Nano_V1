import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses academic structure and mapping issues', () {
    final structure = AcademicStructure.fromJson({
      'school_id': TenancyFixtures.alphaSchoolId,
      'grade_levels': [
        {
          'id': 'g1',
          'name': 'Grade 5',
          'sort_order': 5,
          'status': 'active',
        },
      ],
      'classes': [
        {
          'id': 'c1',
          'grade_level_id': 'g1',
          'name': '5-A',
          'status': 'active',
        },
      ],
      'sections': [],
      'subjects': [
        {
          'id': 's1',
          'name': 'Math',
          'code': 'MATH',
          'status': 'active',
        },
      ],
      'class_subjects': [],
      'mapping_issues': [
        {
          'kind': 'missing_subjects',
          'class_id': 'c1',
          'class_name': '5-A',
        },
      ],
    });

    expect(structure.activeClasses, hasLength(1));
    expect(structure.mappingIssues.single.className, '5-A');
    expect(AcademicStructureKind.classUnit, 'class');
  });
}
