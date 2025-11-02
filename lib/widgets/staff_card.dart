import 'package:flutter/material.dart';
import '../models/staff_model.dart';
import '../utils/constants.dart';

/// Widget to display a staff member card
class StaffCard extends StatelessWidget {
  final Staff staff;
  final VoidCallback? onTap;

  const StaffCard({
    Key? key,
    required this.staff,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
        decoration: BoxDecoration(
          color: AppConstants.cardBackground,
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          border: Border.all(
            color: AppConstants.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppConstants.primaryOrange,
              child: staff.photoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        staff.photoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildInitials();
                        },
                      ),
                    )
                  : _buildInitials(),
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: AppConstants.headingSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getRoleIcon(),
                        size: 16,
                        color: AppConstants.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        staff.roleDisplayName,
                        style: AppConstants.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppConstants.warningYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${staff.performanceScore.toStringAsFixed(1)} • ${staff.totalOrdersServed} orders',
                        style: AppConstants.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppConstants.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials() {
    final initials = staff.name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    return Text(
      initials,
      style: AppConstants.headingMedium.copyWith(
        color: Colors.white,
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (staff.role) {
      case StaffRole.manager:
        return Icons.admin_panel_settings;
      case StaffRole.waiter:
        return Icons.room_service;
      case StaffRole.chef:
        return Icons.restaurant;
      case StaffRole.cashier:
        return Icons.point_of_sale;
    }
  }
}
