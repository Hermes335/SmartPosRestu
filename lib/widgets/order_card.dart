import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Widget to display an order card
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({
    Key? key,
    required this.order,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: AppConstants.dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: AppConstants.primaryOrange,
                      size: AppConstants.iconMedium,
                    ),
                    const SizedBox(width: AppConstants.paddingSmall),
                    Text(
                      'Order #${order.id}',
                      style: AppConstants.headingSmall,
                    ),
                  ],
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              children: [
                Icon(
                  Icons.table_restaurant,
                  size: 16,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Table ${order.tableNumber}',
                  style: AppConstants.bodyMedium,
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppConstants.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  Formatters.formatTime(order.timestamp),
                  style: AppConstants.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              '${order.items.length} items',
              style: AppConstants.bodySmall,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppConstants.bodyMedium,
                ),
                Text(
                  Formatters.formatCurrency(order.totalAmount),
                  style: AppConstants.headingSmall.copyWith(
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

  Widget _buildStatusChip() {
    Color color;
    switch (order.status) {
      case OrderStatus.pending:
        color = AppConstants.warningYellow;
        break;
      case OrderStatus.preparing:
        color = Colors.blue;
        break;
      case OrderStatus.ready:
        color = AppConstants.successGreen;
        break;
      case OrderStatus.served:
        color = Colors.purple;
        break;
      case OrderStatus.completed:
        color = AppConstants.successGreen;
        break;
      case OrderStatus.cancelled:
        color = AppConstants.errorRed;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Text(
        order.status.toString().split('.').last.toUpperCase(),
        style: AppConstants.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
