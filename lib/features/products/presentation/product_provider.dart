import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/product_repository.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final repo = ProductRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getCategories();
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final selectedCat = ref.watch(selectedCategoryProvider);
  return repo.getProducts(categoryId: selectedCat);
});

/// Account-isolated product stream for Product Management: only products owned by current admin.
final adminProductsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final selectedCat = ref.watch(selectedCategoryProvider);
  if (user == null) {
    return Stream.value([]);
  }
  return repo.getProductsForOwner(user.id, categoryId: selectedCat);
});

final featuredProductsProvider = Provider<List<ProductModel>>((ref) {
  final asyncProds = ref.watch(productsStreamProvider);
  return asyncProds.maybeWhen(
    data: (prods) => prods.where((p) => p.isFeatured).toList(),
    orElse: () => [],
  );
});

final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, productId) {
  final repo = ref.watch(productRepositoryProvider);
  return repo.getProductById(productId);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(productRepositoryProvider);
  return repo.searchProducts(query);
});

class ProductAdminController extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repo;
  final Ref _ref;

  ProductAdminController(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<String?> uploadImage(Uint8List bytes, String fileName) async {
    try {
      return await _repo.uploadProductImage(bytes, fileName);
    } catch (e) {
      return null;
    }
  }

  Future<bool> saveProduct(ProductModel product, {bool isNew = false}) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw 'Authentication required to manage products.';
      }
      if (isNew) {
        await _repo.addProduct(product, ownerId: user.id);
      } else {
        await _repo.updateProduct(product, ownerId: user.id);
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw 'Authentication required to delete products.';
      }
      await _repo.deleteProduct(productId, ownerId: user.id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> updateStock(String productId, int newStock) async {
    state = const AsyncValue.loading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw 'Authentication required to update stock.';
      }
      await _repo.updateProductStock(productId, newStock, ownerId: user.id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> saveCategory(CategoryModel category, {bool isNew = false}) async {
    state = const AsyncValue.loading();
    try {
      if (isNew) {
        await _repo.addCategory(category);
      } else {
        await _repo.updateCategory(category);
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCategory(categoryId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final productAdminControllerProvider =
    StateNotifierProvider<ProductAdminController, AsyncValue<void>>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductAdminController(repo, ref);
});

