import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake claim username and rotate friend code', () async {
    final repo = FakeSocialIdentityRepository();
    final claimed = await repo.claimUsername('Ali_Play');
    expect(claimed.username, 'ali_play');
    expect(repo.claimedUsernames, ['ali_play']);

    final rotated = await repo.rotateFriendCode();
    expect(rotated.friendCode, isNot(equals('AB12CD34')));
    expect(repo.rotateCount, 1);
  });

  test('fake lookup by username returns limited profile without user id',
      () async {
    final repo = FakeSocialIdentityRepository();
    final found = await repo.lookup('sara');
    expect(found.socialLabel, 'sara');
    expect(found.toJson().containsKey('user_id'), isFalse);
    expect(found.toJson().containsKey('friend_code'), isFalse);
  });

  test('fake rejects invalid username', () async {
    final repo = FakeSocialIdentityRepository();
    expect(
      () => repo.claimUsername('ab'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
