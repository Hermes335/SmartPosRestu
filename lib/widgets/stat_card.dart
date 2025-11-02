import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Reusable stat card widget for displaying key metrics
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Icon(
                  icon,
                  color: color ?? AppConstants.primaryOrange,
                  size: AppConstants.iconLarge,
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppConstants.textSecondary,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              value,
              style: AppConstants.headingLarge.copyWith(
                color: color ?? AppConstants.primaryOrange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppConstants.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
