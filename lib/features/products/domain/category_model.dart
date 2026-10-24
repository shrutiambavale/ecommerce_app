import '../../../core/utils/parse_helpers.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final bool isActive;
  final int productCount;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = 'category',
    this.isActive = true,
    this.productCount = 0,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      name: ParseHelpers.parseString(map['name']),
      slug: ParseHelpers.parseString(map['slug']),
      icon: ParseHelpers.parseString(map['icon'], 'category'),
      isActive: ParseHelpers.parseBool(map['isActive'], true),
      productCount: ParseHelpers.parseInt(map['productCount'], 0),
      createdAt: ParseHelpers.parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'icon': icon,
      'isActive': isActive,
      'productCount': productCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  CategoryModel copyWith({
    String? name,
    String? slug,
    String? icon,
    bool? isActive,
    int? productCount,
  }) {
    return CategoryModel(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      isActive: isActive ?? this.isActive,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt,
    );
  }
}
