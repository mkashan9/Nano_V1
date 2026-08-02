import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('fake catalog hides school-only games from independents', () async {
    final repo = FakeGameCatalogRepository();
    final school = await repo.loadCatalog(independent: false, gradeLevel: 8);
    expect(school.games.any((g) => g.slug == 'school_circuit'), isTrue);

    final indie = await repo.loadCatalog(independent: true, gradeLevel: 8);
    expect(indie.games.any((g) => g.slug == 'school_circuit'), isFalse);
  });

  test('fake catalog applies grade band', () async {
    final repo = FakeGameCatalogRepository();
    final junior = await repo.loadCatalog(independent: false, gradeLevel: 3);
    expect(junior.games.map((g) => g.slug), ['number_rush']);

    final senior = await repo.loadCatalog(independent: false, gradeLevel: 8);
    expect(senior.games.map((g) => g.slug), ['school_circuit']);
  });
}
