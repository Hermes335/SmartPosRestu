import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../utils/constants.dart';
import '../widgets/table_card.dart';

/// Table Management screen - View and manage restaurant tables
class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  final List<RestaurantTable> _tables = [];
  TableStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _generateMockTables();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      appBar: AppBar(
        backgroundColor: AppConstants.darkSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            final scaffoldState = context.findAncestorStateOfType<ScaffoldState>();
            if (scaffoldState != null) {
              scaffoldState.openDrawer();
            }
          },
        ),
        title: Row(
          children: [
            Icon(
              Icons.table_restaurant,
              color: AppConstants.primaryOrange,
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            const Text(
              'Tables',
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _generateMockTables();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          _buildStatsBar(),

          // Tables grid
          Expanded(
            child: _buildTablesGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTable,
        backgroundColor: AppConstants.primaryOrange,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Stats bar showing table status counts
  Widget _buildStatsBar() {
    final available =
        _tables.where((t) => t.status == TableStatus.available).length;
    final occupied =
        _tables.where((t) => t.status == TableStatus.occupied).length;
    final reserved =
        _tables.where((t) => t.status == TableStatus.reserved).length;
    final cleaning =
        _tables.where((t) => t.status == TableStatus.cleaning).length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      color: AppConstants.darkSecondary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Available', available, AppConstants.successGreen),
          _buildStatItem('Occupied', occupied, AppConstants.primaryOrange),
          _buildStatItem('Reserved', reserved, AppConstants.warningYellow),
          _buildStatItem('Cleaning', cleaning, AppConstants.textSecondary),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
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

  /// Tables grid
  Widget _buildTablesGrid() {
    final filteredTables = _filterStatus == null
        ? _tables
        : _tables.where((t) => t.status == _filterStatus).toList();

    if (filteredTables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant,
              size: 80,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'No tables found',
              style: AppConstants.headingSmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppConstants.paddingMedium,
        crossAxisSpacing: AppConstants.paddingMedium,
        childAspectRatio: 1.0,
      ),
      itemCount: filteredTables.length,
      itemBuilder: (context, index) {
        return TableCard(
          table: filteredTables[index],
          onTap: () => _showTableOptions(filteredTables[index]),
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
        title: const Text('Filter Tables', style: AppConstants.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<TableStatus?>(
              title: const Text('All Tables', style: AppConstants.bodyMedium),
              value: null,
              groupValue: _filterStatus,
              activeColor: AppConstants.primaryOrange,
              onChanged: (value) {
                setState(() {
                  _filterStatus = value;
                });
                Navigator.pop(context);
              },
            ),
            ...TableStatus.values.map((status) {
              return RadioListTile<TableStatus?>(
                title: Text(
                  status.toString().split('.').last.toUpperCase(),
                  style: AppConstants.bodyMedium,
                ),
                value: status,
                groupValue: _filterStatus,
                activeColor: AppConstants.primaryOrange,
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Show table options
  void _showTableOptions(RestaurantTable table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table ${table.tableNumber}',
              style: AppConstants.headingMedium,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Status: ${table.status.toString().split('.').last.toUpperCase()}',
              style: AppConstants.bodyLarge,
            ),
            Text(
              'Capacity: ${table.capacity} seats',
              style: AppConstants.bodyLarge,
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildOptionButton(
              'Assign Order',
              Icons.receipt_long,
              () {
                Navigator.pop(context);
                _assignOrder(table);
              },
            ),
            _buildOptionButton(
              'Mark as Reserved',
              Icons.event_seat,
              () {
                Navigator.pop(context);
                _updateTableStatus(table, TableStatus.reserved);
              },
            ),
            _buildOptionButton(
              'Mark as Cleaning',
              Icons.cleaning_services,
              () {
                Navigator.pop(context);
                _updateTableStatus(table, TableStatus.cleaning);
              },
            ),
            _buildOptionButton(
              'Clear Table',
              Icons.check_circle,
              () {
                Navigator.pop(context);
                _updateTableStatus(table, TableStatus.available);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
        decoration: BoxDecoration(
          color: AppConstants.darkSecondary,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryOrange),
            const SizedBox(width: AppConstants.paddingMedium),
            Text(label, style: AppConstants.bodyLarge),
          ],
        ),
      ),
    );
  }

  /// Add new table
  void _addNewTable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new table feature coming soon!'),
        backgroundColor: AppConstants.primaryOrange,
      ),
    );
  }

  /// Assign order to table
  void _assignOrder(RestaurantTable table) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Assign order to Table ${table.tableNumber}'),
        backgroundColor: AppConstants.primaryOrange,
      ),
    );
  }

  /// Update table status
  void _updateTableStatus(RestaurantTable table, TableStatus newStatus) {
    setState(() {
      final index = _tables.indexWhere((t) => t.id == table.id);
      if (index != -1) {
        _tables[index] = table.copyWith(status: newStatus);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Table ${table.tableNumber} updated to ${newStatus.toString().split('.').last}'),
        backgroundColor: AppConstants.successGreen,
      ),
    );
  }

  /// Generate mock tables for demonstration
  void _generateMockTables() {
    _tables.clear();
    _tables.addAll([
      RestaurantTable(
        id: 'T1',
        tableNumber: '1',
        capacity: 2,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'T2',
        tableNumber: '2',
        capacity: 4,
        status: TableStatus.occupied,
        currentOrderId: 'ORD001',
      ),
      RestaurantTable(
        id: 'T3',
        tableNumber: '3',
        capacity: 4,
        status: TableStatus.occupied,
        currentOrderId: 'ORD002',
      ),
      RestaurantTable(
        id: 'T4',
        tableNumber: '4',
        capacity: 2,
        status: TableStatus.available,
      ),
      RestaurantTable(
        id: 'T5',
        tableNumber: '5',
        capacity: 6,
        status: TableStatus.occupied,
        currentOrderId: 'ORD003',
      ),
      RestaurantTable(
        id: 'T6',
        tableNumber: '6',
        capacity: 4,
        status: TableStatus.reserved,
      ),
      RestaurantTable(
        id: 'T7',
        tableNumber: '7',
        capacity: 2,
        status: TableStatus.cleaning,
      ),
      RestaurantTable(
        id: 'T8',
        tableNumber: '8',
        capacity: 8,
        status: TableStatus.available,
      ),
    ]);
  }
}
