import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses student and csv template', () {
    final student = SchoolStudent.fromJson({
      'id': TenancyFixtures.aliAlphaId,
      'display_name': 'Ali',
      'email': 'ali@alpha.nano.dev',
      'profile_status': 'active',
      'membership_status': 'active',
      'class_name': '5-A',
    });
    expect(student.className, '5-A');
    expect(StudentImportCsv.parse(StudentImportCsv.template), hasLength(1));
  });
}
