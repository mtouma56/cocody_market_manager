import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class LeaseStatusFilterWidget extends StatefulWidget {
  final String selectedStatus;
  final Function(String) onStatusChanged;

  const LeaseStatusFilterWidget({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  State<LeaseStatusFilterWidget> createState() =>
      _LeaseStatusFilterWidgetState();
}

class _LeaseStatusFilterWidgetState extends State<LeaseStatusFilterWidget> {
  final List<Map<String, dynamic>> statusFilters = [
    {'status': 'Tous', 'count': 156, 'color': AppTheme.neutralMedium},
    {'status': 'Actif', 'count': 89, 'color': AppTheme.primaryGreen},
    {'status': 'Expire bientôt', 'count': 23, 'color': AppTheme.warningAccent},
    {'status': 'Expiré', 'count': 12, 'color': AppTheme.alertRed},
    {'status': 'Brouillon', 'count': 32, 'color': AppTheme.neutralMedium},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8.h,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: statusFilters.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = statusFilters[index];
          final isSelected = widget.selectedStatus == filter['status'];

          return GestureDetector(
            onTap: () => widget.onStatusChanged(filter['status']),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? filter['color'].withValues(alpha: 0.1)
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? filter['color']
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter['status'],
                    style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? filter['color']
                          : AppTheme.lightTheme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w, vertical: 0.2.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? filter['color']
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${filter['count']}',
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.surface
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
