import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

/// MED-11: every moment the companion can reach has something it can say.
///
/// Coverage is the kind of property that is true the day it ships and quietly
/// false six modules later, when somebody adds a mood or an event and nobody
/// notices the companion has gone mute there. These are the tests that notice.
void main() {
  /// Every mood a learner can actually cause, derived rather than listed, so
  /// adding an event to the enum is enough to make this fail.
  final reachableMoods =
      CompanionEvent.values.map(CompanionMood.forEvent).toSet();

  test('every reachable mood has at least one line', () {
    for (final mood in reachableMoods) {
      final lines = CompanionScriptBook.core[mood] ?? const <CompanionScript>[];
      expect(lines, isNotEmpty, reason: '${mood.name} has nothing to say');
    }
  });

  test('every reachable mood has a line that can actually be recorded', () {
    // A personalised line can never be pre-recorded (ADR-0008): the recording
    // would say one child's companion name to every other child. A mood whose
    // only line is personalised is a mood that is permanently silent, however
    // much narration gets generated, and that is invisible from the outside.
    for (final mood in reachableMoods) {
      final lines = CompanionScriptBook.core[mood] ?? const <CompanionScript>[];
      expect(
        lines.any((line) => !line.isPersonalised),
        isTrue,
        reason: '${mood.name} can only ever be a caption',
      );
    }
  });

  test('every line carries Urdu text, or is honestly English-only', () {
    // The rule is strict locale match: Urdu audio is never an English file with
    // an Urdu label, and a line with no Urdu shows the caption instead. What
    // must not happen is an Urdu *caption* silently falling back to English
    // words, which is what an empty textUr would cause.
    for (final entry in CompanionScriptBook.core.entries) {
      for (final line in entry.value) {
        final ur = line.textUr;
        expect(
          ur == null || ur.trim().isNotEmpty,
          isTrue,
          reason: '${line.id} has an empty Urdu string, which reads as English',
        );
      }
    }
  });

  test('a personalised line is personalised in both languages or neither', () {
    // Half-personalised is the worst case: recordable in one language and not
    // the other, so a child hears the line in English and reads it in Urdu.
    for (final entry in CompanionScriptBook.core.entries) {
      for (final line in entry.value) {
        final ur = line.textUr;
        if (ur == null) continue;
        expect(
          line.text.contains('{'),
          ur.contains('{'),
          reason: '${line.id} is personalised in one language only',
        );
      }
    }
  });

  test('the recordable set is what the generation run covered', () {
    // The 15 recordings requested in MED-11 were derived from this list. If it
    // grows, the run was incomplete and somebody has to notice before the
    // coverage SQL fails in the field.
    final recordable = <String>{
      for (final lines in CompanionScriptBook.core.values)
        for (final line in lines)
          if (!line.isPersonalised) line.id,
    };

    expect(
      recordable,
      {
        'greeting-2',
        'idle-1',
        'point-1',
        'point-2',
        'thinking-1',
        'retry-1',
        'celebration-1',
        'celebration-2',
      },
      reason: 'the script book changed; narration needs regenerating',
    );
  });
}
