import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PropertyTypeFilterWidget extends StatelessWidget {
  final List<String> selectedTypes;
  final Function(String) onTypeToggled;

  const PropertyTypeFilterWidget({
    super.key,
    required this.selectedTypes,
    required this.onTypeToggled,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> propertyTypes = [
      {'id': '9m2_shop', 'label': 'Boutique 9m²', 'count': 120},
      {'id': '4.5m2_shop', 'label': 'Boutique 4.5m²', 'count': 180},
      {'id': 'bank', 'label': 'Banque', 'count': 8},
      {'id': 'restaurant', 'label': 'Restaurant', 'count': 25},
      {'id': 'box', 'label': 'Box', 'count': 95},
      {'id': 'market_stall', 'label': 'Étal Marché', 'count': 72},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Wrap(
        spacing: 2.w,
        runSpacing: 1.h,
        children: propertyTypes.map((type) {
          final isSelected = selectedTypes.contains(type['id']);

          return GestureDetector(
            onTap: () => onTypeToggled(type['id']),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.secondary
                        .withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.secondary
                      : AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    type['label'],
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.secondary
                              : AppTheme.lightTheme.colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                  SizedBox(width: 1.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w, vertical: 0.2.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.secondary
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${type['count']}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.onSecondary
                                : AppTheme.lightTheme.colorScheme.surface,
                            fontWeight: FontWeight.w600,
                            fontSize: 9.sp,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
