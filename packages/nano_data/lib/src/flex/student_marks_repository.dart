import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// FLX-03 student read-only published marks (own rows only).
abstract class StudentMarksRepository {
  Future<StudentMarksSummary> loadMine({
    required DateTime from,
    required DateTime to,
  });
}

class FakeStudentMarksRepository implements StudentMarksRepository {
  FakeStudentMarksRepository({
    List<StudentMarksResult>? seed,
    this.alwaysFail = false,
  }) : _seed = seed ??
            [
              StudentMarksResult(
                assessmentId: 'asmt-1',
                entryId: 'me-1',
                name: 'Unit test 1',
                category: 'quiz',
                assessmentDate: DateTime.utc(2026, 8, 5),
                assessmentStatus: AssessmentStatus.published,
                entryStatus: MarksEntryStatus.scored,
                totalMarks: 20,
                obtainedMarks: 18,
                subjectCode: 'MATH',
                classLabel: '5-A',
                publishedAt: DateTime.utc(2026, 8, 6),
              ),
              StudentMarksResult(
                assessmentId: 'asmt-2',
                entryId: 'me-2',
                name: 'Homework 3',
                category: 'homework',
                assessmentDate: DateTime.utc(2026, 8, 12),
                assessmentStatus: AssessmentStatus.corrected,
                entryStatus: MarksEntryStatus.scored,
                totalMarks: 10,
                obtainedMarks: 9,
                subjectCode: 'MATH',
                classLabel: '5-A',
                publishedAt: DateTime.utc(2026, 8, 13),
                revision: 2,
                correctionCount: 1,
                lastCorrectedAt: DateTime.utc(2026, 8, 14),
              ),
              StudentMarksResult(
                assessmentId: 'asmt-3',
                entryId: 'me-3',
                name: 'July quiz',
                category: 'quiz',
                assessmentDate: DateTime.utc(2026, 7, 20),
                assessmentStatus: AssessmentStatus.published,
                entryStatus: MarksEntryStatus.absent,
                totalMarks: 15,
                subjectCode: 'ENG',
                classLabel: '5-A',
                publishedAt: DateTime.utc(2026, 7, 21),
              ),
            ];

  final List<StudentMarksResult> _seed;
  var alwaysFail;

  @override
  Future<StudentMarksSummary> loadMine({
    required DateTime from,
    required DateTime to,
  }) async {
    if (alwaysFail) throw StateError('Marks unavailable');
    final fromDay = DateTime.utc(from.year, from.month, from.day);
    final toDay = DateTime.utc(to.year, to.month, to.day);
    final results = [
      for (final r in _seed)
        if (!r.assessmentDate.isBefore(fromDay) &&
            !r.assessmentDate.isAfter(toDay))
          r,
    ]..sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));

    var scored = 0, absent = 0, exempt = 0, notSubmitted = 0;
    for (final r in results) {
      switch (r.entryStatus) {
        case MarksEntryStatus.scored:
          scored++;
        case MarksEntryStatus.absent:
          absent++;
        case MarksEntryStatus.exempt:
          exempt++;
        case MarksEntryStatus.notSubmitted:
          notSubmitted++;
      }
    }
    return StudentMarksSummary(
      from: fromDay,
      to: toDay,
      results: List.unmodifiable(results),
      scoredCount: scored,
      absentCount: absent,
      exemptCount: exempt,
      notSubmittedCount: notSubmitted,
      generatedAt: DateTime.utc(2026, 8, 2),
    );
  }
}

class SupabaseStudentMarksRepository implements StudentMarksRepository {
  SupabaseStudentMarksRepository(this._client);

  final SupabaseClient _client;

  String _isoDate(DateTime d) {
    final u = d.toUtc();
    final mm = u.month.toString().padLeft(2, '0');
    final dd = u.day.toString().padLeft(2, '0');
    return '${u.year}-$mm-$dd';
  }

  @override
  Future<StudentMarksSummary> loadMine({
    required DateTime from,
    required DateTime to,
  }) async {
    final raw = await _client.rpc(
      'student_marks_mine',
      params: {
        'p_from': _isoDate(from),
        'p_to': _isoDate(to),
      },
    );
    if (raw is! Map) throw StateError('Marks unavailable.');
    return StudentMarksSummary.fromJson(Map<String, dynamic>.from(raw));
  }
}
