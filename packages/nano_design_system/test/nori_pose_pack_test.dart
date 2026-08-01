import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// MED-09: the offline floor is real, complete, and reachable.
///
/// The value of a bundled pack is that it cannot fail at runtime, so the only
/// way it can fail is at build time — a mood added to the enum with no drawing
/// behind it, or a file renamed out from under the map. Both are caught here.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every reachable mood has a bundled pose', () {
    for (final mood in CompanionMood.values) {
      expect(
        () => NoriPosePack.assetFor(mood),
        returnsNormally,
        reason: 'no bundled pose for ${mood.name}',
      );
    }
    expect(NoriPosePack.all.toSet().length, CompanionMood.values.length,
        reason: 'two moods must not share one drawing');
  });

  test('every bundled pose is actually in the package bundle', () async {
    for (final path in NoriPosePack.all) {
      final bytes = await rootBundle.load('packages/nano_design_system/$path');
      expect(bytes.lengthInBytes, greaterThan(1024),
          reason: '$path is missing or truncated');
    }
  });

  test('the pack is small enough to ship on a cheap device', () async {
    var total = 0;
    for (final path in NoriPosePack.all) {
      final bytes = await rootBundle.load('packages/nano_design_system/$path');
      total += bytes.lengthInBytes;
    }
    // Art that ships with the app is art nobody can delete or fail to fetch,
    // but it is also weight on every install. A quarter of a megabyte for the
    // whole companion is the budget; blowing it means compressing, not
    // dropping a mood.
    expect(total, lessThan(256 * 1024),
        reason: 'the offline pack has grown past its budget');
  });

  test('one drawing per mood covers every reachable mode and mood pair', () {
    // 4 modes x 6 moods plus celebration|celebration is 25 reachable slots,
    // and the pack has 6 files. That only works because a mode is the ring the
    // stage draws, never a different character (CMP-02).
    final pairs = <String>{};
    for (final surface in CompanionSurface.values) {
      final visible = [true, false].any(
        (junior) => CompanionPlacementPolicy.resolve(
          surface: surface,
          junior: junior,
        ).isVisible,
      );
      if (!visible) continue;
      for (final event in CompanionEvent.values) {
        final mode = CompanionMode.resolve(surface: surface, event: event);
        final mood = CompanionMood.forEvent(event);
        pairs.add('${mode.name}|${mood.name}');
      }
    }

    expect(pairs.length, 25, reason: 'the reachable matrix changed');
    for (final pair in pairs) {
      final mood = CompanionMood.values
          .firstWhere((m) => m.name == pair.split('|').last);
      expect(NoriPosePack.assetFor(mood), isNotEmpty);
    }
  });
}
