import 'dart:async';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/parse_helpers.dart';
import '../domain/cart_item_model.dart';
import '../domain/cart_summary.dart';

class CartRepository {
  final _cartController = StreamController<List<CartItemModel>>.broadcast();
  final List<CartItemModel> _items = [];
  String? _currentUserId;

  CartRepository() {
    _emitCart();
  }

  Stream<List<CartItemModel>> get cartStream => _cartController.stream;
  List<CartItemModel> get currentItems => List.unmodifiable(_items);

  CartSummary get summary => CartSummary.calculate(_items);

  void setUserId(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    // Wipe in-memory cart on account switch or logout to prevent cross-account leak
    _items.clear();
    _emitCart();

    if (userId != null && FirebaseService.isFirebaseAvailable) {
      _loadUserCartFromFirebase(userId);
    }
  }

  Future<void> _loadUserCartFromFirebase(String userId) async {
    try {
      final doc = await FirebaseService.firestore
          ?.collection(AppConstants.cartsCollection)
          .doc(userId)
          .get();

      // Guard against race conditions if user logged out or switched while awaiting fetch
      if (_currentUserId != userId) return;

      _items.clear();
      if (doc != null && doc.exists && doc.data() != null) {
        final rawItems = doc.data()!['items'] as List<dynamic>? ?? [];
        for (final itemMap in rawItems) {
          if (itemMap is Map) {
            _items.add(CartItemModel.fromMap(ParseHelpers.parseMap(itemMap)));
          }
        }
      }
      _emitCart();
    } catch (_) {}
  }

  Future<void> _syncToFirebase() async {
    if (_currentUserId != null && FirebaseService.isFirebaseAvailable) {
      try {
        await FirebaseService.firestore
            ?.collection(AppConstants.cartsCollection)
            .doc(_currentUserId)
            .set({
          'items': _items.map((i) => i.toMap()).toList(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }

  Future<void> addItem(CartItemModel item) async {
    final existingIndex =
        _items.indexWhere((element) => element.productId == item.productId);

    if (existingIndex != -1) {
      final existing = _items[existingIndex];
      final newQuantity = existing.quantity + item.quantity;
      final clampedQty = newQuantity > existing.availableStock
          ? existing.availableStock
          : newQuantity;

      _items[existingIndex] = existing.copyWith(quantity: clampedQty);
    } else {
      _items.add(item);
    }

    _emitCart();
    await _syncToFirebase();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        final item = _items[index];
        final clamped = quantity > item.availableStock ? item.availableStock : quantity;
        _items[index] = item.copyWith(quantity: clamped);
      }
      _emitCart();
      await _syncToFirebase();
    }
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((i) => i.productId == productId);
    _emitCart();
    await _syncToFirebase();
  }

  Future<void> clearCart() async {
    _items.clear();
    _emitCart();
    await _syncToFirebase();
  }

  void _emitCart() {
    _cartController.add(List.from(_items));
  }

  void dispose() {
    _cartController.close();
  }
}
