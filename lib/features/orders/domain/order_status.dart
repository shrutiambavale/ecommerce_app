import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum OrderStatus {
  pendingPayment,
  paymentVerificationPending,
  paymentVerified,
  processing,
  shipped,
  delivered,
  cancelled,
  paymentRejected;

  String get displayName {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'Pending Payment';
      case OrderStatus.paymentVerificationPending:
        return 'Payment Verification Pending';
      case OrderStatus.paymentVerified:
        return 'Payment Verified';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.paymentRejected:
        return 'Payment Rejected';
    }
  }

  String get shortDisplayName {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'Pending Pay';
      case OrderStatus.paymentVerificationPending:
        return 'Verify Pending';
      case OrderStatus.paymentVerified:
        return 'Verified';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.paymentRejected:
        return 'Rejected';
    }
  }

  String toDbString() {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'pending_payment';
      case OrderStatus.paymentVerificationPending:
        return 'payment_verification_pending';
      case OrderStatus.paymentVerified:
        return 'payment_verified';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.shipped:
        return 'shipped';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
      case OrderStatus.paymentRejected:
        return 'payment_rejected';
    }
  }

  static OrderStatus fromString(String? status) {
    if (status == null) return OrderStatus.pendingPayment;
    switch (status.toLowerCase().trim()) {
      case 'payment_verification_pending':
        return OrderStatus.paymentVerificationPending;
      case 'payment_verified':
        return OrderStatus.paymentVerified;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'payment_rejected':
        return OrderStatus.paymentRejected;
      case 'pending_payment':
      default:
        return OrderStatus.pendingPayment;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pendingPayment:
        return AppColors.statusPendingPayment;
      case OrderStatus.paymentVerificationPending:
        return AppColors.statusPendingVerification;
      case OrderStatus.paymentVerified:
        return AppColors.statusVerified;
      case OrderStatus.processing:
        return AppColors.statusProcessing;
      case OrderStatus.shipped:
        return AppColors.statusShipped;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
      case OrderStatus.paymentRejected:
        return AppColors.statusRejected;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case OrderStatus.pendingPayment:
        return const Color(0xFFFEF3C7); // Amber 100
      case OrderStatus.paymentVerificationPending:
        return const Color(0xFFF3E8FF); // Purple 100
      case OrderStatus.paymentVerified:
        return const Color(0xFFD1FAE5); // Emerald 100
      case OrderStatus.processing:
        return const Color(0xFFDBEAFE); // Blue 100
      case OrderStatus.shipped:
        return const Color(0xFFE0F2FE); // Sky 100
      case OrderStatus.delivered:
        return const Color(0xFFDCFCE7); // Green 100
      case OrderStatus.cancelled:
        return const Color(0xFFF1F5F9); // Slate 100
      case OrderStatus.paymentRejected:
        return const Color(0xFFFEE2E2); // Red 100
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pendingPayment:
        return Icons.payment_rounded;
      case OrderStatus.paymentVerificationPending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.paymentVerified:
        return Icons.verified_rounded;
      case OrderStatus.processing:
        return Icons.inventory_2_outlined;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.paymentRejected:
        return Icons.error_outline_rounded;
    }
  }

  /// Determines if an admin transition to [nextStatus] is valid
  bool canAdminTransitionTo(OrderStatus nextStatus) {
    if (this == nextStatus) return false;
    switch (this) {
      case OrderStatus.pendingPayment:
        return nextStatus == OrderStatus.cancelled;
      case OrderStatus.paymentVerificationPending:
        return nextStatus == OrderStatus.paymentVerified ||
            nextStatus == OrderStatus.paymentRejected ||
            nextStatus == OrderStatus.cancelled;
      case OrderStatus.paymentVerified:
        return nextStatus == OrderStatus.processing ||
            nextStatus == OrderStatus.cancelled;
      case OrderStatus.processing:
        return nextStatus == OrderStatus.shipped ||
            nextStatus == OrderStatus.cancelled;
      case OrderStatus.shipped:
        return nextStatus == OrderStatus.delivered ||
            nextStatus == OrderStatus.cancelled;
      case OrderStatus.delivered:
        return false; // Terminal state
      case OrderStatus.cancelled:
        return false; // Terminal state
      case OrderStatus.paymentRejected:
        return nextStatus == OrderStatus.cancelled;
    }
  }

  /// Determines if a customer can cancel the order
  bool get canCustomerCancel {
    return this == OrderStatus.pendingPayment ||
        this == OrderStatus.paymentVerificationPending;
  }

  /// Determines if the customer can submit or re-submit a payment
  bool get canCustomerSubmitPayment {
    return this == OrderStatus.pendingPayment ||
        this == OrderStatus.paymentRejected;
  }
}
