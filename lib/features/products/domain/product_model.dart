import '../../../core/utils/parse_helpers.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String categoryName;
  final double sellingPrice;
  final double originalPrice;
  final int stockQuantity;
  final List<String> images;
  final String? ownerId;
  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    required this.sellingPrice,
    required this.originalPrice,
    required this.stockQuantity,
    required this.images,
    this.ownerId,
    this.isFeatured = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get inStock => stockQuantity > 0;
  bool get isLowStock => stockQuantity > 0 && stockQuantity <= 5;

  String get primaryImage => images.isNotEmpty ? images.first : '';

  int get discountPercentage {
    if (originalPrice <= sellingPrice || originalPrice <= 0) return 0;
    return (((originalPrice - sellingPrice) / originalPrice) * 100).round();
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: ParseHelpers.parseString(map['name']),
      description: ParseHelpers.parseString(map['description']),
      categoryId: ParseHelpers.parseString(map['categoryId']),
      categoryName: ParseHelpers.parseString(map['categoryName']),
      sellingPrice: ParseHelpers.parseDouble(map['sellingPrice']),
      originalPrice: ParseHelpers.parseDouble(map['originalPrice']),
      stockQuantity: ParseHelpers.parseInt(map['stockQuantity']),
      images: ParseHelpers.parseStringList(map['images']),
      ownerId: ParseHelpers.parseNullableString(
        map['ownerId'] ?? map['sellerId'] ?? map['adminId'],
      ),
      isFeatured: ParseHelpers.parseBool(map['isFeatured'], false),
      isActive: ParseHelpers.parseBool(map['isActive'], true),
      createdAt: ParseHelpers.parseDateTime(map['createdAt']),
      updatedAt: ParseHelpers.parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'sellingPrice': sellingPrice,
      'originalPrice': originalPrice,
      'stockQuantity': stockQuantity,
      'images': images,
      'ownerId': ownerId,
      'isFeatured': isFeatured,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ProductModel copyWith({
    String? name,
    String? description,
    String? categoryId,
    String? categoryName,
    double? sellingPrice,
    double? originalPrice,
    int? stockQuantity,
    List<String>? images,
    String? ownerId,
    bool? isFeatured,
    bool? isActive,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      images: images ?? this.images,
      ownerId: ownerId ?? this.ownerId,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
