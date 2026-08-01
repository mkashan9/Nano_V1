import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  CompanionPlacement placement(CompanionSurface surface, {bool junior = true}) {
    return CompanionPlacementPolicy.resolve(surface: surface, junior: junior);
  }

  test('junior leads with the companion where a start matters', () {
    expect(placement(CompanionSurface.home), CompanionPlacement.hero);
    expect(placement(CompanionSurface.learning), CompanionPlacement.hero);
    expect(placement(CompanionSurface.onboarding), CompanionPlacement.hero);
  });

  test('senior keeps it beside the content instead', () {
    expect(
      placement(CompanionSurface.home, junior: false),
      CompanionPlacement.aside,
    );
    expect(
      placement(CompanionSurface.learning, junior: false),
      CompanionPlacement.aside,
    );
    expect(
      placement(CompanionSurface.progress, junior: false),
      CompanionPlacement.aside,
    );
  });

  test('a quiz keeps the companion in the flow for both experiences', () {
    expect(placement(CompanionSurface.quiz), CompanionPlacement.inline);
    expect(
      placement(CompanionSurface.quiz, junior: false),
      CompanionPlacement.inline,
    );
  });

  test('social and settings carry no companion at all', () {
    for (final junior in const [true, false]) {
      expect(
        placement(CompanionSurface.social, junior: junior),
        CompanionPlacement.hidden,
      );
      expect(
        placement(CompanionSurface.settings, junior: junior),
        CompanionPlacement.hidden,
      );
    }
  });

  test('every surface has a placement in both experiences', () {
    for (final surface in CompanionSurface.values) {
      for (final junior in const [true, false]) {
        expect(
          placement(surface, junior: junior),
          isA<CompanionPlacement>(),
          reason: '$surface junior=$junior',
        );
      }
    }
  });

  test('junior is never quieter than senior on the same surface', () {
    const weight = {
      CompanionPlacement.hidden: 0,
      CompanionPlacement.aside: 1,
      CompanionPlacement.inline: 2,
      CompanionPlacement.hero: 3,
    };
    for (final surface in CompanionSurface.values) {
      expect(
        weight[placement(surface)]!,
        greaterThanOrEqualTo(weight[placement(surface, junior: false)]!),
        reason: '$surface',
      );
    }
  });

  test('hidden is the only placement that renders nothing', () {
    expect(CompanionPlacement.hidden.isVisible, isFalse);
    for (final other in const [
      CompanionPlacement.hero,
      CompanionPlacement.inline,
      CompanionPlacement.aside,
    ]) {
      expect(other.isVisible, isTrue);
    }
  });
}
