import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('CommunitySummary and detail parse JSON', () {
    final summary = CommunitySummary.fromJson({
      'id': 'c1',
      'slug': 'study-circle',
      'name': 'Study Circle',
      'summary': 'Tips',
      'visibility': 'public',
      'member_count': 3,
      'my_role': 'member',
      'my_status': 'active',
    });
    expect(summary.isMember, isTrue);
    expect(summary.memberCount, 3);

    final detail = CommunityDetail.fromJson({
      'id': 'c1',
      'slug': 'study-circle',
      'name': 'Study Circle',
      'summary': 'Tips',
      'rules_text': 'Be kind',
      'visibility': 'public',
      'member_count': 3,
      'my_role': 'owner',
      'my_status': 'active',
    });
    expect(detail.rulesText, 'Be kind');
    expect(detail.canManageRoles, isTrue);
    expect(detail.canInvite, isTrue);
    expect(detail.canLeave, isTrue);

    final member = CommunityMember.fromJson({
      'user_id': 'u1',
      'display_name': 'Ali',
      'role': 'admin',
      'status': 'active',
      'is_self': false,
    });
    expect(member.role, 'admin');

    final invite = CommunityInvite.fromJson({
      'id': 'i1',
      'community_id': 'c1',
      'code': 'ABC123',
      'use_count': 1,
      'max_uses': 10,
    });
    expect(invite.code, 'ABC123');
  });

  test('join and leave helpers reflect membership status', () {
    const open = CommunityDetail(
      id: 'c1',
      slug: 'open',
      name: 'Open',
      summary: '',
      rulesText: '',
    );
    expect(open.canJoin, isTrue);
    expect(open.canLeave, isFalse);

    const pending = CommunityDetail(
      id: 'c1',
      slug: 'open',
      name: 'Open',
      summary: '',
      rulesText: '',
      myRole: 'member',
      myStatus: CommunityMembershipStatus.pending,
    );
    expect(pending.isPending, isTrue);
    expect(pending.canJoin, isFalse);
    expect(pending.canLeave, isTrue);
  });
}
