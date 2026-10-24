import 'package:ecommerce_app/features/orders/domain/order_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OrderStatus State Transitions Unit Tests', () {
    test('Pending Payment transitions correctly', () {
      const status = OrderStatus.pendingPayment;
      expect(status.canCustomerCancel, true);
      expect(status.canCustomerSubmitPayment, true);
      expect(status.canAdminTransitionTo(OrderStatus.cancelled), true);
      expect(status.canAdminTransitionTo(OrderStatus.delivered), false);
    });

    test('Payment Verification Pending transitions correctly', () {
      const status = OrderStatus.paymentVerificationPending;
      expect(status.canCustomerCancel, true);
      expect(status.canCustomerSubmitPayment, false); // Already submitted
      expect(status.canAdminTransitionTo(OrderStatus.paymentVerified), true);
      expect(status.canAdminTransitionTo(OrderStatus.paymentRejected), true);
      expect(status.canAdminTransitionTo(OrderStatus.delivered), false);
    });

    test('Payment Verified transitions to Processing or Cancelled', () {
      const status = OrderStatus.paymentVerified;
      expect(status.canCustomerCancel, false);
      expect(status.canAdminTransitionTo(OrderStatus.processing), true);
      expect(status.canAdminTransitionTo(OrderStatus.cancelled), true);
      expect(status.canAdminTransitionTo(OrderStatus.delivered), false);
    });

    test('Processing transitions to Shipped or Cancelled', () {
      const status = OrderStatus.processing;
      expect(status.canAdminTransitionTo(OrderStatus.shipped), true);
      expect(status.canAdminTransitionTo(OrderStatus.cancelled), true);
      expect(status.canAdminTransitionTo(OrderStatus.delivered), false);
    });

    test('Shipped transitions to Delivered or Cancelled', () {
      const status = OrderStatus.shipped;
      expect(status.canAdminTransitionTo(OrderStatus.delivered), true);
      expect(status.canAdminTransitionTo(OrderStatus.cancelled), true);
      expect(status.canAdminTransitionTo(OrderStatus.processing), false);
    });

    test('Delivered and Cancelled are terminal states', () {
      const delivered = OrderStatus.delivered;
      const cancelled = OrderStatus.cancelled;

      for (final s in OrderStatus.values) {
        expect(delivered.canAdminTransitionTo(s), false);
        expect(cancelled.canAdminTransitionTo(s), false);
      }
    });

    test('Payment Rejected allows customer resubmission', () {
      const status = OrderStatus.paymentRejected;
      expect(status.canCustomerSubmitPayment, true);
      expect(status.canAdminTransitionTo(OrderStatus.cancelled), true);
    });
  });
}
