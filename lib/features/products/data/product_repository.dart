import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/parse_helpers.dart';
import '../../cart/domain/cart_item_model.dart';
import '../domain/category_model.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final _categoriesController = StreamController<List<CategoryModel>>.broadcast();
  final _productsController = StreamController<List<ProductModel>>.broadcast();

  // Curated, realistic seed categories
  static final List<CategoryModel> _seedCategories = [
    CategoryModel(
      id: 'cat_electronics',
      name: 'Electronics',
      slug: 'electronics',
      icon: 'devices',
      productCount: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
    ),
    CategoryModel(
      id: 'cat_fashion',
      name: 'Fashion & Apparel',
      slug: 'fashion',
      icon: 'checkroom',
      productCount: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
    ),
    CategoryModel(
      id: 'cat_home',
      name: 'Home & Living',
      slug: 'home',
      icon: 'home',
      productCount: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    CategoryModel(
      id: 'cat_accessories',
      name: 'Accessories',
      slug: 'accessories',
      icon: 'watch',
      productCount: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
  ];

  static final List<ProductModel> _seedProducts = [];

  ProductRepository() {
    _emitLocalCategories();
    _emitLocalProducts();

    if (FirebaseService.isFirebaseAvailable) {
      FirebaseService.firestore
          ?.collection(AppConstants.categoriesCollection)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final cats = <CategoryModel>[];
          for (final doc in snapshot.docs) {
            try {
              cats.add(CategoryModel.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('Error parsing category ${doc.id}: $e');
            }
          }
          if (cats.isNotEmpty) {
            _categoriesController.add(cats);
          }
        }
      }, onError: (e) {
        debugPrint('Categories stream error: $e');
      });

      FirebaseService.firestore
          ?.collection(AppConstants.productsCollection)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final prods = <ProductModel>[];
          for (final doc in snapshot.docs) {
            try {
              prods.add(ProductModel.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('Error parsing product ${doc.id}: $e');
            }
          }
          if (prods.isNotEmpty) {
            _seedProducts.clear();
            _seedProducts.addAll(prods);
            _productsController.add(prods);
          }
        }
      }, onError: (e) {
        debugPrint('Products stream error: $e');
      });
    }
  }

  void _emitLocalCategories() {
    _categoriesController.add(List.from(_seedCategories));
  }

  void _emitLocalProducts() {
    _productsController.add(List.from(_seedProducts));
  }

  Stream<List<CategoryModel>> getCategories() async* {
    yield List.from(_seedCategories);
    yield* _categoriesController.stream;
  }

  Future<List<CategoryModel>> getCategoriesOnce() async {
    if (FirebaseService.isFirebaseAvailable) {
      try {
        final snapshot = await FirebaseService.firestore!
            .collection(AppConstants.categoriesCollection)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final cats = <CategoryModel>[];
          for (final doc in snapshot.docs) {
            try {
              cats.add(CategoryModel.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('Error parsing category in getOnce ${doc.id}: $e');
            }
          }
          if (cats.isNotEmpty) {
            _seedCategories.clear();
            _seedCategories.addAll(cats);
            return cats;
          }
        }
      } catch (e) {
        debugPrint('Error fetching categories: $e');
      }
    }
    return List.from(_seedCategories);
  }

  Future<void> addCategory(CategoryModel category) async {
    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .set(category.toMap());
    } else {
      _seedCategories.add(category);
      _emitLocalCategories();
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.categoriesCollection)
          .doc(category.id)
          .update(category.toMap());
    } else {
      final idx = _seedCategories.indexWhere((c) => c.id == category.id);
      if (idx != -1) {
        _seedCategories[idx] = category;
        _emitLocalCategories();
      }
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.categoriesCollection)
          .doc(categoryId)
          .delete();
    } else {
      _seedCategories.removeWhere((c) => c.id == categoryId);
      _emitLocalCategories();
    }
  }

  Stream<List<ProductModel>> getProducts({
    String? categoryId,
    bool featuredOnly = false,
  }) async* {
    var initial = _seedProducts.where((p) => p.isActive).toList();
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      initial = initial.where((p) => p.categoryId == categoryId).toList();
    }
    if (featuredOnly) {
      initial = initial.where((p) => p.isFeatured).toList();
    }
    yield initial;

    yield* _productsController.stream.map((products) {
      var filtered = products.where((p) => p.isActive).toList();
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        filtered = filtered.where((p) => p.categoryId == categoryId).toList();
      }
      if (featuredOnly) {
        filtered = filtered.where((p) => p.isFeatured).toList();
      }
      return filtered;
    });
  }

  /// Stream products strictly owned by the specified owner/admin.
  Stream<List<ProductModel>> getProductsForOwner(
    String ownerId, {
    String? categoryId,
  }) async* {
    var initial = _seedProducts.where((p) => p.ownerId == ownerId).toList();
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      initial = initial.where((p) => p.categoryId == categoryId).toList();
    }
    yield initial;

    yield* _productsController.stream.map((products) {
      var filtered = products.where((p) => p.ownerId == ownerId).toList();
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
        filtered = filtered.where((p) => p.categoryId == categoryId).toList();
      }
      return filtered;
    });
  }

  /// Fetch products owned by a specific admin/owner once
  Future<List<ProductModel>> getProductsForOwnerOnce(String ownerId) async {
    final all = await getAllProductsOnce();
    return all.where((p) => p.ownerId == ownerId).toList();
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final all = await getAllProductsOnce();
    return all.where((p) {
      return p.name.toLowerCase().contains(clean) ||
          p.description.toLowerCase().contains(clean) ||
          p.categoryName.toLowerCase().contains(clean);
    }).toList();
  }

  Future<List<ProductModel>> getAllProductsOnce() async {
    if (FirebaseService.isFirebaseAvailable) {
      try {
        final snapshot = await FirebaseService.firestore!
            .collection(AppConstants.productsCollection)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final prods = <ProductModel>[];
          for (final doc in snapshot.docs) {
            try {
              prods.add(ProductModel.fromMap(doc.data(), doc.id));
            } catch (e) {
              debugPrint('Error parsing product in getAllOnce ${doc.id}: $e');
            }
          }
          if (prods.isNotEmpty) return prods;
        }
      } catch (e) {
        debugPrint('Error fetching products: $e');
      }
    }
    return List.from(_seedProducts);
  }

  Future<ProductModel?> getProductById(String productId) async {
    if (FirebaseService.isFirebaseAvailable) {
      final doc = await FirebaseService.firestore!
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .get();
      if (doc.exists && doc.data() != null) {
        return ProductModel.fromMap(doc.data()!, doc.id);
      }
    }
    final matches = _seedProducts.where((p) => p.id == productId);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Uploads product image bytes to Firebase Storage under AppConstants.productImagesPath
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    if (FirebaseService.isFirebaseAvailable && FirebaseService.storage != null) {
      final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
      final mimeType = ext == 'png'
          ? 'image/png'
          : (ext == 'webp' ? 'image/webp' : 'image/jpeg');
      final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$cleanName';

      final ref = FirebaseService.storage!
          .ref()
          .child(AppConstants.productImagesPath)
          .child(uniqueName);

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: mimeType),
      );
      return await uploadTask.ref.getDownloadURL();
    } else {
      // In local mode, return a reliable placeholder
      return 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=800&q=80';
    }
  }

  Future<void> addProduct(ProductModel product, {required String ownerId}) async {
    final boundProduct = product.copyWith(ownerId: ownerId);
    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.productsCollection)
          .doc(boundProduct.id)
          .set(boundProduct.toMap());
    } else {
      _seedProducts.add(boundProduct);
      _emitLocalProducts();
    }
  }

  Future<void> updateProduct(
    ProductModel product, {
    required String ownerId,
    bool isSuperAdmin = false,
  }) async {
    final existing = await getProductById(product.id);
    if (existing != null &&
        existing.ownerId != null &&
        existing.ownerId != ownerId &&
        !isSuperAdmin) {
      throw 'Unauthorized: You do not have permission to modify this product.';
    }

    final boundProduct = product.copyWith(
      ownerId: existing?.ownerId ?? ownerId,
    );

    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.productsCollection)
          .doc(boundProduct.id)
          .update(boundProduct.toMap());
    } else {
      final idx = _seedProducts.indexWhere((p) => p.id == boundProduct.id);
      if (idx != -1) {
        _seedProducts[idx] = boundProduct;
        _emitLocalProducts();
      }
    }
  }

  Future<void> deleteProduct(
    String productId, {
    required String ownerId,
    bool isSuperAdmin = false,
  }) async {
    final existing = await getProductById(productId);
    if (existing != null &&
        existing.ownerId != null &&
        existing.ownerId != ownerId &&
        !isSuperAdmin) {
      throw 'Unauthorized: You do not have permission to delete this product.';
    }

    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .delete();
    } else {
      _seedProducts.removeWhere((p) => p.id == productId);
      _emitLocalProducts();
    }
  }

  Future<void> updateProductStock(
    String productId,
    int newStock, {
    required String ownerId,
    bool isSuperAdmin = false,
  }) async {
    final existing = await getProductById(productId);
    if (existing != null &&
        existing.ownerId != null &&
        existing.ownerId != ownerId &&
        !isSuperAdmin) {
      throw 'Unauthorized: You do not have permission to adjust stock for this product.';
    }

    if (FirebaseService.isFirebaseAvailable) {
      await FirebaseService.firestore!
          .collection(AppConstants.productsCollection)
          .doc(productId)
          .update({
        'stockQuantity': newStock,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      final idx = _seedProducts.indexWhere((p) => p.id == productId);
      if (idx != -1) {
        _seedProducts[idx] = _seedProducts[idx].copyWith(stockQuantity: newStock);
        _emitLocalProducts();
      }
    }
  }

  /// Concurrency-safe atomic inventory deduction
  Future<bool> checkAndDeductStock(List<CartItemModel> items) async {
    if (FirebaseService.isFirebaseAvailable) {
      final firestore = FirebaseService.firestore!;
      return await firestore.runTransaction<bool>((transaction) async {
        // Step 1: Read and verify all products first (Firestore transaction requirement)
        final productDocs = <DocumentReference, DocumentSnapshot>{};
        for (final item in items) {
          final docRef = firestore
              .collection(AppConstants.productsCollection)
              .doc(item.productId);
          final docSnap = await transaction.get(docRef);
          if (!docSnap.exists) {
            throw 'Product ${item.productName} is no longer available.';
          }
          final dataMap = ParseHelpers.parseMap(docSnap.data());
          final currentStock = ParseHelpers.parseInt(dataMap['stockQuantity']);
          if (currentStock < item.quantity) {
            throw 'Insufficient stock for ${item.productName}. Available: $currentStock';
          }
          productDocs[docRef] = docSnap;
        }

        // Step 2: Write all deductions
        for (final item in items) {
          final docRef = firestore
              .collection(AppConstants.productsCollection)
              .doc(item.productId);
          final docSnap = productDocs[docRef]!;
          final dataMap = ParseHelpers.parseMap(docSnap.data());
          final currentStock = ParseHelpers.parseInt(dataMap['stockQuantity']);
          transaction.update(docRef, {
            'stockQuantity': currentStock - item.quantity,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
        return true;
      });
    } else {
      // Local check & deduction
      for (final item in items) {
        final idx = _seedProducts.indexWhere((p) => p.id == item.productId);
        if (idx == -1) {
          throw 'Product ${item.productName} no longer exists.';
        }
        if (_seedProducts[idx].stockQuantity < item.quantity) {
          throw 'Insufficient stock for ${item.productName}. Available: ${_seedProducts[idx].stockQuantity}';
        }
      }

      for (final item in items) {
        final idx = _seedProducts.indexWhere((p) => p.id == item.productId);
        if (idx != -1) {
          final updated = _seedProducts[idx].copyWith(
            stockQuantity: _seedProducts[idx].stockQuantity - item.quantity,
          );
          _seedProducts[idx] = updated;
        }
      }
      _emitLocalProducts();
      return true;
    }
  }

  void dispose() {
    _categoriesController.close();
    _productsController.close();
  }
}
