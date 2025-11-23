import 'dart:async';

import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../services/order_service.dart';
import '../services/table_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/table_card.dart';

/// Table Management screen - View and manage restaurant tables
class TableManagementScreen extends StatefulWidget {
  const TableManagementScreen({super.key});

  @override
  State<TableManagementScreen> createState() => _TableManagementScreenState();
}

class _TableManagementScreenState extends State<TableManagementScreen> {
  final TableService _tableService = TableService();
  final OrderService _orderService = OrderService();
  final List<RestaurantTable> _tables = [];
  final List<Order> _orders = [];
  StreamSubscription<List<RestaurantTable>>? _tablesSubscription;
  StreamSubscription<List<Order>>? _ordersSubscription;
  bool _isLoadingTables = true;
  String? _tablesError;
  TableStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _subscribeToTables();
    _subscribeToOrders();
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
              _subscribeToTables();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewTable,
        backgroundColor: AppConstants.primaryOrange,
        icon: const Icon(Icons.add),
        label: const Text('Add Table'),
      ),
    );
  }

  void _subscribeToTables() {
    _tablesSubscription?.cancel();
    setState(() {
      _isLoadingTables = true;
      _tablesError = null;
    });

    _tablesSubscription = _tableService.getTablesStream().listen(
      (tables) {
        if (!mounted) {
          return;
        }
        setState(() {
          _tables
            ..clear()
            ..addAll(_sortTablesByNumber(tables));
          _isLoadingTables = false;
        });
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoadingTables = false;
          _tablesError = error.toString();
        });
      },
    );
  }

  void _subscribeToOrders() {
    _ordersSubscription?.cancel();
    _ordersSubscription = _orderService.getOrdersStream().listen(
      (orders) {
        if (!mounted) {
          return;
        }
        setState(() {
          _orders
            ..clear()
            ..addAll(orders);
        });
      },
      onError: (_) {
        // Ignore order stream errors here; the Order screen surfaces them.
      },
    );
  }

  @override
  void dispose() {
    _tablesSubscription?.cancel();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  List<RestaurantTable> _sortTablesByNumber(List<RestaurantTable> input) {
    final sorted = List<RestaurantTable>.from(input);
    sorted.sort((a, b) {
      final aValue = int.tryParse(a.tableNumber);
      final bValue = int.tryParse(b.tableNumber);
      if (aValue != null && bValue != null) {
        return aValue.compareTo(bValue);
      }
      return a.tableNumber.compareTo(b.tableNumber);
    });
    return sorted;
  }

  /// Stats bar showing table status counts
  Widget _buildStatsBar() {
    if (_isLoadingTables) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        color: AppConstants.darkSecondary,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppConstants.primaryOrange),
            const SizedBox(width: AppConstants.paddingSmall),
            const Text('Loading tables...', style: AppConstants.bodyMedium),
          ],
        ),
      );
    }

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
    if (_isLoadingTables) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppConstants.primaryOrange),
            const SizedBox(height: AppConstants.paddingMedium),
            const Text('Fetching tables...', style: AppConstants.bodyMedium),
          ],
        ),
      );
    }

    if (_tablesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppConstants.errorRed,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Failed to load tables',
                style: AppConstants.headingSmall.copyWith(
                  color: AppConstants.errorRed,
                ),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                _tablesError!,
                style: AppConstants.bodySmall.copyWith(
                  color: AppConstants.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
              () async {
                Navigator.pop(context);
                await _assignOrder(table);
              },
            ),
            _buildOptionButton(
              'Mark as Reserved',
              Icons.event_seat,
              () async {
                Navigator.pop(context);
                await _updateTableStatus(table, TableStatus.reserved);
              },
            ),
            _buildOptionButton(
              'Mark as Cleaning',
              Icons.cleaning_services,
              () async {
                Navigator.pop(context);
                await _updateTableStatus(table, TableStatus.cleaning);
              },
            ),
            _buildOptionButton(
              'Clear Table',
              Icons.check_circle,
              () async {
                Navigator.pop(context);
                await _updateTableStatus(table, TableStatus.available);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    String label,
    IconData icon,
    Future<void> Function() onTap,
  ) {
    return InkWell(
      onTap: () async {
        await onTap();
      },
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
    final tableNumberController = TextEditingController();
    final capacityController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.cardBackground,
          title: Row(
            children: const [
              Icon(Icons.table_restaurant, color: AppConstants.primaryOrange),
              SizedBox(width: AppConstants.paddingSmall),
              Text('Add Table', style: AppConstants.headingSmall),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tableNumberController,
                  style: AppConstants.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Table Number',
                    hintText: 'e.g. 5 or VIP-1',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return 'Please enter a table number';
                    }
                    if (_tableNumberExists(trimmed)) {
                      return 'Table number already exists';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextFormField(
                  controller: capacityController,
                  style: AppConstants.bodyLarge,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    hintText: 'Number of seats',
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    final capacity = int.tryParse(trimmed);
                    if (capacity == null || capacity <= 0) {
                      return 'Enter a valid capacity';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                      });

                      final tableNumber = tableNumberController.text.trim();
                      final capacity =
                          int.parse(capacityController.text.trim());

                      final newTable = RestaurantTable(
                        id: '',
                        tableNumber: tableNumber,
                        capacity: capacity,
                        status: TableStatus.available,
                      );

                      try {
                        await _tableService.createTable(newTable);
                        if (!mounted) {
                          return;
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Table $tableNumber added successfully',
                            ),
                            backgroundColor: AppConstants.successGreen,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() {
                          isSubmitting = false;
                        });
                        if (!mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add table: $e'),
                            backgroundColor: AppConstants.errorRed,
                          ),
                        );
                      }
                    },
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Table'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Update table status
  Future<void> _updateTableStatus(
    RestaurantTable table,
    TableStatus newStatus,
  ) async {
    try {
      if (newStatus == TableStatus.available) {
        await _tableService.clearTable(table.id);
        await _detachOrderFromTable(table);
      } else {
        await _tableService.updateTableStatus(table.id, newStatus);
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table ${table.tableNumber} updated to ${newStatus.toString().split('.').last}',
          ),
          backgroundColor: AppConstants.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update table: $e'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  bool _tableNumberExists(String number) {
    return _tables.any(
      (table) => table.tableNumber.toLowerCase() == number.toLowerCase(),
    );
  }

  Future<void> _assignOrder(RestaurantTable table) async {
    if (table.status == TableStatus.occupied &&
        (table.currentOrderId?.isNotEmpty ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Table ${table.tableNumber} already has an active order. Clear it first to reassign.',
          ),
          backgroundColor: AppConstants.primaryOrange,
        ),
      );
      return;
    }

    final assignableOrders = _availableOrdersForAssignment();
    if (assignableOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No pending orders available for assignment'),
          backgroundColor: AppConstants.primaryOrange,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign Order to Table ${table.tableNumber}',
                style: AppConstants.headingMedium,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: assignableOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(
                    height: AppConstants.paddingSmall,
                  ),
                  itemBuilder: (context, index) {
                    final order = assignableOrders[index];
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(context);
                        await _linkOrderToTable(table, order);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        decoration: BoxDecoration(
                          color: AppConstants.darkSecondary,
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusMedium),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order ${order.id}',
                                    style: AppConstants.bodyLarge,
                                  ),
                                  const SizedBox(
                                      height: AppConstants.paddingSmall / 2),
                                  Text(
                                    '${Formatters.formatCurrency(order.totalAmount)} • ${Formatters.formatDateTime(order.timestamp)}',
                                    style: AppConstants.bodySmall.copyWith(
                                      color: AppConstants.textSecondary,
                                    ),
                                  ),
                                  if ((order.notes ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppConstants.paddingSmall / 2,
                                      ),
                                      child: Text(
                                        order.notes!,
                                        style: AppConstants.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppConstants.primaryOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: AppConstants.bodySmall.copyWith(
                                  color: AppConstants.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Order> _availableOrdersForAssignment() {
    final assignableStatuses = {
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.ready,
    };

    final orders = _orders.where((order) {
      final hasTable =
          order.tableNumber.trim().isNotEmpty && order.tableNumber != 'NO_TABLE';
      if (hasTable) {
        return false;
      }
      return assignableStatuses.contains(order.status);
    }).toList();

    orders.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return orders;
  }

  Future<void> _linkOrderToTable(
    RestaurantTable table,
    Order order,
  ) async {
    try {
      await _tableService.assignOrderToTable(table.id, order.id);
      await _orderService.updateOrder(
        order.copyWith(tableNumber: table.tableNumber),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order ${order.id} assigned to Table ${table.tableNumber}',
          ),
          backgroundColor: AppConstants.successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign order: $e'),
          backgroundColor: AppConstants.errorRed,
        ),
      );
    }
  }

  Future<void> _detachOrderFromTable(RestaurantTable table) async {
    final orderId = table.currentOrderId;
    if (orderId == null || orderId.isEmpty) {
      return;
    }

    final order = _findOrderById(orderId);
    if (order == null) {
      return;
    }

    if (order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled) {
      return;
    }

    try {
      await _orderService.updateOrder(
        order.copyWith(tableNumber: 'NO_TABLE'),
      );
    } catch (_) {
      // Failing to detach the table from the order isn't fatal; skip surfacing.
    }
  }

  Order? _findOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (_) {
      return null;
    }
  }
}
