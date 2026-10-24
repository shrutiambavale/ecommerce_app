import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';
import '../../checkout/presentation/add_edit_address_screen.dart';
import '../../orders/presentation/order_history_screen.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar & Name Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      ((user?.fullName.isNotEmpty ?? false)
                              ? user?.fullName[0].toUpperCase()
                              : null) ??
                          'U',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Guest Customer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email.isNotEmpty == true
                              ? user!.email
                              : 'No email associated',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: user?.role == UserRole.admin
                                ? AppColors.accent.withValues(alpha: 0.15)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user?.role == UserRole.admin
                                ? 'ADMINISTRATOR'
                                : 'CUSTOMER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: user?.role == UserRole.admin
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Admin Dashboard Entry (if user is admin or role switcher)
            if (user?.role == UserRole.admin) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white),
                  ),
                  title: const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text(
                    'Manage orders, verify payments & stock',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AdminDashboardScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],



            // Action Items
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'My Orders',
                    subtitle: 'View history & track shipments',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const OrderHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.location_on_outlined,
                    title: 'Delivery Addresses',
                    subtitle: 'Manage saved shipping addresses',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AddEditAddressScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Order Notifications',
                    subtitle: 'Real-time updates on status changes',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('FCM Notifications enabled for orders.'),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _buildProfileTile(
                    icon: Icons.help_outline_rounded,
                    title: 'UPI Payment Support',
                    subtitle: 'Help with UTR verification & refunds',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Payment Help'),
                          content: const Text(
                            'For manual UPI payments, your UTR number is verified against our bank statement by our admin team within 30 minutes of submission.\n\nFor inquiries: support@luxestore.com',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Got it'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.border),
              ),
              tileColor: AppColors.surface,
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: () async {
                final confirm = await ConfirmationDialog.show(
                  context,
                  title: 'Log Out?',
                  message: 'Are you sure you want to log out of your session?',
                  confirmText: 'Log Out',
                  confirmColor: AppColors.error,
                );

                if (confirm == true) {
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                }
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
