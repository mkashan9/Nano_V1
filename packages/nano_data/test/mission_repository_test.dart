import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('home prefers live missions when a repository is wired', () async {
    final missions = FakeMissionRepository(
      missions: [
        MissionProgressView(
          missionId: 'm1',
          slug: 'daily_lesson',
          cadence: MissionCadence.daily,
          titleEn: 'Complete a lesson',
          titleUr: 'x',
          subtitleEn: 'Today',
          subtitleUr: 'x',
          xpBonus: 15,
          targetCount: 1,
          progressCount: 0,
          periodKey: '2026-08-02',
          completed: false,
        ),
      ],
    );
    final home = FakeStudentHomeRepository(
      missions: const [
        HomePlanItem(id: 'fixture', title: 'Fixture', subtitle: 'x', xpReward: 1),
      ],
      missionRepository: missions,
    );
    final summary = await home.loadHome(userId: 'u1', learnerName: 'Ali');
    expect(summary.missions.single.title, 'Complete a lesson');
    expect(summary.missions.single.xpReward, 15);
  });

  test('home keeps fixture missions without a repository', () async {
    final home = FakeStudentHomeRepository(
      missions: const [
        HomePlanItem(id: 'fixture', title: 'Fixture', subtitle: 'x', xpReward: 1),
      ],
    );
    final summary = await home.loadHome(userId: 'u1', learnerName: 'Ali');
    expect(summary.missions.single.title, 'Fixture');
  });
}
