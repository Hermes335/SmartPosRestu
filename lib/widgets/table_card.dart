import 'package:flutter/material.dart';
import '../models/table_model.dart';
import '../utils/constants.dart';

/// Widget to display a restaurant table card
class TableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback? onTap;

  const TableCard({
    super.key,
    required this.table,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: _getStatusColor(),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: AppConstants.dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getStatusIcon(),
              size: 40,
              color: AppConstants.textPrimary,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Table ${table.tableNumber}',
              style: AppConstants.headingSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _getStatusText(),
              style: AppConstants.bodySmall.copyWith(
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${table.capacity} seats',
              style: AppConstants.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (table.status) {
      case TableStatus.available:
        return AppConstants.cardBackground;
      case TableStatus.occupied:
        return AppConstants.primaryOrange.withOpacity(0.2);
      case TableStatus.reserved:
        return AppConstants.warningYellow.withOpacity(0.2);
      case TableStatus.cleaning:
        return AppConstants.darkSecondary;
    }
  }

  IconData _getStatusIcon() {
    switch (table.status) {
      case TableStatus.available:
        return Icons.check_circle_outline;
      case TableStatus.occupied:
        return Icons.people;
      case TableStatus.reserved:
        return Icons.event_seat;
      case TableStatus.cleaning:
        return Icons.cleaning_services;
    }
  }

  String _getStatusText() {
    switch (table.status) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.cleaning:
        return 'Cleaning';
    }
  }
}
