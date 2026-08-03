import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';
import 'package:student_app/features/qa/presentation/bidi_layout_audit_page.dart';

void main() {
  testWidgets('bidi layout audit page passes Urdu smoke', (tester) async {
    await tester.binding.setSurfaceSize(
      const Size(
        BidiLayoutBudgets.smallPhoneWidth,
        BidiLayoutBudgets.smallPhoneHeight,
      ),
    );
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(
              BidiLayoutBudgets.smallPhoneWidth,
              BidiLayoutBudgets.smallPhoneHeight,
            ),
            textScaler: TextScaler.linear(BidiLayoutBudgets.textScaleSmoke),
          ),
          child: MaterialApp(
            theme: NanoTheme.senior(),
            home: BidiLayoutAuditPage(
              repository: FakeBidiLayoutAuditRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('اردو اور دو طرفہ ترتیب'), findsOneWidget);
    expect(find.text('تمام اردو/بائیڈائی جانچیں پاس'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('تمام اردو/بائیڈائی جانچیں پاس'))),
      TextDirection.rtl,
    );
  });

  testWidgets('profile opens bidi layout audit from Me', (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: Scaffold(
            body: StudentProfilePage(
              repository: FakeStudentProfileRepository(),
              principal: SessionPrincipal.seniorSchool().copyWith(userId: 'u1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Urdu & bidirectional'));
    await tester.pumpAndSettle();
    expect(find.text('تمام اردو/بائیڈائی جانچیں پاس'), findsOneWidget);
  });

  testWidgets('English segment flips to LTR', (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: BidiLayoutAuditPage(
            repository: FakeBidiLayoutAuditRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('انگریزی'));
    await tester.pumpAndSettle();
    expect(find.text('All bidi checks passed'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('All bidi checks passed'))),
      TextDirection.ltr,
    );
  });
}
