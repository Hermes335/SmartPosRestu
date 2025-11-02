import 'package:firebase_database/firebase_database.dart';
import '../models/order_model.dart';

/// Firebase database service for order management
/// Handles CRUD operations for orders in real-time database
class OrderService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get orders stream (real-time updates)
  Stream<List<Order>> getOrdersStream() {
    return _database.child('orders').onValue.map((event) {
      final orders = <Order>[];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          orders.add(Order.fromJson(Map<String, dynamic>.from(value)));
        });
      }
      return orders;
    });
  }

  /// Get single order by ID
  Future<Order?> getOrder(String orderId) async {
    try {
      final snapshot = await _database.child('orders/$orderId').get();
      if (snapshot.exists) {
        return Order.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  /// Create new order
  Future<void> createOrder(Order order) async {
    try {
      await _database.child('orders/${order.id}').set(order.toJson());
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  /// Update existing order
  Future<void> updateOrder(Order order) async {
    try {
      await _database.child('orders/${order.id}').update(order.toJson());
    } catch (e) {
      print('Error updating order: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _database.child('orders/$orderId').update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating order status: $e');
      rethrow;
    }
  }

  /// Delete order
  Future<void> deleteOrder(String orderId) async {
    try {
      await _database.child('orders/$orderId').remove();
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  /// Get orders by table number
  Future<List<Order>> getOrdersByTable(String tableNumber) async {
    try {
      final snapshot = await _database
          .child('orders')
          .orderByChild('tableNumber')
          .equalTo(tableNumber)
          .get();

      final orders = <Order>[];
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          orders.add(Order.fromJson(Map<String, dynamic>.from(value)));
        });
      }
      return orders;
    } catch (e) {
      print('Error getting orders by table: $e');
      return [];
    }
  }

  /// Get today's orders
  Future<List<Order>> getTodaysOrders() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _database.child('orders').get();

      final orders = <Order>[];
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          final order = Order.fromJson(Map<String, dynamic>.from(value));
          if (order.timestamp.isAfter(startOfDay)) {
            orders.add(order);
          }
        });
      }
      return orders;
    } catch (e) {
      print('Error getting today\'s orders: $e');
      return [];
    }
  }
}
