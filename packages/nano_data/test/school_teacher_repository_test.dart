import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('lists creates suspends and blocks bad import commit', () async {
    final repo = FakeSchoolTeacherRepository();
    expect(await repo.list(), hasLength(1));

    final created = await repo.create(
      displayName: 'New Teacher',
      email: 'new@alpha.nano.dev',
    );
    expect(created.tempPassword, isNotEmpty);
    expect(created.teachers, hasLength(2));

    final suspended = await repo.setStatus(
      userId: created.teacher.id,
      status: 'suspended',
      reason: 'leave',
    );
    expect(suspended.singleWhere((t) => t.id == created.teacher.id).isSuspended,
        isTrue);

    final preview = await repo.previewImport([
      {'display_name': 'Dup', 'email': 'teacher@alpha.nano.dev'},
    ]);
    expect(preview.canCommit, isFalse);

    final blocked = await repo.commitImport([
      {'display_name': 'Dup', 'email': 'teacher@alpha.nano.dev'},
    ]);
    expect(blocked.committed, isFalse);
  });
}
