import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('lists creates suspends and blocks bad import commit', () async {
    final repo = FakeSchoolStudentRepository();
    expect(await repo.list(), hasLength(1));

    final created = await repo.create(
      displayName: 'New Student',
      email: 'new@alpha.nano.dev',
      classId: 'class-5a',
    );
    expect(created.tempPassword, isNotEmpty);
    expect(created.students, hasLength(2));

    final suspended = await repo.setStatus(
      userId: created.student.id,
      status: 'suspended',
      reason: 'transfer',
    );
    expect(
      suspended.singleWhere((s) => s.id == created.student.id).isSuspended,
      isTrue,
    );

    final blocked = await repo.commitImport([
      {'display_name': 'Dup', 'email': 'ali@alpha.nano.dev'},
    ]);
    expect(blocked.committed, isFalse);
  });
}
