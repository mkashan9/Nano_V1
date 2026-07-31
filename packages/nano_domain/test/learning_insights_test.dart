import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

SubjectProgress _subject({
  required String id,
  int total = 4,
  int completed = 0,
  int inProgress = 0,
  int locked = 0,
  int watched = 0,
  int order = 1,
}) {
  return SubjectProgress(
    subjectId: id,
    slug: id,
    title: id,
    order: order,
    topicsTotal: total,
    topicsCompleted: completed,
    topicsInProgress: inProgress,
    topicsLocked: locked,
    watchedSeconds: watched,
  );
}

void main() {
  group('subject progress', () {
    test('reads a summary row', () {
      final subject = SubjectProgress.fromRow({
        'subject_id': 'subject-math',
        'subject_slug': 'math',
        'subject_order': 2,
        'subject_title': 'Math',
        'subject_title_ur': 'حساب',
        'world_color_hex': '#2F7BFF',
        'topics_total': 4,
        'topics_completed': 1,
        'topics_in_progress': 1,
        'topics_locked': 2,
        'watched_seconds': 300,
        'last_activity_at': '2026-07-31T10:00:00Z',
      });

      expect(subject.slug, 'math');
      expect(subject.order, 2);
      expect(subject.titleFor(NanoAppLocale.ur), 'حساب');
      expect(subject.titleFor(NanoAppLocale.en), 'Math');
      expect(subject.completionRatio, 0.25);
      expect(subject.topicsRemaining, 3);
      expect(subject.isStarted, isTrue);
      expect(subject.isFinished, isFalse);
      expect(subject.lastActivityAt?.isUtc, isTrue);
    });

    test('an empty subject has no completion and is not started', () {
      final subject = _subject(id: 'empty', total: 0);
      expect(subject.completionRatio, 0);
      expect(subject.isStarted, isFalse);
      expect(subject.isFinished, isFalse);
    });
  });

  group('next up suggestions', () {
    test('reads a ranked row with its reason', () {
      final suggestion = NextUpSuggestion.fromRow({
        'topic_version_id': 'tv-addition-1',
        'topic_id': 'topic-addition',
        'subject_id': 'subject-math',
        'topic_title': 'Adding small numbers',
        'topic_title_ur': 'چھوٹے اعداد جمع',
        'subject_title': 'Math',
        'subject_title_ur': 'حساب',
        'reason': 'resume',
        'rank': 1,
        'estimated_minutes': 15,
        'duration_seconds': 150,
        'watched_seconds': 60,
        'resume_seconds': 60,
      });

      expect(suggestion.isResume, isTrue);
      expect(suggestion.rank, 1);
      expect(suggestion.titleFor(NanoAppLocale.ur), 'چھوٹے اعداد جمع');
      expect(suggestion.subjectTitleFor(NanoAppLocale.en), 'Math');
      expect(
        suggestion.reasonLabel(NanoCopy(NanoAppLocale.en)),
        'You left this unfinished',
      );
    });

    test('an unknown reason is treated as a new subject', () {
      expect(NextUpReason.fromName('something-else'), NextUpReason.newSubject);
      expect(NextUpReason.fromName(null), NextUpReason.newSubject);
      expect(
        NextUpReason.fromName('next_in_subject'),
        NextUpReason.nextInSubject,
      );
    });

    test('each reason reads differently in both languages', () {
      final en = NanoCopy(NanoAppLocale.en);
      final ur = NanoCopy(NanoAppLocale.ur);
      const suggestions = [
        NextUpSuggestion(
          topicVersionId: 'a',
          topicId: 'a',
          subjectId: 's',
          title: 'A',
          subjectTitle: 'S',
          reason: NextUpReason.resume,
        ),
        NextUpSuggestion(
          topicVersionId: 'b',
          topicId: 'b',
          subjectId: 's',
          title: 'B',
          subjectTitle: 'S',
          reason: NextUpReason.nextInSubject,
        ),
        NextUpSuggestion(
          topicVersionId: 'c',
          topicId: 'c',
          subjectId: 's',
          title: 'C',
          subjectTitle: 'S',
          reason: NextUpReason.newSubject,
        ),
      ];

      final labels = suggestions.map((item) => item.reasonLabel(en)).toSet();
      expect(labels.length, 3);
      for (final suggestion in suggestions) {
        expect(suggestion.reasonLabel(ur), isNot(suggestion.reasonLabel(en)));
      }
    });
  });

  group('learning insights', () {
    test('totals add up across subjects', () {
      final insights = LearningInsights(
        subjects: [
          _subject(id: 'math', total: 4, completed: 2, watched: 300),
          _subject(id: 'science', total: 6, completed: 1, watched: 120, order: 2),
        ],
      );

      expect(insights.topicsCompleted, 3);
      expect(insights.topicsTotal, 10);
      expect(insights.watchedSeconds, 420);
      expect(insights.watchedMinutes, 7);
      expect(insights.completionRatio, closeTo(0.3, 0.0001));
      expect(insights.isEmpty, isFalse);
    });

    test('the first suggestion is the recommendation, the rest alternatives', () {
      const insights = LearningInsights(
        suggestions: [
          NextUpSuggestion(
            topicVersionId: 'first',
            topicId: 'a',
            subjectId: 's',
            title: 'First',
            subjectTitle: 'S',
            rank: 1,
          ),
          NextUpSuggestion(
            topicVersionId: 'second',
            topicId: 'b',
            subjectId: 's',
            title: 'Second',
            subjectTitle: 'S',
            rank: 2,
          ),
        ],
      );

      expect(insights.recommendation?.topicVersionId, 'first');
      expect(insights.alternatives.single.topicVersionId, 'second');
    });

    test('nothing left to do means no recommendation, not an error', () {
      final insights = LearningInsights(
        subjects: [_subject(id: 'math', total: 2, completed: 2, watched: 240)],
      );
      expect(insights.recommendation, isNull);
      expect(insights.alternatives, isEmpty);
      expect(insights.subjects.single.isFinished, isTrue);
    });

    test('subjects are ordered the way the catalog orders them', () {
      final insights = LearningInsights(
        subjects: [
          _subject(id: 'science', order: 2),
          _subject(id: 'math', order: 1),
        ],
      );
      expect(
        insights.orderedSubjects.map((subject) => subject.subjectId),
        ['math', 'science'],
      );
    });

    test('the strongest subject is the one furthest finished', () {
      final insights = LearningInsights(
        subjects: [
          _subject(id: 'math', total: 4, completed: 3, inProgress: 1),
          _subject(id: 'science', total: 4, completed: 1, inProgress: 1, order: 2),
        ],
      );
      expect(insights.strongest?.subjectId, 'math');
      expect(insights.needsAttention?.subjectId, 'science');
    });

    test('a subject that is only started, never finished, is not a strength', () {
      final insights = LearningInsights(
        subjects: [_subject(id: 'math', total: 4, inProgress: 1)],
      );
      expect(insights.strongest, isNull);
    });

    test('one started subject is not called out as needing attention', () {
      final insights = LearningInsights(
        subjects: [
          _subject(id: 'math', total: 4, completed: 2, inProgress: 1),
          _subject(id: 'science', total: 4, order: 2),
        ],
      );
      expect(insights.strongest?.subjectId, 'math');
      expect(insights.needsAttention, isNull);
    });

    test('a finished subject is never the focus area', () {
      final insights = LearningInsights(
        subjects: [
          _subject(id: 'math', total: 2, completed: 2),
          _subject(id: 'science', total: 4, completed: 1, order: 2),
          _subject(id: 'art', total: 4, completed: 3, order: 3),
        ],
      );
      expect(insights.strongest?.subjectId, 'math');
      expect(insights.needsAttention?.subjectId, 'science');
    });

    test('untouched subjects leave both callouts empty', () {
      final insights = LearningInsights(
        subjects: [
          _subject(id: 'math', total: 4, locked: 1),
          _subject(id: 'science', total: 4, order: 2),
        ],
      );
      expect(insights.strongest, isNull);
      expect(insights.needsAttention, isNull);
    });
  });
}
