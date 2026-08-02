import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('UsernamePolicy rejects reserved and short names', () {
    expect(UsernamePolicy.validate('ab'), isNotNull);
    expect(UsernamePolicy.validate('nano'), isNotNull);
    expect(UsernamePolicy.validate('Ali_1'), isNull);
    expect(UsernamePolicy.normalize('Ali_1'), 'ali_1');
  });

  test('LimitedProfile strips forbidden identity fields', () {
    final profile = LimitedProfile.fromJson({
      'social_label': 'sara',
      'username': 'sara',
      'level': 2,
      'companion_name': 'Nori',
      'accepts_friend_requests': true,
      'achievements': ['First quiz'],
    });
    final json = profile.toJson();
    for (final field in LimitedProfile.forbiddenFields) {
      expect(json.containsKey(field), isFalse, reason: field);
    }
    expect(json['social_label'], 'sara');
    expect(json['achievements'], ['First quiz']);
  });

  test('SocialIdentity parses friend code payload', () {
    final identity = SocialIdentity.fromJson({
      'username': 'ali',
      'friend_code': 'AB12CD34',
      'friend_code_rotated_at': '2026-08-02T00:00:00Z',
    });
    expect(identity.hasUsername, isTrue);
    expect(identity.friendCode, 'AB12CD34');
  });
}
