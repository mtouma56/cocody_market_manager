import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class BiometricAuthWidget extends StatelessWidget {
  final VoidCallback? onBiometricPressed;
  final bool isAvailable;

  const BiometricAuthWidget({
    super.key,
    this.onBiometricPressed,
    this.isAvailable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isAvailable) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(height: 3.h),

        // Divider with text
        Row(
          children: [
            Expanded(
              child: Divider(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                thickness: 0.5,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'ou',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  fontSize: 12.sp,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                thickness: 0.5,
              ),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Biometric Button
        OutlinedButton.icon(
          onPressed: onBiometricPressed != null
              ? () {
                  HapticFeedback.lightImpact();
                  onBiometricPressed!();
                }
              : null,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
            side: BorderSide(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withValues(alpha: 0.5),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.w),
            ),
          ),
          icon: CustomIconWidget(
            iconName: 'fingerprint',
            color: AppTheme.lightTheme.colorScheme.secondary,
            size: 5.w,
          ),
          label: Text(
            'Authentification biométrique',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    );
  }
}
