import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// CMP-04 / MED-09: bundled humanoid poses are complete and reachable.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every reachable mood has a bundled pose', () {
    for (final mood in CompanionMood.values) {
      expect(
        () => CompanionPosePack.assetFor(mood),
        returnsNormally,
        reason: 'no bundled pose for ${mood.name}',
      );
      expect(
        () => NoriPosePack.assetFor(mood),
        returnsNormally,
        reason: 'NoriPosePack wrapper must forward',
      );
      expect(NoriPosePack.assetFor(mood), CompanionPosePack.assetFor(mood));
    }
    expect(
      CompanionPosePack.all.toSet().length,
      CompanionMood.values.length,
      reason: 'two moods must not share one drawing',
    );
  });

  test('paths point at humanoid webp assets, not legacy nori jpgs', () {
    for (final path in CompanionPosePack.all) {
      expect(path, startsWith('assets/companion/companion_'));
      expect(path, endsWith('.webp'));
      expect(path, isNot(contains('nori_')));
    }
    expect(CompanionPosePack.portraitAsset, contains('companion_portrait'));
  });

  test('every bundled pose is actually in the package bundle', () async {
    for (final path in CompanionPosePack.all) {
      final bytes = await rootBundle.load('packages/nano_design_system/$path');
      expect(
        bytes.lengthInBytes,
        greaterThan(1024),
        reason: '$path is missing or truncated',
      );
    }
    final portrait = await rootBundle.load(
      'packages/nano_design_system/${CompanionPosePack.portraitAsset}',
    );
    expect(portrait.lengthInBytes, greaterThan(1024));
  });

  test('the pack is small enough to ship on a cheap device', () async {
    var total = 0;
    for (final path in CompanionPosePack.all) {
      final bytes = await rootBundle.load('packages/nano_design_system/$path');
      total += bytes.lengthInBytes;
    }
    expect(
      total,
      lessThan(768 * 1024),
      reason: 'humanoid offline pack grew past CMP-04 budget',
    );
  });

  test('one drawing per mood covers every reachable mode and mood pair', () {
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

    expect(
      pairs.length,
      greaterThan(24),
      reason: 'the reachable matrix should include CMP-04 events',
    );
    for (final pair in pairs) {
      final mood = CompanionMood.values.firstWhere(
        (m) => m.name == pair.split('|').last,
      );
      expect(CompanionPosePack.assetFor(mood), isNotEmpty);
    }
  });

  test('identity version is stable', () {
    expect(CompanionPosePack.identityVersion, CompanionIdentity.version);
  });
}
