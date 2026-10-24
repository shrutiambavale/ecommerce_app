import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../orders/domain/order_model.dart';
import '../../orders/domain/order_status.dart';
import '../../orders/presentation/order_provider.dart';

class AdminPaymentVerificationScreen extends ConsumerStatefulWidget {
  const AdminPaymentVerificationScreen({super.key});

  @override
  ConsumerState<AdminPaymentVerificationScreen> createState() =>
      _AdminPaymentVerificationScreenState();
}

class _AdminPaymentVerificationScreenState
    extends ConsumerState<AdminPaymentVerificationScreen> {
  final Set<String> _processingOrderIds = {};

  Future<void> _approveOrderPayment(OrderModel order) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Approve Payment?',
      message:
          'Confirm that you have independently verified receipt of ${CurrencyFormatter.format(order.totalAmount)} in your bank account matching UTR "${order.utrNumber}".',
      confirmText: 'Approve & Mark Verified',
      confirmColor: AppColors.success,
      icon: Icons.verified_user_rounded,
    );

    if (confirmed == true && mounted) {
      setState(() => _processingOrderIds.add(order.id));
      final admin = ref.read(currentUserProvider);

      final success = await ref
          .read(orderControllerProvider.notifier)
          .approvePayment(
            orderId: order.id,
            adminId: admin?.fullName ?? 'Admin',
          );

      if (mounted) {
        setState(() => _processingOrderIds.remove(order.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Payment for ${order.id} approved and order marked as Verified.'
                  : 'Failed to approve payment.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrderPayment(OrderModel order) async {
    final reasonController = TextEditingController();
    final reasonFormKey = GlobalKey<FormState>();

    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Reject Payment'),
          ],
        ),
        content: Form(
          key: reasonFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provide a clear reason for rejecting the payment submission for ${order.id}. This will be visible to the customer.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a reason for rejection';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText:
                      'e.g. UTR not found in bank statement, amount mismatch...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonFormKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );

    if (shouldReject == true && mounted) {
      setState(() => _processingOrderIds.add(order.id));
      final admin = ref.read(currentUserProvider);

      final success = await ref
          .read(orderControllerProvider.notifier)
          .rejectPayment(
            orderId: order.id,
            reason: reasonController.text.trim(),
            adminId: admin?.fullName ?? 'Admin',
          );

      if (mounted) {
        setState(() => _processingOrderIds.remove(order.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Payment for ${order.id} rejected with audit record.'
                  : 'Failed to reject payment.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _previewScreenshot(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Customer Payment Screenshot'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 460),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppCachedImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allOrdersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Verifications'),
      ),
      body: allOrdersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allOrders) {
          final pendingOrders = allOrders
              .where((o) => o.status == OrderStatus.paymentVerificationPending)
              .toList();

          if (pendingOrders.isEmpty) {
            return const EmptyStateView(
              icon: Icons.verified_rounded,
              title: 'All Payments Verified!',
              message:
                  'There are no pending customer UPI payment submissions requiring verification at this time.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: pendingOrders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = pendingOrders[index];
              final isProcessing = _processingOrderIds.contains(order.id);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.statusPendingVerification,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order.id,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          DateFormatter.formatDateTime(order.updatedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Customer Info
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.customerName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${order.customerEmail} • ${order.customerPhone}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Ordered Items Summary
                    Text(
                      'Items: ${order.items.map((i) => '${i.quantity}x ${i.productName}').join(', ')}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Payable Amount & UTR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payable Total',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(order.totalAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Submitted UTR / Ref',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    order.utrNumber ?? 'N/A',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                if (order.utrNumber != null)
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: order.utrNumber!),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('UTR copied to clipboard!'),
                                          duration: Duration(milliseconds: 1000),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.copy_rounded,
                                      size: 14,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Screenshot Preview Button (if attached)
                    if (order.paymentScreenshotUrl != null &&
                        order.paymentScreenshotUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.receipt_rounded, size: 16),
                        label: const Text('View Payment Screenshot'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 38),
                        ),
                        onPressed: () => _previewScreenshot(
                          context,
                          order.paymentScreenshotUrl!,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Verification Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Reject',
                            variant: ButtonVariant.danger,
                            height: 42,
                            isLoading: isProcessing,
                            onPressed: () => _rejectOrderPayment(order),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Approve Payment',
                            variant: ButtonVariant.secondary,
                            height: 42,
                            isLoading: isProcessing,
                            icon: Icons.check_rounded,
                            onPressed: () => _approveOrderPayment(order),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
