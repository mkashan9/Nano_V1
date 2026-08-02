import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('creates draft and publishes feedback for roster students', () async {
    final repo = FakeTeacherFeedbackRepository();
    final created = await repo.create(
      assignmentId: 'asg-1',
      input: TeacherFeedbackDraftInput(
        studentUserId: TenancyFixtures.aliAlphaId,
        category: FeedbackCategory.effort,
        body: 'Strong focus this week.',
      ),
    );
    expect(created.notes, hasLength(1));
    expect(created.notes.first.isDraft, isTrue);
    expect(created.notes.first.studentDisplayName, 'Ali Khan');

    final published = await repo.update(
      noteId: created.notes.first.id,
      input: TeacherFeedbackDraftInput(
        studentUserId: TenancyFixtures.aliAlphaId,
        category: FeedbackCategory.progress,
        body: 'Strong focus — improving.',
        publishNow: true,
      ),
    );
    expect(published.notes.first.status, FeedbackNoteStatus.published);
    expect(published.notes.first.category, FeedbackCategory.progress);
  });

  test('rejects students outside roster', () async {
    final repo = FakeTeacherFeedbackRepository();
    expect(
      () => repo.create(
        assignmentId: 'asg-1',
        input: const TeacherFeedbackDraftInput(
          studentUserId: 'not-on-roster',
          category: FeedbackCategory.behavior,
          body: 'Nope',
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('published notes cannot be edited', () async {
    final repo = FakeTeacherFeedbackRepository();
    final created = await repo.create(
      assignmentId: 'asg-1',
      input: TeacherFeedbackDraftInput(
        studentUserId: TenancyFixtures.aliAlphaId,
        category: FeedbackCategory.effort,
        body: 'Done',
        publishNow: true,
      ),
    );
    expect(
      () => repo.update(
        noteId: created.notes.first.id,
        input: TeacherFeedbackDraftInput(
          studentUserId: TenancyFixtures.aliAlphaId,
          category: FeedbackCategory.effort,
          body: 'Changed',
        ),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
