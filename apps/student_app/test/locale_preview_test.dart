import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('Urdu locale flips RTL and translates greeting', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );

    await tester.pumpWidget(
      const NanoStudentApp(
        config: config,
        initialLocale: NanoAppLocale.ur,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('سلام Ali'), findsOneWidget);
    expect(find.text('مضامین'), findsOneWidget);
    final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(material.locale?.languageCode, 'ur');
    expect(
      Directionality.of(tester.element(find.text('سلام Ali'))),
      TextDirection.rtl,
    );
  });
}
