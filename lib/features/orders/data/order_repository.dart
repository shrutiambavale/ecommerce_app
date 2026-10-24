import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../auth/domain/user_model.dart';
import '../../cart/domain/cart_item_model.dart';
import '../../cart/domain/cart_summary.dart';
import '../../checkout/domain/address_model.dart';
import '../../products/data/product_repository.dart';
import '../domain/order_model.dart';
import '../domain/order_status.dart';

class OrderRepository {
  final ProductRepository _productRepository;
  final _ordersController = StreamController<List<OrderModel>>.broadcast();

  static final List<OrderModel> _seedOrders = [];

  OrderRepository(this._productRepository) {
    _emitOrders();

    if (FirebaseService.isFirebaseAvailable) {
      FirebaseService.firestore
          ?.collection(AppConstants.ordersCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final orders = <OrderModel>[];
          for (final doc in snapshot.docs) {
            try {
              orders.add(OrderModel.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('Error parsing order ${doc.id}: $e');
            }
          }
          if (orders.isNotEmpty) {
            _ordersController.add(orders);
          }
        }
      }, onError: (e) {
        debugPrint('Orders stream error: $e');
      });
    }
  }

  void _emitOrders() {
    _ordersController.add(List.from(_seedOrders));
  }

  Stream<List<OrderModel>> getAllOrders({OrderStatus? filterStatus}) async* {
    var initial = List<OrderModel>.from(_seedOrders);
    if (filterStatus != null) {
      initial = initial.where((o) => o.status == filterStatus).toList();
    }
    yield initial;

    yield* _ordersController.stream.map((orders) {
      if (filterStatus == null) return orders;
      return orders.where((o) => o.status == filterStatus).toList();
    });
  }

  Stream<List<OrderModel>> getCustomerOrders(String customerId) async* {
    yield _seedOrders.where((o) => o.customerId == customerId).toList();
    yield* _ordersController.stream.map((orders) {
      return orders.where((o) => o.customerId == customerId).toList();
    });
  }

  Future<List<OrderModel>> getAllOrdersOnce() async {
    if (FirebaseService.isFirebaseAvailable) {
      try {
        final snapshot = await FirebaseService.firestore!
            .collection(AppConstants.ordersCollection)
            .orderBy('createdAt', descending: true)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final orders = <OrderModel>[];
          for (final doc in snapshot.docs) {
            try {
              orders.add(OrderModel.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('Error parsing order in getAllOnce ${doc.id}: $e');
            }
          }
          if (orders.isNotEmpty) return orders;
        }
      } catch (e) {
        debugPrint('Error fetching orders: $e');
      }
    }
    return List.from(_seedOrders);
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    if (FirebaseService.isFirebaseAvailable) {
      final doc = await FirebaseService.firestore!
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();
      if (doc.exists && doc.data() != null) {
        return OrderModel.fromMap(doc.data()!, doc.id);
      }
    }
    final matches = _seedOrders.where((o) => o.id == orderId);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Creates order, freezes item prices, and decrements stock safely
  Future<OrderModel> createOrder({
    required UserModel customer,
    required List<CartItemModel> items,
    required AddressModel shippingAddress,
    required CartSummary summary,
  }) async {
    if (items.isEmpty) {
      throw 'Cannot create order with an empty cart.';
    }

    // Step 1: Concurrency-safe stock verification & deduction
    await _productRepository.checkAndDeductStock(items);

    // Step 2: Freeze item snapshots
    final orderItems = items.map((item) {
      return OrderItemModel(
        productId: item.productId,
        productName: item.productName,
        productImage: item.productImage,
        unitPrice: item.unitPrice,
        quantity: item.quantity,
        ownerId: item.ownerId,
      );
    }).toList();

    String? merchantId;
    for (final item in items) {
      if (item.ownerId != null && item.ownerId!.isNotEmpty) {
        merchantId = item.ownerId;
        break;
      }
    }

    final now = DateTime.now();
    final orderId = 'ORD_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch.toString().substring(7)}';

    final newOrder = OrderModel(
      id: orderId,
      customerId: customer.id,
      customerName: customer.fullName,
      customerEmail: customer.email,
      customerPhone: customer.phoneNumber,
      items: orderItems,
      shippingAddress: shippingAddress,
      subtotal: summary.subtotal,
      gstAmount: summary.gstAmount,
      deliveryFee: summary.deliveryFee,
      totalAmount: summary.totalAmount,
      status: OrderStatus.pendingPayment,
      paymentMethod: 'UPI_QR',
      merchantId: merchantId,
      createdAt: now,
      updatedAt: now,
    );

    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .set(newOrder.toMap());
    } else {
      _seedOrders.insert(0, newOrder);
      _emitOrders();
    }

    return newOrder;
  }

  /// Customer submits payment UTR and optional screenshot
  Future<void> submitOrderPayment({
    required String orderId,
    required String utrNumber,
    String? screenshotUrl,
  }) async {
    final order = await getOrderById(orderId);
    if (order == null) throw 'Order not found.';

    if (!order.status.canCustomerSubmitPayment) {
      throw 'Payment cannot be submitted for an order with status "${order.status.displayName}".';
    }

    final now = DateTime.now();
    final updated = order.copyWith(
      status: OrderStatus.paymentVerificationPending,
      utrNumber: utrNumber.trim(),
      paymentScreenshotUrl: screenshotUrl,
    );

    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'status': OrderStatus.paymentVerificationPending.toDbString(),
        'utrNumber': utrNumber.trim(),
        'paymentScreenshotUrl': screenshotUrl,
        'paymentRejectionReason': null, // clear previous reason if resubmitted
        'updatedAt': now.toIso8601String(),
      });
    } else {
      final idx = _seedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _seedOrders[idx] = updated;
        _emitOrders();
      }
    }
  }

  /// Admin approves customer payment after independent bank verification
  Future<void> approveOrderPayment({
    required String orderId,
    required String adminId,
  }) async {
    final order = await getOrderById(orderId);
    if (order == null) throw 'Order not found.';

    if (!order.status.canAdminTransitionTo(OrderStatus.paymentVerified)) {
      throw 'Cannot approve payment for order in status "${order.status.displayName}".';
    }

    final now = DateTime.now();

    if (FirebaseService.isFirebaseAvailable) {
      final batch = FirebaseService.firestore!.batch();

      // Update Order
      final orderRef = FirebaseService.firestore!
          .collection(AppConstants.ordersCollection)
          .doc(orderId);
      batch.update(orderRef, {
        'status': OrderStatus.paymentVerified.toDbString(),
        'verifiedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });

      // Write Audit Log
      final auditRef = FirebaseService.firestore!
          .collection(AppConstants.auditLogsCollection)
          .doc();
      batch.set(auditRef, {
        'action': 'PAYMENT_APPROVED',
        'orderId': orderId,
        'adminId': adminId,
        'previousStatus': order.status.toDbString(),
        'newStatus': OrderStatus.paymentVerified.toDbString(),
        'utrNumber': order.utrNumber,
        'timestamp': now.toIso8601String(),
      });

      await batch.commit();
    } else {
      final idx = _seedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _seedOrders[idx] = _seedOrders[idx].copyWith(
          status: OrderStatus.paymentVerified,
          verifiedAt: now,
        );
        _emitOrders();
      }
    }
  }

  /// Admin rejects customer payment with reason
  Future<void> rejectOrderPayment({
    required String orderId,
    required String reason,
    required String adminId,
  }) async {
    final order = await getOrderById(orderId);
    if (order == null) throw 'Order not found.';

    if (!order.status.canAdminTransitionTo(OrderStatus.paymentRejected)) {
      throw 'Cannot reject payment for order in status "${order.status.displayName}".';
    }

    final now = DateTime.now();

    if (FirebaseService.isFirebaseAvailable) {
      final batch = FirebaseService.firestore!.batch();

      final orderRef = FirebaseService.firestore!
          .collection(AppConstants.ordersCollection)
          .doc(orderId);
      batch.update(orderRef, {
        'status': OrderStatus.paymentRejected.toDbString(),
        'paymentRejectionReason': reason,
        'updatedAt': now.toIso8601String(),
      });

      final auditRef = FirebaseService.firestore!
          .collection(AppConstants.auditLogsCollection)
          .doc();
      batch.set(auditRef, {
        'action': 'PAYMENT_REJECTED',
        'orderId': orderId,
        'adminId': adminId,
        'reason': reason,
        'timestamp': now.toIso8601String(),
      });

      await batch.commit();
    } else {
      final idx = _seedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _seedOrders[idx] = _seedOrders[idx].copyWith(
          status: OrderStatus.paymentRejected,
          paymentRejectionReason: reason,
        );
        _emitOrders();
      }
    }
  }

  /// Admin advances fulfillment status (Processing, Shipped, Delivered)
  Future<void> updateFulfillmentStatus({
    required String orderId,
    required OrderStatus nextStatus,
    required String adminId,
  }) async {
    final order = await getOrderById(orderId);
    if (order == null) throw 'Order not found.';

    if (!order.status.canAdminTransitionTo(nextStatus)) {
      throw 'Invalid status transition from "${order.status.displayName}" to "${nextStatus.displayName}".';
    }

    final now = DateTime.now();

    if (FirebaseService.isFirebaseAvailable) {
      final batch = FirebaseService.firestore!.batch();

      final orderRef = FirebaseService.firestore!
          .collection(AppConstants.ordersCollection)
          .doc(orderId);
      batch.update(orderRef, {
        'status': nextStatus.toDbString(),
        'updatedAt': now.toIso8601String(),
      });

      final auditRef = FirebaseService.firestore!
          .collection(AppConstants.auditLogsCollection)
          .doc();
      batch.set(auditRef, {
        'action': 'STATUS_CHANGE',
        'orderId': orderId,
        'adminId': adminId,
        'previousStatus': order.status.toDbString(),
        'newStatus': nextStatus.toDbString(),
        'timestamp': now.toIso8601String(),
      });

      await batch.commit();
    } else {
      final idx = _seedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _seedOrders[idx] = _seedOrders[idx].copyWith(status: nextStatus);
        _emitOrders();
      }
    }
  }

  /// Cancel order and restore stock
  Future<void> cancelOrder({
    required String orderId,
    required String cancelledBy,
    String? reason,
  }) async {
    final order = await getOrderById(orderId);
    if (order == null) throw 'Order not found.';

    if (!order.status.canCustomerCancel) {
      throw 'Order in "${order.status.displayName}" cannot be cancelled.';
    }

    // Restore stock for all items
    for (final item in order.items) {
      final prod = await _productRepository.getProductById(item.productId);
      if (prod != null) {
        await _productRepository.updateProductStock(
          item.productId,
          prod.stockQuantity + item.quantity,
          ownerId: prod.ownerId ?? 'system',
          isSuperAdmin: true,
        );
      }
    }

    final now = DateTime.now();

    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .update({
        'status': OrderStatus.cancelled.toDbString(),
        'updatedAt': now.toIso8601String(),
      });
    } else {
      final idx = _seedOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        _seedOrders[idx] = _seedOrders[idx].copyWith(status: OrderStatus.cancelled);
        _emitOrders();
      }
    }
  }

  void dispose() {
    _ordersController.close();
  }
}
