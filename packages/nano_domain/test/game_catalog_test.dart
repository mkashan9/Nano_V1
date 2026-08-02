import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses game catalog and eligibility gates independent', () {
    final catalog = GameCatalog.fromJson({
      'games': [
        {
          'game_id': 'g1',
          'version_id': 'v1',
          'slug': 'number_rush',
          'category': 'practice',
          'title_en': 'Number Rush',
          'summary_en': 'Count',
          'min_grade': 1,
          'max_grade': 5,
          'independent_allowed': true,
        },
        {
          'game_id': 'g2',
          'version_id': 'v2',
          'slug': 'school_circuit',
          'category': 'challenge',
          'title_en': 'School Circuit',
          'summary_en': 'Challenge',
          'min_grade': 6,
          'max_grade': 12,
          'independent_allowed': false,
        },
      ],
    });
    expect(catalog.games, hasLength(2));
    expect(
      GameEligibility.allows(
        game: catalog.games.last,
        independent: true,
        gradeLevel: 8,
      ),
      isFalse,
    );
    expect(
      GameEligibility.allows(
        game: catalog.games.first,
        independent: false,
        gradeLevel: 3,
      ),
      isTrue,
    );
    expect(
      GameEligibility.allows(
        game: catalog.games.first,
        independent: false,
        gradeLevel: 9,
      ),
      isFalse,
    );
  });
}
