import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentStatusFilter extends StatelessWidget {
  final List<Map<String, dynamic>> statusFilters;
  final String selectedStatus;
  final Function(String) onStatusChanged;

  const PaymentStatusFilter({
    super.key,
    required this.statusFilters,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        itemCount: statusFilters.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = statusFilters[index];
          final isSelected = selectedStatus == filter['status'];

          return GestureDetector(
            onTap: () => onStatusChanged(filter['status'] as String),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? (filter['color'] as Color)
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (filter['color'] as Color)
                      : AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filter['label'] as String,
                    style: GoogleFonts.roboto(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.surface
                          : AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 1.5.w, vertical: 0.3.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.surface
                              .withValues(alpha: 0.2)
                          : (filter['color'] as Color),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      filter['count'].toString(),
                      style: GoogleFonts.roboto(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.surface
                            : AppTheme.lightTheme.colorScheme.surface,
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
