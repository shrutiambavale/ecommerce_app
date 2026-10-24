import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../products/domain/product_model.dart';
import '../data/cart_repository.dart';
import '../domain/cart_item_model.dart';
import '../domain/cart_summary.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final repo = CartRepository();
  final currentUser = ref.watch(currentUserProvider);
  repo.setUserId(currentUser?.id);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final cartItemsProvider = StreamProvider<List<CartItemModel>>((ref) {
  final repo = ref.watch(cartRepositoryProvider);
  return repo.cartStream;
});

final cartSummaryProvider = Provider<CartSummary>((ref) {
  final itemsAsync = ref.watch(cartItemsProvider);
  return itemsAsync.maybeWhen(
    data: (items) => CartSummary.calculate(items),
    orElse: () => CartSummary.calculate([]),
  );
});

final cartItemCountProvider = Provider<int>((ref) {
  final itemsAsync = ref.watch(cartItemsProvider);
  return itemsAsync.maybeWhen(
    data: (items) => items.fold<int>(0, (sum, item) => sum + item.quantity),
    orElse: () => 0,
  );
});

class CartController extends StateNotifier<AsyncValue<void>> {
  final CartRepository _repo;

  CartController(this._repo) : super(const AsyncValue.data(null));

  Future<void> addToCart(ProductModel product, {int quantity = 1}) async {
    state = const AsyncValue.loading();
    try {
      final cartItem = CartItemModel(
        productId: product.id,
        productName: product.name,
        productImage: product.primaryImage,
        unitPrice: product.sellingPrice,
        quantity: quantity,
        availableStock: product.stockQuantity,
        ownerId: product.ownerId,
      );
      await _repo.addItem(cartItem);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    try {
      await _repo.updateQuantity(productId, quantity);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeItem(String productId) async {
    try {
      await _repo.removeItem(productId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> clearCart() async {
    try {
      await _repo.clearCart();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final cartControllerProvider =
    StateNotifierProvider<CartController, AsyncValue<void>>((ref) {
  final repo = ref.watch(cartRepositoryProvider);
  return CartController(repo);
});
