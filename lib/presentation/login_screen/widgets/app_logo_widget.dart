import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AppLogoWidget extends StatelessWidget {
  const AppLogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container
        Container(
          width: 25.w,
          height: 25.w,
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.primary,
            borderRadius: BorderRadius.circular(4.w),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow
                    .withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'store',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 12.w,
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // App Name
        Text(
          'Cocody Market',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 24.sp,
          ),
        ),

        SizedBox(height: 0.5.h),

        // App Subtitle
        Text(
          'Manager',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
            fontSize: 16.sp,
            letterSpacing: 0.5,
          ),
        ),

        SizedBox(height: 1.h),

        // Market Description
        Text(
          'Marché Cocody Saint Jean',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w300,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}
