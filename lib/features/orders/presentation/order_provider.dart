import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../cart/domain/cart_item_model.dart';
import '../../cart/domain/cart_summary.dart';
import '../../checkout/domain/address_model.dart';
import '../../payment/presentation/payment_provider.dart';
import '../../products/presentation/product_provider.dart';
import '../data/order_repository.dart';
import '../domain/order_model.dart';
import '../domain/order_status.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final repo = OrderRepository(productRepo);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final customerOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return Stream.value([]);
  }
  return repo.getCustomerOrders(user.id);
});

final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getAllOrders();
});

final orderStatusFilterProvider = StateProvider<OrderStatus?>((ref) => null);

final filteredOrdersProvider = Provider<List<OrderModel>>((ref) {
  final allOrdersAsync = ref.watch(allOrdersProvider);
  final filter = ref.watch(orderStatusFilterProvider);

  return allOrdersAsync.maybeWhen(
    data: (orders) {
      if (filter == null) return orders;
      return orders.where((o) => o.status == filter).toList();
    },
    orElse: () => [],
  );
});

final orderDetailProvider =
    FutureProvider.family<OrderModel?, String>((ref, orderId) {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getOrderById(orderId);
});

class OrderController extends StateNotifier<AsyncValue<void>> {
  final OrderRepository _repo;
  final Ref _ref;

  OrderController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<OrderModel?> placeOrder({
    required UserModel customer,
    required List<CartItemModel> items,
    required AddressModel shippingAddress,
    required CartSummary summary,
  }) async {
    state = const AsyncValue.loading();
    try {
      final order = await _repo.createOrder(
        customer: customer,
        items: items,
        shippingAddress: shippingAddress,
        summary: summary,
      );
      state = const AsyncValue.data(null);
      return order;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<bool> submitPaymentProof({
    required String orderId,
    required String utrNumber,
    String? screenshotUrl,
    required String customerId,
    required String customerName,
    required double amount,
  }) async {
    state = const AsyncValue.loading();
    try {
      // 1. Update order
      await _repo.submitOrderPayment(
        orderId: orderId,
        utrNumber: utrNumber,
        screenshotUrl: screenshotUrl,
      );

      // 2. Record payment submission
      await _ref.read(paymentRepositoryProvider).submitPaymentVerification(
            orderId: orderId,
            customerId: customerId,
            customerName: customerName,
            amount: amount,
            utrNumber: utrNumber,
            screenshotUrl: screenshotUrl,
          );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> approvePayment({
    required String orderId,
    required String adminId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.approveOrderPayment(orderId: orderId, adminId: adminId);
      await _ref.read(paymentRepositoryProvider).updateSubmissionStatus(
            orderId: orderId,
            status: 'approved',
            adminId: adminId,
          );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> rejectPayment({
    required String orderId,
    required String reason,
    required String adminId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectOrderPayment(
        orderId: orderId,
        reason: reason,
        adminId: adminId,
      );
      await _ref.read(paymentRepositoryProvider).updateSubmissionStatus(
            orderId: orderId,
            status: 'rejected',
            rejectionReason: reason,
            adminId: adminId,
          );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateFulfillment({
    required String orderId,
    required OrderStatus nextStatus,
    required String adminId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateFulfillmentStatus(
        orderId: orderId,
        nextStatus: nextStatus,
        adminId: adminId,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> cancelOrder({
    required String orderId,
    required String cancelledBy,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.cancelOrder(
        orderId: orderId,
        cancelledBy: cancelledBy,
        reason: reason,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, AsyncValue<void>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OrderController(repo, ref);
});
