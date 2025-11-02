/// Table model representing a restaurant table
class RestaurantTable {
  final String id;
  final String tableNumber;
  final int capacity;
  final TableStatus status;
  final String? currentOrderId;

  RestaurantTable({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    required this.status,
    this.currentOrderId,
  });

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'capacity': capacity,
      'status': status.toString().split('.').last,
      'currentOrderId': currentOrderId,
    };
  }

  /// Create from JSON (Firebase)
  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'],
      tableNumber: json['tableNumber'],
      capacity: json['capacity'],
      status: TableStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      currentOrderId: json['currentOrderId'],
    );
  }

  /// Create a copy with modified fields
  RestaurantTable copyWith({
    String? id,
    String? tableNumber,
    int? capacity,
    TableStatus? status,
    String? currentOrderId,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      tableNumber: tableNumber ?? this.tableNumber,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      currentOrderId: currentOrderId ?? this.currentOrderId,
    );
  }
}

/// Table status enum
enum TableStatus {
  available,
  occupied,
  reserved,
  cleaning,
}
