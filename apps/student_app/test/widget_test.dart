import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

void main() {
  testWidgets('junior shell shows Home Learn Games Profile tabs', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.junior(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Flex'), findsNothing);
    expect(find.text('Animals Adventure'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Math'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('Math'), findsOneWidget);
  });

  testWidgets('independent shell hides Flex tab', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {'diagnostics': true},
    );
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialPrincipal: SessionPrincipal.independent(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Learn'), findsWidgets);
    expect(find.text('Flex'), findsNothing);
    expect(find.text('Communities'), findsOneWidget);
  });
}
