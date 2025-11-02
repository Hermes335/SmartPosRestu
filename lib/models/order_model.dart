/// Order model representing a customer order in the POS system
class Order {
  final String id;
  final String tableNumber;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime timestamp;
  final OrderStatus status;
  final String? staffId;

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalAmount,
    required this.timestamp,
    required this.status,
    this.staffId,
  });

  /// Convert Order to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'staffId': staffId,
    };
  }

  /// Create Order from JSON (Firebase)
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      tableNumber: json['tableNumber'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      staffId: json['staffId'],
    );
  }
}

/// Individual item within an order
class OrderItem {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String? notes;

  OrderItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.notes,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
      'notes': notes,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      price: json['price'].toDouble(),
      notes: json['notes'],
    );
  }
}

/// Order status enum
enum OrderStatus {
  pending,
  preparing,
  ready,
  served,
  completed,
  cancelled,
}
