import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('lists classes and guards unknown assignment', () async {
    final repo = FakeTeacherClassesRepository();
    final mine = await repo.listMine();
    expect(mine.assignments, hasLength(2));

    final roster = await repo.loadRoster('asg-1');
    expect(roster.students, hasLength(2));

    expect(() => repo.loadRoster('unknown'), throwsStateError);

    repo.alwaysFail = true;
    expect(repo.listMine, throwsStateError);
  });
}
