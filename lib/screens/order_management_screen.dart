import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/order_card.dart';

/// Order Management screen - View and manage customer orders
class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  OrderStatus _selectedFilter = OrderStatus.pending;
  final List<Order> _mockOrders = [];

  @override
  void initState() {
    super.initState();
    _generateMockOrders();
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
              Icons.receipt_long,
              color: AppConstants.primaryOrange,
            ),
            const SizedBox(width: AppConstants.paddingSmall),
            const Text(
              'Orders',
              style: AppConstants.headingMedium,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
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
          // Status filter tabs
          _buildStatusTabs(),

          // Orders list
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewOrder,
        backgroundColor: AppConstants.primaryOrange,
        icon: const Icon(Icons.add),
        label: const Text('New Order'),
      ),
    );
  }

  /// Status filter tabs
  Widget _buildStatusTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      color: AppConstants.darkSecondary,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium),
        children: OrderStatus.values.map((status) {
          final isSelected = _selectedFilter == status;
          return Padding(
            padding: const EdgeInsets.only(right: AppConstants.paddingSmall),
            child: FilterChip(
              label: Text(
                status.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppConstants.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = status;
                });
              },
              backgroundColor: AppConstants.cardBackground,
              selectedColor: AppConstants.primaryOrange,
              checkmarkColor: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Orders list
  Widget _buildOrdersList() {
    final filteredOrders = _mockOrders
        .where((order) => order.status == _selectedFilter)
        .toList();

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: AppConstants.textSecondary,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'No ${_selectedFilter.toString().split('.').last} orders',
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
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return OrderCard(
          order: filteredOrders[index],
          onTap: () => _showOrderDetails(filteredOrders[index]),
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
        title: const Text('Filter Orders', style: AppConstants.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OrderStatus.values.map((status) {
            return RadioListTile<OrderStatus>(
              title: Text(
                status.toString().split('.').last.toUpperCase(),
                style: AppConstants.bodyMedium,
              ),
              value: status,
              groupValue: _selectedFilter,
              activeColor: AppConstants.primaryOrange,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Show order details
  void _showOrderDetails(Order order) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id}',
                  style: AppConstants.headingMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text('Table: ${order.tableNumber}', style: AppConstants.bodyLarge),
            Text(
              'Time: ${Formatters.formatDateTime(order.timestamp)}',
              style: AppConstants.bodyMedium,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            const Text('Items:', style: AppConstants.headingSmall),
            const SizedBox(height: AppConstants.paddingSmall),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppConstants.paddingSmall),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.quantity}x ${item.name}',
                          style: AppConstants.bodyMedium),
                      Text(Formatters.formatCurrency(item.totalPrice),
                          style: AppConstants.bodyMedium),
                    ],
                  ),
                )),
            const Divider(color: AppConstants.dividerColor),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: AppConstants.headingSmall),
                Text(
                  Formatters.formatCurrency(order.totalAmount),
                  style: AppConstants.headingMedium.copyWith(
                    color: AppConstants.primaryOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Create new order
  void _createNewOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create new order feature coming soon!'),
        backgroundColor: AppConstants.primaryOrange,
      ),
    );
  }

  /// Generate mock orders for demonstration
  void _generateMockOrders() {
    _mockOrders.addAll([
      Order(
        id: 'ORD001',
        tableNumber: '5',
        items: [
          OrderItem(
            id: 'ITEM1',
            name: 'Margherita Pizza',
            quantity: 2,
            price: 15.0,
          ),
          OrderItem(
            id: 'ITEM2',
            name: 'Caesar Salad',
            quantity: 1,
            price: 12.0,
          ),
        ],
        totalAmount: 42.0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: OrderStatus.pending,
      ),
      Order(
        id: 'ORD002',
        tableNumber: '3',
        items: [
          OrderItem(
            id: 'ITEM3',
            name: 'Pasta Carbonara',
            quantity: 1,
            price: 17.0,
          ),
        ],
        totalAmount: 17.0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: OrderStatus.preparing,
      ),
      Order(
        id: 'ORD003',
        tableNumber: '8',
        items: [
          OrderItem(
            id: 'ITEM4',
            name: 'Grilled Salmon',
            quantity: 2,
            price: 24.0,
          ),
          OrderItem(
            id: 'ITEM5',
            name: 'Tiramisu',
            quantity: 2,
            price: 9.0,
          ),
        ],
        totalAmount: 66.0,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: OrderStatus.ready,
      ),
    ]);
  }
}
