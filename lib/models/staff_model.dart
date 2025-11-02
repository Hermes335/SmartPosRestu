/// Staff model representing restaurant employees
class Staff {
  final String id;
  final String name;
  final String email;
  final StaffRole role;
  final String? photoUrl;
  final DateTime hireDate;
  final double performanceScore;
  final int totalOrdersServed;

  Staff({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
    required this.hireDate,
    this.performanceScore = 0.0,
    this.totalOrdersServed = 0,
  });

  /// Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'photoUrl': photoUrl,
      'hireDate': hireDate.toIso8601String(),
      'performanceScore': performanceScore,
      'totalOrdersServed': totalOrdersServed,
    };
  }

  /// Create from JSON (Firebase)
  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: StaffRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
      ),
      photoUrl: json['photoUrl'],
      hireDate: DateTime.parse(json['hireDate']),
      performanceScore: json['performanceScore']?.toDouble() ?? 0.0,
      totalOrdersServed: json['totalOrdersServed'] ?? 0,
    );
  }

  /// Get role display name
  String get roleDisplayName {
    switch (role) {
      case StaffRole.manager:
        return 'Manager';
      case StaffRole.waiter:
        return 'Waiter';
      case StaffRole.chef:
        return 'Chef';
      case StaffRole.cashier:
        return 'Cashier';
    }
  }
}

/// Staff role enum
enum StaffRole {
  manager,
  waiter,
  chef,
  cashier,
}
