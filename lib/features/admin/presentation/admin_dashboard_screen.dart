import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/login_screen.dart';
import '../../customer/presentation/customer_main_nav_screen.dart';
import '../../orders/presentation/order_details_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_payment_verification_screen.dart';
import 'admin_products_screen.dart';
import 'admin_provider.dart';
import 'admin_qr_settings_screen.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null || currentUser.role != UserRole.admin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: EmptyStateView(
            icon: Icons.security_rounded,
            title: 'Administrator Authorization Required',
            message:
                'This management console is strictly restricted to verified store administrators.',
          ),
        ),
      );
    }

    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Management Console',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            Text(
              'LuxeStore Enterprise Backend',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: const Text('Storefront'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomerMainNavScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: () async {
              final confirm = await ConfirmationDialog.show(
                context,
                title: 'Log Out?',
                message:
                    'Are you sure you want to end your administrator session?',
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
          const SizedBox(width: 8),
        ],
      ),
      body: statsAsync.when(
        loading: () => const LoadingView(message: 'Loading store metrics...'),
        error: (err, _) => Center(child: Text('Error loading stats: $err')),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminStatsProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pending Verification Action Alert Banner (if pending)
                  if (stats.pendingPaymentVerifications > 0) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const AdminPaymentVerificationScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.statusPendingVerification,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.statusPendingVerification,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.hourglass_top_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${stats.pendingPaymentVerifications} Payment ${stats.pendingPaymentVerifications == 1 ? 'Verification' : 'Verifications'} Pending',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Customer UTRs and screenshots awaiting manual review',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // KPI Cards Grid
                  const Text(
                    'Performance Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      _buildKpiCard(
                        title: 'Verified Sales',
                        value: CurrencyFormatter.format(stats.totalVerifiedSales),
                        subtitle: 'Received in bank',
                        icon: Icons.payments_rounded,
                        color: AppColors.success,
                      ),
                      _buildKpiCard(
                        title: 'Pending UTRs',
                        value: '${stats.pendingPaymentVerifications}',
                        subtitle: 'Requires approval',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.statusPendingVerification,
                      ),
                      _buildKpiCard(
                        title: 'Total Orders',
                        value: '${stats.totalOrders}',
                        subtitle: 'Lifetime orders',
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.accent,
                      ),
                      _buildKpiCard(
                        title: 'Total Products',
                        value: '${stats.totalProducts}',
                        subtitle: 'Catalog size',
                        icon: Icons.inventory_2_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Operations & Management Shortcuts
                  const Text(
                    'Management Modules',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildNavTile(
                          icon: Icons.verified_user_rounded,
                          color: AppColors.statusPendingVerification,
                          title: 'Payment Verification',
                          subtitle: 'Verify customer UTRs & receipts',
                          badgeCount: stats.pendingPaymentVerifications,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminPaymentVerificationScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildNavTile(
                          icon: Icons.receipt_long_rounded,
                          color: AppColors.accent,
                          title: 'Orders Management',
                          subtitle: 'View, filter & update fulfillment status',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AdminOrdersScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildNavTile(
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.primary,
                          title: 'Product Management',
                          subtitle: 'Add products, edit prices & manage inventory',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminProductsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildNavTile(
                          icon: Icons.category_rounded,
                          color: const Color(0xFFD97706),
                          title: 'Category Management',
                          subtitle: 'Organize store catalog categories',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminCategoriesScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildNavTile(
                          icon: Icons.qr_code_2_rounded,
                          color: const Color(0xFF0D9488),
                          title: 'UPI Payment QR Settings',
                          subtitle: 'Upload QR image, UPI ID & receiver details',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminQrSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildNavTile(
                          icon: Icons.people_alt_rounded,
                          color: const Color(0xFF6366F1),
                          title: 'Customer Management',
                          subtitle: 'View registered customers & details',
                          badgeCount: stats.totalCustomers,
                          badgeColor: AppColors.surfaceVariant,
                          badgeTextColor: AppColors.textPrimary,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AdminCustomersScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Orders Feed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Orders',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AdminOrdersScreen(),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (stats.recentOrders.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No orders placed yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...stats.recentOrders.map((order) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrderDetailsScreen(orderId: order.id),
                              ),
                            );
                          },
                          title: Text(
                            order.id,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${order.customerName} • ${DateFormatter.formatDate(order.createdAt)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.format(order.totalAmount),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              StatusBadge(
                                status: order.status,
                                fontSize: 9,
                                showIcon: false,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int? badgeCount,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount != null && badgeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.statusPendingVerification,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: badgeTextColor ?? Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
