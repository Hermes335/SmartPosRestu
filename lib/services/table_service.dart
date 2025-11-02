import 'package:firebase_database/firebase_database.dart';
import '../models/table_model.dart';

/// Firebase database service for table management
/// Handles CRUD operations for restaurant tables
class TableService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get all tables stream (real-time updates)
  Stream<List<RestaurantTable>> getTablesStream() {
    return _database.child('tables').onValue.map((event) {
      final tables = <RestaurantTable>[];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          tables.add(
              RestaurantTable.fromJson(Map<String, dynamic>.from(value)));
        });
      }
      return tables;
    });
  }

  /// Get single table by ID
  Future<RestaurantTable?> getTable(String tableId) async {
    try {
      final snapshot = await _database.child('tables/$tableId').get();
      if (snapshot.exists) {
        return RestaurantTable.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('Error getting table: $e');
      return null;
    }
  }

  /// Create new table
  Future<void> createTable(RestaurantTable table) async {
    try {
      await _database.child('tables/${table.id}').set(table.toJson());
    } catch (e) {
      print('Error creating table: $e');
      rethrow;
    }
  }

  /// Update existing table
  Future<void> updateTable(RestaurantTable table) async {
    try {
      await _database.child('tables/${table.id}').update(table.toJson());
    } catch (e) {
      print('Error updating table: $e');
      rethrow;
    }
  }

  /// Update table status
  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    try {
      await _database.child('tables/$tableId').update({
        'status': status.toString().split('.').last,
      });
    } catch (e) {
      print('Error updating table status: $e');
      rethrow;
    }
  }

  /// Assign order to table
  Future<void> assignOrderToTable(String tableId, String orderId) async {
    try {
      await _database.child('tables/$tableId').update({
        'currentOrderId': orderId,
        'status': TableStatus.occupied.toString().split('.').last,
      });
    } catch (e) {
      print('Error assigning order to table: $e');
      rethrow;
    }
  }

  /// Clear table (mark as available)
  Future<void> clearTable(String tableId) async {
    try {
      await _database.child('tables/$tableId').update({
        'currentOrderId': null,
        'status': TableStatus.available.toString().split('.').last,
      });
    } catch (e) {
      print('Error clearing table: $e');
      rethrow;
    }
  }

  /// Delete table
  Future<void> deleteTable(String tableId) async {
    try {
      await _database.child('tables/$tableId').remove();
    } catch (e) {
      print('Error deleting table: $e');
      rethrow;
    }
  }

  /// Get available tables
  Future<List<RestaurantTable>> getAvailableTables() async {
    try {
      final snapshot = await _database
          .child('tables')
          .orderByChild('status')
          .equalTo(TableStatus.available.toString().split('.').last)
          .get();

      final tables = <RestaurantTable>[];
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          tables.add(
              RestaurantTable.fromJson(Map<String, dynamic>.from(value)));
        });
      }
      return tables;
    } catch (e) {
      print('Error getting available tables: $e');
      return [];
    }
  }
}
