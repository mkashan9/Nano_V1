import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses teacher and csv template', () {
    final teacher = SchoolTeacher.fromJson({
      'id': TenancyFixtures.teacherId,
      'display_name': 'Ms. Khan',
      'email': 'teacher@alpha.nano.dev',
      'profile_status': 'active',
      'membership_status': 'active',
    });
    expect(teacher.email, contains('@'));
    expect(TeacherImportCsv.parse(TeacherImportCsv.template), hasLength(1));
  });
}
