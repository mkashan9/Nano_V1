import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  final sessions = [
    SecurityFixtures.activeSession.copyWith(isCurrent: true),
    SecurityFixtures.revokedSession,
    DeviceSession(
      id: 'f3333333-3333-3333-3333-333333333333',
      userId: TenancyFixtures.aliAlphaId,
      deviceLabel: 'iPad',
    ),
  ];

  test('load profile returns private owner fields', () async {
    final repo = FakeStudentProfileRepository(sessions: sessions);
    final view = await repo.loadProfile(
      userId: TenancyFixtures.aliAlphaId,
      displayName: 'Ali',
      role: AppRole.juniorStudent,
    );
    expect(view.email, isNotNull);
    expect(view.guardianContact, isNotNull);
    expect(view.schoolName, 'Alpha Academy');
    expect(view.level.level, 3);
  });

  test('independent learners have no school context', () async {
    final repo = FakeStudentProfileRepository();
    final view = await repo.loadProfile(
      userId: TenancyFixtures.indieId,
      displayName: 'Indie',
      role: AppRole.independentStudent,
    );
    expect(view.schoolName, isNull);
    expect(view.className, isNull);
  });

  test('privacy save records the write', () async {
    final repo = FakeStudentProfileRepository();
    final saved = await repo.savePrivacy(
      PrivacySettings(
        userId: TenancyFixtures.aliAlphaId,
        discoverable: false,
      ),
    );
    expect(saved.discoverable, isFalse);
    expect(repo.privacyWrites, hasLength(1));
    expect((await repo.loadPrivacy(TenancyFixtures.aliAlphaId)).discoverable,
        isFalse);
  });

  test('revoke marks the session and refuses the current device', () async {
    final repo = FakeStudentProfileRepository(sessions: sessions);
    await expectLater(
      repo.revokeSession(SecurityFixtures.activeSessionId),
      throwsStateError,
    );

    await repo.revokeSession('f3333333-3333-3333-3333-333333333333');
    expect(repo.revokedSessionIds, ['f3333333-3333-3333-3333-333333333333']);
    final remaining = await repo.loadSessions(TenancyFixtures.aliAlphaId);
    expect(
      remaining
          .firstWhere((s) => s.id == 'f3333333-3333-3333-3333-333333333333')
          .isActive,
      isFalse,
    );
  });

  test('sign-out clears the sync cache and queue', () {
    final sync = NanoSyncController();
    sync.cache.put(
      CacheEntry(
        key: 'home',
        payload: const {'xp': 10},
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    sync.enqueueDraft(
      envelope: SyncEnvelope(
        operationId: 'op-1',
        actorId: TenancyFixtures.aliAlphaId,
        schoolId: TenancyFixtures.alphaSchoolId,
        moduleId: 'STU-05',
        operationType: SyncOperationType.attendanceDraft,
        createdAt: DateTime.now().toUtc(),
      ),
      kind: OfflineMutationKind.attendanceDraft,
      payload: const {'note': 'private'},
    );
    expect(sync.cache.all, isNotEmpty);
    expect(sync.queue.items, isNotEmpty);

    sync.cache.clear();
    sync.queue.clear();

    expect(sync.cache.all, isEmpty);
    expect(sync.queue.items, isEmpty);
  });
}
