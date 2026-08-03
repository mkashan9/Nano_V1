import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('SafetyTextCheck and rate status parse JSON', () {
    final check = SafetyTextCheck.fromJson({
      'allowed': false,
      'code': 'NS062',
      'message': 'That message contains restricted content.',
    });
    expect(check.allowed, isFalse);
    expect(check.code, 'NS062');

    final status = SafetyRateStatus.fromJson({
      'action_key': 'friend_request',
      'configured': true,
      'max_count': 20,
      'used': 3,
      'remaining': 17,
      'window_seconds': 3600,
      'is_enabled': true,
    });
    expect(status.remaining, 17);
    expect(SafetyActionKey.friendRequest.wire, 'friend_request');
  });

  test('safetyPolicyMessage maps known codes', () {
    expect(
      safetyPolicyMessage('NS061: Too many attempts', isUrdu: false),
      contains('Too many'),
    );
    expect(
      safetyPolicyMessage('NS063 link is not allowed', isUrdu: false),
      contains('link'),
    );
  });
}
