import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/main.dart';

void main() {
  testWidgets('teacher shell shows core destinations', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(const NanoTeacherApp(config: config));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Classes'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('Marks'), findsOneWidget);
  });
}
