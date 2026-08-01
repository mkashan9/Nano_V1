import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses a privacy-safe dashboard payload', () {
    final dashboard = PlatformDashboard.fromJson({
      'school_count': 2,
      'active_school_count': 2,
      'learner_count': 10,
      'staff_count': 3,
      'suspended_profile_count': 0,
      'open_incident_count': 1,
      'schools': [
        {
          'id': 's1',
          'code': 'ALPHA',
          'name': 'Alpha Academy',
          'status': 'active',
          'learner_count': 8,
          'staff_count': 2,
        },
      ],
      'recent_audit': [
        {
          'action': 'other',
          'target_type': 'school',
          'created_at': '2026-08-02T00:00:00Z',
          'school_code': 'ALPHA',
        },
      ],
    });
    expect(dashboard.schoolCount, 2);
    expect(dashboard.schools.single.code, 'ALPHA');
    expect(dashboard.recentAudit.single.schoolCode, 'ALPHA');
  });

  test('school summary rejects email keys', () {
    expect(
      () => SchoolDirectoryEntry.fromJson({
        'id': 's1',
        'code': 'ALPHA',
        'name': 'Alpha',
        'status': 'active',
        'email': 'admin@example.dev',
      }),
      throwsStateError,
    );
  });

  test('query match is case-insensitive on name and code', () {
    const school = SchoolDirectoryEntry(
      id: 's1',
      code: 'ALPHA',
      name: 'Alpha Academy',
      status: 'active',
    );
    expect(school.matchesQuery('alp'), isTrue);
    expect(school.matchesQuery('BETA'), isFalse);
  });
}
