import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class FloorSelectorWidget extends StatelessWidget {
  final String selectedFloor;
  final Function(String) onFloorSelected;

  const FloorSelectorWidget({
    super.key,
    required this.selectedFloor,
    required this.onFloorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> floors = [
      {'id': 'rdc', 'label': 'RDC'},
      {'id': '1er', 'label': '1er'},
      {'id': '2eme', 'label': '2ème'},
      {'id': '3eme', 'label': '3ème'},
    ];

    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: floors.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final floor = floors[index];
          final isSelected = selectedFloor == floor['id'];

          return GestureDetector(
            onTap: () => onFloorSelected(floor['id']!),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.lightTheme.colorScheme.primary
                      : AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  floor['label']!,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? AppTheme.lightTheme.colorScheme.onPrimary
                            : AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
