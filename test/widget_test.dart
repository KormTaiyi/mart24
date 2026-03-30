import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mart24/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('login screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember Me'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
  });
}
