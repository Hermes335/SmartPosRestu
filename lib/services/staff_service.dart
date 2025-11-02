import 'package:firebase_database/firebase_database.dart';
import '../models/staff_model.dart';

/// Firebase database service for staff management
/// Handles CRUD operations for restaurant staff
class StaffService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get all staff stream (real-time updates)
  Stream<List<Staff>> getStaffStream() {
    return _database.child('staff').onValue.map((event) {
      final staffList = <Staff>[];
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          staffList.add(Staff.fromJson(Map<String, dynamic>.from(value)));
        });
      }
      return staffList;
    });
  }

  /// Get single staff member by ID
  Future<Staff?> getStaff(String staffId) async {
    try {
      final snapshot = await _database.child('staff/$staffId').get();
      if (snapshot.exists) {
        return Staff.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map));
      }
      return null;
    } catch (e) {
      print('Error getting staff: $e');
      return null;
    }
  }

  /// Create new staff member
  Future<void> createStaff(Staff staff) async {
    try {
      await _database.child('staff/${staff.id}').set(staff.toJson());
    } catch (e) {
      print('Error creating staff: $e');
      rethrow;
    }
  }

  /// Update existing staff member
  Future<void> updateStaff(Staff staff) async {
    try {
      await _database.child('staff/${staff.id}').update(staff.toJson());
    } catch (e) {
      print('Error updating staff: $e');
      rethrow;
    }
  }

  /// Update staff performance score
  Future<void> updatePerformanceScore(
      String staffId, double performanceScore) async {
    try {
      await _database.child('staff/$staffId').update({
        'performanceScore': performanceScore,
      });
    } catch (e) {
      print('Error updating performance score: $e');
      rethrow;
    }
  }

  /// Increment staff order count
  Future<void> incrementOrderCount(String staffId) async {
    try {
      final snapshot = await _database.child('staff/$staffId').get();
      if (snapshot.exists) {
        final staff = Staff.fromJson(
            Map<String, dynamic>.from(snapshot.value as Map));
        await _database.child('staff/$staffId').update({
          'totalOrdersServed': staff.totalOrdersServed + 1,
        });
      }
    } catch (e) {
      print('Error incrementing order count: $e');
      rethrow;
    }
  }

  /// Delete staff member
  Future<void> deleteStaff(String staffId) async {
    try {
      await _database.child('staff/$staffId').remove();
    } catch (e) {
      print('Error deleting staff: $e');
      rethrow;
    }
  }

  /// Get staff by role
  Future<List<Staff>> getStaffByRole(StaffRole role) async {
    try {
      final snapshot = await _database
          .child('staff')
          .orderByChild('role')
          .equalTo(role.toString().split('.').last)
          .get();

      final staffList = <Staff>[];
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          staffList.add(Staff.fromJson(Map<String, dynamic>.from(value)));
        });
      }
      return staffList;
    } catch (e) {
      print('Error getting staff by role: $e');
      return [];
    }
  }
}
