import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

Widget _host({
  required StudentProfileRepository repository,
  NanoSyncController? sync,
  Future<void> Function()? onSignOut,
  ValueChanged<StudentPreferences>? onPreferences,
}) {
  final principal = SessionPrincipal.junior(displayName: 'Ali Alpha')
      .copyWith(userId: TenancyFixtures.aliAlphaId, isAuthenticated: true);
  return NanoLocaleScope(
    locale: NanoAppLocale.en,
    copy: const NanoCopy(NanoAppLocale.en),
    child: MaterialApp(
      theme: NanoTheme.junior(),
      home: Scaffold(
        body: StudentProfilePage(
          repository: repository,
          principal: principal,
          preferences: StudentPreferences(userId: principal.userId!),
          onPreferencesChanged: onPreferences,
          onOpenAccessibility: () {},
          onSignOut: onSignOut,
          syncController: sync,
        ),
      ),
    ),
  );
}

FakeStudentProfileRepository _repo() {
  return FakeStudentProfileRepository(
    sessions: [
      SecurityFixtures.activeSession.copyWith(isCurrent: true),
      DeviceSession(
        id: 'f3333333-3333-3333-3333-333333333333',
        userId: TenancyFixtures.aliAlphaId,
        deviceLabel: 'iPad',
        lastSeenAt:
            DateTime.now().toUtc().subtract(const Duration(hours: 5)),
      ),
      SecurityFixtures.revokedSession,
    ],
  );
}

Future<void> _pump(WidgetTester tester, Widget app) async {
  await tester.binding.setSurfaceSize(const Size(800, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows identity, progress and privacy controls', (tester) async {
    await _pump(tester, _host(repository: _repo()));

    expect(find.text('Ali Alpha'), findsOneWidget);
    expect(find.textContaining('Level 3'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Let others find me'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.textContaining('This device'), findsOneWidget);
  });

  testWidgets('toggling privacy persists through the repository',
      (tester) async {
    final repo = _repo();
    await _pump(tester, _host(repository: repo));

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(repo.privacyWrites, hasLength(1));
    expect(repo.privacyWrites.single.discoverable, isFalse);
  });

  testWidgets('revoking another device updates the list', (tester) async {
    final repo = _repo();
    await _pump(tester, _host(repository: repo));

    expect(find.text('Sign out device'), findsOneWidget);
    await tester.tap(find.text('Sign out device'));
    await tester.pumpAndSettle();

    expect(repo.revokedSessionIds, ['f3333333-3333-3333-3333-333333333333']);
    expect(find.text('Signed out'), findsNWidgets(2));
  });

  testWidgets('sign out clears private caches before leaving', (tester) async {
    final sync = NanoSyncController();
    sync.cache.put(
      CacheEntry(
        key: 'home',
        payload: const {'xp': 10},
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    var signedOut = false;
    await _pump(
      tester,
      _host(
        repository: _repo(),
        sync: sync,
        onSignOut: () async {
          signedOut = true;
        },
      ),
    );

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
    expect(sync.cache.all, isEmpty);
    expect(sync.queue.items, isEmpty);
  });

  testWidgets('load failure shows a recoverable error', (tester) async {
    await _pump(
      tester,
      _host(repository: FakeStudentProfileRepository(alwaysFail: true)),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
  });
}
