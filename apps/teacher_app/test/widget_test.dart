import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/main.dart';

void main() {
  testWidgets('teacher foundation loads', (tester) async {
    const config = EnvironmentConfig(
      environment: NanoEnvironment.development,
      supabaseUrl: '',
      supabaseAnonKey: '',
      featureFlags: {},
    );
    await tester.pumpWidget(const NanoTeacherApp(config: config));
    expect(find.textContaining('Teacher'), findsWidgets);
  });
}
