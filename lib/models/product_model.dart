class ProductModel {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final double wholesalePrice;
  final int minOrderQuantity;
  final String unit;
  final String imageUrl;
  final bool isAvailable;

  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.wholesalePrice,
    required this.minOrderQuantity,
    required this.unit,
    required this.imageUrl,
    required this.isAvailable,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'wholesalePrice': wholesalePrice,
      'minOrderQuantity': minOrderQuantity,
      'unit': unit,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble() ?? 0,
      minOrderQuantity: (map['minOrderQuantity'] as num?)?.toInt() ?? 1,
      unit: map['unit'] as String? ?? 'pcs',
      imageUrl: map['imageUrl'] as String? ?? '',
      isAvailable: map['isAvailable'] as bool? ?? true,
    );
  }
}
