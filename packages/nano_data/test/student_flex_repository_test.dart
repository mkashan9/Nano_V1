import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('loads flex hub for eligible students', () async {
    final repo = FakeStudentFlexRepository();
    final hub = await repo.loadHub(flexEligible: true);
    expect(hub.sections, hasLength(3));
    expect(hub.openTasks, greaterThan(0));
  });

  test('rejects ineligible accounts', () async {
    final repo = FakeStudentFlexRepository();
    expect(
      () => repo.loadHub(flexEligible: false),
      throwsStateError,
    );
  });
}
