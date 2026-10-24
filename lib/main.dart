import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase services gracefully (with fallback for dev/emulator environments)
  await FirebaseService.initialize();

  runApp(const ProviderScope(child: LuxeStoreApp()));
}

class LuxeStoreApp extends StatelessWidget {
  const LuxeStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashWrapper(),
    );
  }
}
