import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses school dashboard and setup steps', () {
    final dashboard = SchoolDashboard.fromJson({
      'school_id': TenancyFixtures.alphaSchoolId,
      'code': 'ALPHA01',
      'name': 'Alpha Academy',
      'display_name': 'Alpha Academy',
      'status': 'active',
      'primary_color': '#2F7BFF',
      'secondary_color': '#1B4F9C',
      'learner_count': 30,
      'staff_count': 4,
      'teacher_count': 3,
      'class_count': 0,
      'setup': {
        'has_admin': true,
        'branding_ready': true,
        'contact_ready': false,
        'academic_year_ready': true,
        'setup_completed': false,
      },
    });
    expect(dashboard.setupStepsDone, 3);
    expect(SchoolBrandColorRules.isValid('#aabbcc'), isTrue);
    expect(SchoolBrandColorRules.isValid('red'), isFalse);
  });
}
