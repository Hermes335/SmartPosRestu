import 'package:flutter/material.dart';
import '../models/staff_model.dart';
import '../utils/constants.dart';
import '../widgets/staff_card.dart';

/// Staff Management screen - View staff and their performance
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({Key? key}) : super(key: key);

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final List<Staff> _staffList = [];
  StaffRole? _filterRole;

  @override
  void initState() {
    super.initState();
    _generateMockStaff();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.darkSecondary,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.people,
              color: AppConstants.primaryOrange,
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            const Text(
              'Staff',
              style: AppConstants.headingMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(),

          // Staff list
          Expanded(
            child: _buildStaffList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewStaff,
        backgroundColor: AppConstants.primaryOrange,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }

  /// Stats bar showing staff metrics
  Widget _buildStatsBar() {
    final totalStaff = _staffList.length;
    final avgPerformance = _staffList.isEmpty
        ? 0.0
        : _staffList.map((s) => s.performanceScore).reduce((a, b) => a + b) /
            totalStaff;
    final totalOrders = _staffList.isEmpty
        ? 0
        : _staffList.map((s) => s.totalOrdersServed).reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppConstants.darkSecondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Staff', totalStaff.toString(),
              AppConstants.primaryOrange),
          _buildStatItem('Avg. Score', avgPerformance.toStringAsFixed(1),
              AppConstants.successGreen),
          _buildStatItem(
              'Orders Served', totalOrders.toString(), Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppConstants.headingMedium.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppConstants.bodySmall,
        ),
      ],
    );
  }

  /// Staff list
  Widget _buildStaffList() {
    final filteredStaff = _filterRole == null
        ? _staffList
        : _staffList.where((s) => s.role == _filterRole).toList();

    if (filteredStaff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'No staff members found',
              style: AppConstants.headingSmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      itemCount: filteredStaff.length,
      itemBuilder: (context, index) {
        return StaffCard(
          staff: filteredStaff[index],
          onTap: () => _showStaffDetails(filteredStaff[index]),
        );
      },
    );
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardBackground,
        title: const Text('Filter by Role', style: AppConstants.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<StaffRole?>(
              title: const Text('All Staff', style: AppConstants.bodyMedium),
              value: null,
              groupValue: _filterRole,
              activeColor: AppConstants.primaryOrange,
              onChanged: (value) {
                setState(() {
                  _filterRole = value;
                });
                Navigator.pop(context);
              },
            ),
            ...StaffRole.values.map((role) {
              return RadioListTile<StaffRole?>(
                title: Text(
                  role.toString().split('.').last.toUpperCase(),
                  style: AppConstants.bodyMedium,
                ),
                value: role,
                groupValue: _filterRole,
                activeColor: AppConstants.primaryOrange,
                onChanged: (value) {
                  setState(() {
                    _filterRole = value;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Show staff details
  void _showStaffDetails(Staff staff) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(
                        bottom: AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      color: AppConstants.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConstants.primaryOrange,
                    child: Text(
                      staff.name
                          .split(' ')
                          .map((w) => w.isNotEmpty ? w[0] : '')
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Center(
                  child: Text(
                    staff.name,
                    style: AppConstants.headingLarge,
                  ),
                ),
                Center(
                  child: Text(
                    staff.roleDisplayName,
                    style: AppConstants.bodyLarge.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                _buildDetailRow('Email', staff.email, Icons.email),
                _buildDetailRow(
                  'Performance Score',
                  '${staff.performanceScore.toStringAsFixed(1)}/10',
                  Icons.star,
                ),
                _buildDetailRow(
                  'Orders Served',
                  staff.totalOrdersServed.toString(),
                  Icons.receipt,
                ),
                _buildDetailRow(
                  'Hire Date',
                  staff.hireDate.toString().split(' ')[0],
                  Icons.calendar_today,
                ),
                const SizedBox(height: AppConstants.paddingLarge),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _editStaff(staff);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryOrange,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                  ),
                  child: const Text('Edit Staff'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppConstants.primaryOrange,
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppConstants.bodySmall,
                ),
                Text(
                  value,
                  style: AppConstants.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Add new staff
  void _addNewStaff() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new staff feature coming soon!'),
        backgroundColor: AppConstants.primaryOrange,
      ),
    );
  }

  /// Edit staff
  void _editStaff(Staff staff) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit ${staff.name}'),
        backgroundColor: AppConstants.primaryOrange,
      ),
    );
  }

  /// Generate mock staff for demonstration
  void _generateMockStaff() {
    _staffList.addAll([
      Staff(
        id: 'S1',
        name: 'John Manager',
        email: 'john@smartserve.com',
        role: StaffRole.manager,
        hireDate: DateTime(2022, 1, 15),
        performanceScore: 9.2,
        totalOrdersServed: 450,
      ),
      Staff(
        id: 'S2',
        name: 'Sarah Waiter',
        email: 'sarah@smartserve.com',
        role: StaffRole.waiter,
        hireDate: DateTime(2023, 3, 10),
        performanceScore: 8.5,
        totalOrdersServed: 320,
      ),
      Staff(
        id: 'S3',
        name: 'Mike Chef',
        email: 'mike@smartserve.com',
        role: StaffRole.chef,
        hireDate: DateTime(2021, 6, 1),
        performanceScore: 9.8,
        totalOrdersServed: 680,
      ),
      Staff(
        id: 'S4',
        name: 'Emily Cashier',
        email: 'emily@smartserve.com',
        role: StaffRole.cashier,
        hireDate: DateTime(2023, 8, 20),
        performanceScore: 8.0,
        totalOrdersServed: 210,
      ),
      Staff(
        id: 'S5',
        name: 'David Waiter',
        email: 'david@smartserve.com',
        role: StaffRole.waiter,
        hireDate: DateTime(2023, 2, 5),
        performanceScore: 7.8,
        totalOrdersServed: 285,
      ),
    ]);
  }
}
