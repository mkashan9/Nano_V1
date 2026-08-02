import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('creates and updates draft classroom announcements', () async {
    final repo = FakeTeacherClassroomRepository();
    final created = await repo.create(
      assignmentId: 'asg-1',
      input: const TeacherClassroomDraftInput(
        title: 'Quiz tomorrow',
        body: 'Chapter 3',
      ),
    );
    expect(created.items, hasLength(1));
    expect(created.items.first.isDraft, isTrue);

    final updated = await repo.update(
      itemId: created.items.first.id,
      input: const TeacherClassroomDraftInput(
        title: 'Quiz Friday',
        body: 'Chapter 3 + 4',
      ),
    );
    expect(updated.items.first.title, 'Quiz Friday');
    expect(updated.items.first.body, 'Chapter 3 + 4');
  });

  test('publish-now creates published item; draft-only edit', () async {
    final repo = FakeTeacherClassroomRepository();
    final published = await repo.create(
      assignmentId: 'asg-1',
      input: const TeacherClassroomDraftInput(
        title: 'Posted',
        publishNow: true,
      ),
    );
    expect(published.items.first.status, ClassroomItemStatus.published);
    expect(
      () => repo.update(
        itemId: published.items.first.id,
        input: const TeacherClassroomDraftInput(title: 'Nope'),
      ),
      throwsStateError,
    );
  });
}
