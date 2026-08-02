import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  StudentProfileView profile({
    String name = 'Ali Alpha',
    AppRole role = AppRole.juniorStudent,
    List<ProfileAchievement> achievements = const [],
  }) {
    return StudentProfileView(
      userId: TenancyFixtures.aliAlphaId,
      displayName: name,
      role: role,
      schoolName: 'Alpha Academy',
      className: 'Grade 5B',
      email: 'ali@alpha.nano.dev',
      guardianContact: 'parent@example.dev',
      attendanceLabel: '94%',
      latestMarkLabel: '8/10',
      xp: 560,
      streakDays: 7,
      completedTopics: 12,
      achievements: achievements,
    );
  }

  test('initials take the first letter of each name part', () {
    expect(profile().initials, 'AA');
    expect(profile(name: 'Sara').initials, 'SA');
    expect(profile(name: '  ').initials, '?');
  });

  test('public projection strips every forbidden field', () {
    final view = profile(
      achievements: [
        ProfileAchievement(
          id: 'a1',
          title: 'First quiz',
          earnedAt: DateTime.utc(2026, 7, 1),
        ),
      ],
    );
    final privacy = PrivacySettings(userId: view.userId);
    final public = PublicProfileProjection.of(view, privacy);
    final json = public.toJson();

    for (final field in PublicProfileProjection.forbiddenFields) {
      expect(json.containsKey(field), isFalse, reason: field);
    }
    expect(json['email'], isNull);
    expect(json['displayName'], 'Ali');
    expect(json['level'], 3);
    expect(json['achievements'], ['First quiz']);
  });

  test('public projection prefers username when claimed', () {
    final view = profile();
    final privacy = PrivacySettings(userId: view.userId);
    final public = PublicProfileProjection.of(
      view,
      privacy,
      username: 'ali_alpha',
    );
    expect(public.displayName, 'ali_alpha');
    expect(public.username, 'ali_alpha');
    expect(public.toJson().containsKey('friendCode'), isFalse);
  });

  test('hiding achievements removes them from the public projection', () {
    final view = profile(
      achievements: [
        ProfileAchievement(
          id: 'a1',
          title: 'First quiz',
          earnedAt: DateTime.utc(2026, 7, 1),
        ),
      ],
    );
    final privacy = PrivacySettings(
      userId: view.userId,
      showAchievements: false,
      discoverable: false,
    );
    final public = PublicProfileProjection.of(view, privacy);
    expect(public.achievements, isEmpty);
    expect(public.discoverable, isFalse);
  });

  test('device session last-seen label and revocability', () {
    final current = SecurityFixtures.activeSession.copyWith(isCurrent: true);
    expect(current.isRevocable, isFalse);

    final other = DeviceSession(
      id: 'x',
      userId: TenancyFixtures.aliAlphaId,
      deviceLabel: 'iPad',
      lastSeenAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
    );
    expect(other.isRevocable, isTrue);
    expect(other.lastSeenLabel, '2 h ago');
    expect(SecurityFixtures.revokedSession.isRevocable, isFalse);
  });

  test('privacy settings round-trip through a row map', () {
    final settings = PrivacySettings(
      userId: TenancyFixtures.aliAlphaId,
      discoverable: false,
      allowFriendRequests: false,
    );
    final restored = PrivacySettings.fromRow(settings.toRow());
    expect(restored.discoverable, isFalse);
    expect(restored.showAchievements, isTrue);
    expect(restored.allowFriendRequests, isFalse);
  });
}
