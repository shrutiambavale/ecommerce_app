import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/order_status.dart';

class OrderStatusTimeline extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusTimeline({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return _buildAlertBox(
        icon: Icons.cancel_outlined,
        color: AppColors.error,
        title: 'Order Cancelled',
        message: 'This order has been cancelled and returned to inventory.',
      );
    }

    if (status == OrderStatus.paymentRejected) {
      return _buildAlertBox(
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        title: 'Payment Verification Failed',
        message:
            'The admin could not verify receipt of your payment. Please re-check your UTR reference and resubmit.',
      );
    }

    final steps = [
      _TimelineStep(
        title: 'Placed',
        subtitle: 'Pending Payment',
        isCompleted: true,
        isActive: status == OrderStatus.pendingPayment,
      ),
      _TimelineStep(
        title: 'Verification',
        subtitle: 'UTR Submitted',
        isCompleted: status != OrderStatus.pendingPayment,
        isActive: status == OrderStatus.paymentVerificationPending,
      ),
      _TimelineStep(
        title: 'Processing',
        subtitle: 'Payment Verified',
        isCompleted: status == OrderStatus.processing ||
            status == OrderStatus.shipped ||
            status == OrderStatus.delivered,
        isActive: status == OrderStatus.paymentVerified ||
            status == OrderStatus.processing,
      ),
      _TimelineStep(
        title: 'Shipped',
        subtitle: 'In Transit',
        isCompleted: status == OrderStatus.shipped ||
            status == OrderStatus.delivered,
        isActive: status == OrderStatus.shipped,
      ),
      _TimelineStep(
        title: 'Delivered',
        subtitle: 'Order Complete',
        isCompleted: status == OrderStatus.delivered,
        isActive: status == OrderStatus.delivered,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : (step.isCompleted
                                ? AppColors.success
                                : AppColors.border),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: step.isActive
                            ? AppColors.primary
                            : (step.isCompleted
                                ? AppColors.success
                                : AppColors.surfaceVariant),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.isActive
                              ? AppColors.primary
                              : (step.isCompleted
                                  ? AppColors.success
                                  : AppColors.border),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          step.isCompleted ? Icons.check : Icons.circle,
                          size: step.isCompleted ? 14 : 8,
                          color: (step.isCompleted || step.isActive)
                              ? Colors.white
                              : AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isLast
                            ? Colors.transparent
                            : (steps[index + 1].isCompleted
                                ? AppColors.success
                                : AppColors.border),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: step.isActive ? FontWeight.w800 : FontWeight.w600,
                    color: step.isActive
                        ? AppColors.primary
                        : (step.isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAlertBox({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
  });
}
