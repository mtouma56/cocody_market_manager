import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentMetricsCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const PaymentMetricsCard({
    super.key,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.w,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CustomIconWidget(
                iconName: icon.codePoint.toString(),
                color: textColor,
                size: 4.w,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            amount,
            style: GoogleFonts.roboto(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            subtitle,
            style: GoogleFonts.roboto(
              fontSize: 8.sp,
              fontWeight: FontWeight.w400,
              color: textColor.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
