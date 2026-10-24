import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../customer/presentation/customer_main_nav_screen.dart';
import '../domain/user_role.dart';
import 'auth_provider.dart';
import 'login_screen.dart';

class SplashWrapper extends ConsumerWidget {
  const SplashWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const _SplashScreenView(),
      error: (error, stackTrace) => const LoginScreen(),
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        if (user.role == UserRole.admin) {
          return const AdminDashboardScreen();
        }
        return const CustomerMainNavScreen();
      },
    );
  }
}

class _SplashScreenView extends StatelessWidget {
  const _SplashScreenView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              AppConstants.appTagline,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
