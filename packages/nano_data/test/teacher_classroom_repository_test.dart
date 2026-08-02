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

  test('adds and removes link attachments on drafts', () async {
    final repo = FakeTeacherClassroomRepository();
    final created = await repo.create(
      assignmentId: 'asg-1',
      input: const TeacherClassroomDraftInput(title: 'Materials'),
    );
    final itemId = created.items.first.id;
    final withLink = await repo.addAttachment(
      itemId: itemId,
      input: const TeacherClassroomAttachmentInput(
        title: 'Worksheet',
        url: 'https://example.com/ws.pdf',
      ),
    );
    expect(withLink.items.first.attachments, hasLength(1));
    final removed = await repo.removeAttachment(
      withLink.items.first.attachments.first.id,
    );
    expect(removed.items.first.attachments, isEmpty);
  });

  test('schedules future publish and tracks acknowledgements', () async {
    final repo = FakeTeacherClassroomRepository();
    final created = await repo.create(
      assignmentId: 'asg-1',
      input: TeacherClassroomDraftInput(
        title: 'Parent night',
        scheduledPublishAt: DateTime.utc(2026, 9, 1),
        expiresAt: DateTime.utc(2026, 9, 15),
      ),
    );
    expect(created.items.first.isScheduled, isTrue);
    expect(created.items.first.displayStatus, 'scheduled');

    final published = await repo.create(
      assignmentId: 'asg-1',
      input: const TeacherClassroomDraftInput(
        title: 'Posted',
        publishNow: true,
      ),
    );
    final item = published.items.firstWhere((i) => i.title == 'Posted');
    expect(item.status, ClassroomItemStatus.published);
    expect(item.rosterCount, 2);

    await repo.recordAck(
      itemId: item.id,
      studentUserId: TenancyFixtures.aliAlphaId,
    );
    final listed = await repo.listForAssignment('asg-1');
    final again = listed.items.firstWhere((i) => i.id == item.id);
    expect(again.ackCount, 1);
    expect(again.rosterCount, 2);
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
