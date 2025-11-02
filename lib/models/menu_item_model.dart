/// Menu item model representing dishes available in the restaurant
class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final MenuCategory category;
  final String? imageUrl;
  final bool isAvailable;
  final int salesCount;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
    this.salesCount = 0,
  });

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category.toString().split('.').last,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'salesCount': salesCount,
    };
  }

  /// Create from JSON (Firebase)
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      category: MenuCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
      ),
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'] ?? true,
      salesCount: json['salesCount'] ?? 0,
    );
  }
}

/// Menu category enum
enum MenuCategory {
  appetizer,
  mainCourse,
  dessert,
  beverage,
  special,
}
