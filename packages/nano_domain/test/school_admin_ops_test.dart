import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('school codes normalize and validate', () {
    expect(SchoolCodeRules.normalize(' abc01 '), 'ABC01');
    expect(SchoolCodeRules.isValid('AB'), isFalse);
    expect(SchoolCodeRules.isValid('ALPHA01'), isTrue);
  });

  test('managed school parses status wire values', () {
    final school = ManagedSchool.fromJson({
      'id': 's1',
      'code': 'GAMMA01',
      'name': 'Gamma',
      'status': 'suspended',
      'has_school_admin': true,
      'learner_count': 2,
      'staff_count': 1,
    });
    expect(school.status, SchoolStatus.suspended);
    expect(school.status.wireName, 'suspended');
  });
}
