import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// FLX-04 student classroom feed + acknowledgement.
abstract class StudentClassroomRepository {
  Future<StudentClassroomFeed> loadFeed();
  Future<StudentClassroomFeed> acknowledge(String itemId);
}

class FakeStudentClassroomRepository implements StudentClassroomRepository {
  FakeStudentClassroomRepository({
    List<StudentClassroomItem>? seed,
    this.alwaysFail = false,
  }) : _items = List.of(
          seed ??
              [
                StudentClassroomItem(
                  id: 'cls-1',
                  title: 'Bring notebooks',
                  body: 'Math class tomorrow.',
                  status: ClassroomItemStatus.published,
                  subjectCode: 'MATH',
                  classLabel: '5-A',
                  publishedAt: DateTime.utc(2026, 8, 1),
                  requiresAcknowledgement: true,
                  attachments: const [
                    TeacherClassroomAttachment(
                      id: 'att-1',
                      classroomItemId: 'cls-1',
                      kind: ClassroomAttachmentKind.link,
                      title: 'Worksheet',
                      url: 'https://example.com/ws.pdf',
                    ),
                  ],
                ),
                StudentClassroomItem(
                  id: 'cls-2',
                  title: 'Parent night',
                  body: 'Hall A at 5pm.',
                  status: ClassroomItemStatus.published,
                  subjectCode: 'ENG',
                  classLabel: '5-A',
                  publishedAt: DateTime.utc(2026, 7, 20),
                  expiresAt: DateTime.utc(2026, 7, 25),
                  isExpired: true,
                  requiresAcknowledgement: true,
                ),
              ],
        );

  final List<StudentClassroomItem> _items;
  var alwaysFail;

  StudentClassroomFeed _feed() => StudentClassroomFeed(
        items: List.unmodifiable(_items),
        generatedAt: DateTime.utc(2026, 8, 2),
      );

  @override
  Future<StudentClassroomFeed> loadFeed() async {
    if (alwaysFail) throw StateError('Classroom unavailable');
    return _feed();
  }

  @override
  Future<StudentClassroomFeed> acknowledge(String itemId) async {
    if (alwaysFail) throw StateError('Classroom unavailable');
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx < 0) throw StateError('Announcement not found.');
    final existing = _items[idx];
    if (!existing.canAcknowledge) {
      throw StateError('Acknowledgement is not available.');
    }
    _items[idx] = StudentClassroomItem(
      id: existing.id,
      title: existing.title,
      body: existing.body,
      status: existing.status,
      attachments: existing.attachments,
      subjectCode: existing.subjectCode,
      classLabel: existing.classLabel,
      publishedAt: existing.publishedAt,
      expiresAt: existing.expiresAt,
      requiresAcknowledgement: existing.requiresAcknowledgement,
      isExpired: existing.isExpired,
      acknowledged: true,
      acknowledgedAt: DateTime.utc(2026, 8, 2),
    );
    return _feed();
  }
}

class SupabaseStudentClassroomRepository
    implements StudentClassroomRepository {
  SupabaseStudentClassroomRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<StudentClassroomFeed> loadFeed() async {
    final raw = await _client.rpc('student_classroom_feed');
    if (raw is! Map) throw StateError('Classroom unavailable.');
    return StudentClassroomFeed.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<StudentClassroomFeed> acknowledge(String itemId) async {
    await _client.rpc(
      'student_classroom_acknowledge',
      params: {'p_item_id': itemId},
    );
    return loadFeed();
  }
}
