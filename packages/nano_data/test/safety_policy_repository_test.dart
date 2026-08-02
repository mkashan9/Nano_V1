import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake blocks banned phrase and unknown links', () async {
    final repo = FakeSafetyPolicyRepository();
    final banned = await repo.checkText('hello nano_banned_phrase_test');
    expect(banned.allowed, isFalse);
    expect(banned.code, 'NS062');

    final badLink = await repo.checkText('see https://evil.example/phish');
    expect(badLink.allowed, isFalse);
    expect(badLink.code, 'NS063');

    final ok = await repo.checkText('watch https://youtube.com/watch?v=1');
    expect(ok.allowed, isTrue);
  });

  test('fake rate status remaining', () async {
    final repo = FakeSafetyPolicyRepository();
    repo.used['friend_request'] = 5;
    final status = await repo.rateStatus(SafetyActionKey.friendRequest);
    expect(status.used, 5);
    expect(status.remaining, 15);
  });
}
