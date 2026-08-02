import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/share/presentation/social_share_sheet.dart';

void main() {
  testWidgets('share sheet shows preview and copies text', (tester) async {
    final card = ShareCard.achievement(
      displayName: 'Ali Alpha',
      titleEn: 'First quiz',
      titleUr: 'پہلا کوئز',
    );
    ShareOutcome? outcome;

    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    outcome = await showSocialShareSheet(
                      context: context,
                      card: card,
                      copy: const NanoCopy(NanoAppLocale.en),
                      dispatcher: (plan) async {
                        expect(plan.target, ShareTarget.clipboard);
                        expect(plan.shareText, contains('Ali'));
                        return ShareOutcome.copied;
                      },
                    );
                  },
                  child: const Text('Open share'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open share'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share-card-preview')), findsOneWidget);
    expect(find.textContaining('earned First quiz'), findsOneWidget);

    await tester.tap(find.text('Copy text'));
    await tester.pumpAndSettle();
    expect(outcome, ShareOutcome.copied);
  });
}
