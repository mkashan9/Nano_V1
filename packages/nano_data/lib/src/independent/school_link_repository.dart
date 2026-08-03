import 'package:nano_domain/nano_domain.dart';

/// IND-04 school invitation redeem / account linking (fake-first).
abstract class SchoolLinkRepository {
  Future<SchoolInvitePreview> previewInvite(String code);

  Future<SchoolLinkResult> linkAccount({
    required SessionPrincipal principal,
    required String code,
  });
}

class FakeSchoolLinkRepository implements SchoolLinkRepository {
  FakeSchoolLinkRepository({
    Map<String, SchoolInvitePreview>? invites,
    this.alwaysFail = false,
  }) : _invites = Map.of(
          invites ??
              {
                TenancyFixtures.alpha.code: SchoolInvitePreview(
                  code: TenancyFixtures.alpha.code,
                  schoolId: TenancyFixtures.alpha.id,
                  schoolName: TenancyFixtures.alpha.name,
                ),
                'SUSP01': const SchoolInvitePreview(
                  code: 'SUSP01',
                  schoolId: 'suspended-school',
                  schoolName: 'Paused School',
                  schoolStatus: SchoolStatus.suspended,
                ),
              },
        );

  final Map<String, SchoolInvitePreview> _invites;
  bool alwaysFail;
  final linkedUserIds = <String>{};

  @override
  Future<SchoolInvitePreview> previewInvite(String code) async {
    if (alwaysFail) throw StateError('Invite lookup failed');
    final normalized = SchoolLinkPolicy.normalizeCode(code);
    if (!SchoolLinkPolicy.looksLikeCode(normalized)) {
      throw StateError('Invalid school code');
    }
    final preview = _invites[normalized];
    if (preview == null) throw StateError('School invite not found');
    return preview;
  }

  @override
  Future<SchoolLinkResult> linkAccount({
    required SessionPrincipal principal,
    required String code,
  }) async {
    if (alwaysFail) throw StateError('Link failed');
    final preview = await previewInvite(code);
    final decision = SchoolLinkPolicy.canLink(
      role: principal.role,
      schoolId: principal.schoolId,
      preview: preview,
    );
    if (!decision.allowed) {
      throw StateError(decision.reason.name);
    }
    final userId = principal.userId ?? 'local';
    linkedUserIds.add(userId);
    final upgraded = SchoolLinkPolicy.linkedPrincipal(
      principal,
      schoolId: preview.schoolId,
    );
    return SchoolLinkResult(
      schoolId: preview.schoolId,
      schoolName: preview.schoolName,
      schoolCode: preview.code,
      principal: upgraded,
      progressPreserved: true,
    );
  }
}
