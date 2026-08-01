import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('home prefers the live streak and gentle notice', () async {
    final streaks = FakeStreakRepository(
      snapshot: const StreakSnapshot(
        current: 2,
        longest: 4,
        status: StreakStatus.active,
        notice: 'welcome_back',
        messageEn: 'Welcome back.',
        messageUr: 'x',
      ),
    );
    final home = FakeStudentHomeRepository(streakRepository: streaks);
    final summary = await home.loadHome(userId: 'u1', learnerName: 'Ali');
    expect(summary.streakDays, 2);
    expect(summary.notice, HomeNoticeKind.streakGentle);
  });

  test('profile prefers the live streak count', () async {
    final streaks = FakeStreakRepository(
      snapshot: const StreakSnapshot(current: 4, longest: 4),
    );
    final profile = FakeStudentProfileRepository(streakRepository: streaks);
    final view = await profile.loadProfile(
      userId: 'u1',
      displayName: 'Ali',
      role: AppRole.juniorStudent,
    );
    expect(view.streakDays, 4);
  });
}
