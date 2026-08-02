import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/friends_page.dart';

void main() {
  testWidgets('accepts incoming request into friends list', (tester) async {
    final repo = FakeFriendGraphRepository(
      requests: [
        const FriendRequest(
          id: 'req-1',
          status: FriendRequestStatus.pending,
          direction: FriendRequestDirection.incoming,
          peerLabel: 'sara',
          username: 'sara',
        ),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: FriendsPage(repository: repo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Requests'));
    await tester.pumpAndSettle();
    expect(find.text('sara'), findsOneWidget);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Friends').last);
    await tester.pumpAndSettle();
    expect(find.text('sara'), findsOneWidget);

    await tester.tap(find.text('Ranking'));
    await tester.pumpAndSettle();
    expect(find.textContaining('XP'), findsWidgets);
  });
}
