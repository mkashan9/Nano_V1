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

    final member = CommunityMember.fromJson({
      'user_id': 'u1',
      'display_name': 'Ali',
      'role': 'admin',
      'status': 'active',
      'is_self': false,
    });
    expect(member.role, 'admin');
  });
}
