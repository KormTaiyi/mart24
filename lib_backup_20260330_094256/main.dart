import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mart24/core/config/app_environment.dart';
import 'package:mart24/core/config/firebase_bootstrap.dart';
import 'package:mart24/core/network/network_bootstrap.dart';
import 'package:mart24/core/routes/app_routes.dart';
import 'package:mart24/core/state/session_manager.dart';
import 'package:mart24/core/theme/app_themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _bootstrapApp();
  runApp(const MyApp());
}

Future<void> _bootstrapApp() async {
  if (kDebugMode) {
    debugPrint(
      'App mode: ${AppEnvironment.useMockApi ? 'MOCK' : 'API'}'
      ' | baseUrl: ${AppEnvironment.apiBaseUrl}',
    );
  }

  try {
    await NetworkBootstrap.init();
  } catch (error) {
    debugPrint('Network bootstrap failed: $error');
  }

  try {
    final FirebaseBootstrapResult result =
        await FirebaseBootstrap.ensureInitialized();
    if (!result.isSuccess && kDebugMode) {
      debugPrint('Firebase bootstrap skipped: ${result.message}');
    }
  } catch (error) {
    debugPrint('Firebase bootstrap failed: $error');
  }

  try {
    await SessionManager.init();
  } catch (error) {
    debugPrint('Session initialization failed: $error');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        if (defaultTargetPlatform != TargetPlatform.android) {
          return child ?? const SizedBox.shrink();
        }

        return SafeArea(
          top: false,
          left: false,
          right: false,
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: '/',
      routes: AppRoutes.routes,
    );
  }
}
