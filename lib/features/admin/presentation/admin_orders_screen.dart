import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../orders/domain/order_model.dart';
import '../../orders/domain/order_status.dart';
import '../../orders/presentation/order_details_screen.dart';
import '../../orders/presentation/order_provider.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  OrderStatus? _selectedStatusFilter;
  String _searchQuery = '';

  Future<void> _transitionOrderStatus(
    OrderModel order,
    OrderStatus nextStatus,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Update Order Status?',
      message:
          'Are you sure you want to transition order ${order.id} from "${order.status.displayName}" to "${nextStatus.displayName}"?',
      confirmText: 'Update Status',
      confirmColor: nextStatus == OrderStatus.cancelled
          ? AppColors.error
          : AppColors.primary,
    );

    if (confirmed == true && mounted) {
      final admin = ref.read(currentUserProvider);
      final success = await ref
          .read(orderControllerProvider.notifier)
          .updateFulfillment(
            orderId: order.id,
            nextStatus: nextStatus,
            adminId: admin?.fullName ?? 'Admin',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Order ${order.id} updated to ${nextStatus.displayName}'
                  : 'Failed to update order status.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOrdersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Fulfillment'),
      ),
      body: Column(
        children: [
          // Search & Status Filter Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search order ID or customer name...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('All Orders'),
                          selected: _selectedStatusFilter == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedStatusFilter = null);
                            }
                          },
                        ),
                      ),
                      ...OrderStatus.values.map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status.displayName),
                            selected: _selectedStatusFilter == status,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatusFilter =
                                    selected ? status : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: allOrdersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (allOrders) {
                var orders = allOrders;

                if (_selectedStatusFilter != null) {
                  orders = orders
                      .where((o) => o.status == _selectedStatusFilter)
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  orders = orders.where((o) {
                    return o.id.toLowerCase().contains(q) ||
                        o.customerName.toLowerCase().contains(q) ||
                        o.customerEmail.toLowerCase().contains(q);
                  }).toList();
                }

                if (orders.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Matching Orders',
                    message:
                        'No orders found matching the selected filter or search criteria.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    // Determine valid next transitions for this order
                    final nextTransitions = OrderStatus.values
                        .where((s) => order.status.canAdminTransitionTo(s))
                        .toList();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OrderDetailsScreen(orderId: order.id),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    order.id,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                status: order.status,
                                fontSize: 11,
                                useShortName: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Customer: ${order.customerName} (${order.customerPhone})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            '${order.items.length} items • ${CurrencyFormatter.format(order.totalAmount)} • ${DateFormatter.formatDateTime(order.createdAt)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          if (nextTransitions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Transition to:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                ...nextTransitions.map((next) {
                                  return ActionChip(
                                    label: Text(
                                      next.displayName,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: next == OrderStatus.cancelled
                                            ? AppColors.error
                                            : AppColors.primary,
                                      ),
                                    ),
                                    backgroundColor:
                                        next.color.withValues(alpha: 0.12),
                                    side: BorderSide(
                                      color: next.color.withValues(alpha: 0.3),
                                    ),
                                    onPressed: () =>
                                        _transitionOrderStatus(order, next),
                                  );
                                }),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
