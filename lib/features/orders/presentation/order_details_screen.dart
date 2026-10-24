import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_cached_image.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../payment/presentation/upi_qr_payment_screen.dart';
import '../domain/order_status.dart';
import 'order_provider.dart';
import 'widgets/order_status_timeline.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: orderAsync.when(
        loading: () => const LoadingView(message: 'Loading order details...'),
        error: (err, _) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.refresh(orderDetailProvider(widget.orderId)),
        ),
        data: (order) {
          if (order == null) {
            return const ErrorStateView(
              title: 'Order Not Found',
              message: 'This order could not be located in our records.',
            );
          }

          final isOwner = currentUser != null && currentUser.id == order.customerId;
          final isAdmin = currentUser?.role == UserRole.admin;
          if (!isOwner && !isAdmin) {
            return const ErrorStateView(
              title: 'Access Denied',
              message: 'You are not authorized to view the details of this order.',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Order Info & Status Card
                Container(
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
                        children: [
                          Expanded(
                            child: Text(
                              order.id,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          StatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Placed on ${DateFormatter.formatDateTime(order.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      OrderStatusTimeline(status: order.status),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Resubmit or Pay Now Callout (if pending payment or payment rejected)
                if (order.status.canCustomerSubmitPayment) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: order.status == OrderStatus.paymentRejected
                          ? AppColors.errorBackground
                          : AppColors.warningBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: order.status == OrderStatus.paymentRejected
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              order.status == OrderStatus.paymentRejected
                                  ? Icons.error_outline_rounded
                                  : Icons.payment_rounded,
                              color: order.status == OrderStatus.paymentRejected
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                order.status == OrderStatus.paymentRejected
                                    ? 'Payment Rejected by Admin'
                                    : 'Awaiting UPI Payment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: order.status == OrderStatus.paymentRejected
                                      ? AppColors.error
                                      : AppColors.statusPendingPayment,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (order.paymentRejectionReason != null &&
                            order.paymentRejectionReason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${order.paymentRejectionReason}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        CustomButton(
                          text: order.status == OrderStatus.paymentRejected
                              ? 'Re-submit Payment with UTR'
                              : 'Pay Now via UPI QR',
                          variant: ButtonVariant.primary,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    UpiQrPaymentScreen(order: order),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Payment Details Card (if UTR exists)
                if (order.utrNumber != null && order.utrNumber!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Information',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Submitted UTR / Ref:',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      order.utrNumber ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: () {
                                      if (order.utrNumber != null) {
                                        Clipboard.setData(
                                          ClipboardData(text: order.utrNumber!),
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('UTR copied!'),
                                            duration: Duration(milliseconds: 1000),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Icon(
                                      Icons.copy_rounded,
                                      size: 16,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (order.paymentScreenshotUrl != null &&
                            order.paymentScreenshotUrl!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Payment Screenshot:',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              _showScreenshotDialog(
                                context,
                                order.paymentScreenshotUrl!,
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AppCachedImage(
                                imageUrl: order.paymentScreenshotUrl!,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Ordered Items Snapshot
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Items in this Order (${order.items.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              AppCachedImage(
                                imageUrl: item.productImage,
                                width: 50,
                                height: 50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.quantity} x ${CurrencyFormatter.format(item.unitPrice)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(item.totalPrice),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Delivery Address Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        order.shippingAddress.fullName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.shippingAddress.fullAddress,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mobile: ${order.shippingAddress.phoneNumber}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Price Breakdown Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price Summary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow('Items Subtotal', order.subtotal),
                      const SizedBox(height: 8),
                      _buildPriceRow('Applicable GST (18%)', order.gstAmount),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Charges',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            order.deliveryFee == 0
                                ? 'FREE'
                                : CurrencyFormatter.format(order.deliveryFee),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: order.deliveryFee == 0
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
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
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Cancellation Option
                if (order.status.canCustomerCancel) ...[
                  CustomButton(
                    text: 'Cancel Order',
                    variant: ButtonVariant.danger,
                    isLoading: _isCancelling,
                    onPressed: () async {
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Cancel Order?',
                        message:
                            'Are you sure you want to cancel this order? The reserved inventory stock will be restored immediately.',
                        confirmText: 'Yes, Cancel Order',
                        confirmColor: AppColors.error,
                      );

                      if (confirmed == true && mounted) {
                        setState(() => _isCancelling = true);
                        await ref
                            .read(orderControllerProvider.notifier)
                            .cancelOrder(
                              orderId: order.id,
                              cancelledBy: currentUser?.fullName ?? 'Customer',
                              reason: 'Customer initiated cancellation',
                            );
                        ref.invalidate(orderDetailProvider(widget.orderId));
                        setState(() => _isCancelling = false);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showScreenshotDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Payment Receipt Screenshot'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppCachedImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
