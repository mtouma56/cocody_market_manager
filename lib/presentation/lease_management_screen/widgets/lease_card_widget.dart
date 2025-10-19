import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LeaseCardWidget extends StatelessWidget {
  final Map<String, dynamic> lease;
  final VoidCallback? onTap;
  final VoidCallback? onViewContract;
  final VoidCallback? onRenewLease;
  final VoidCallback? onPaymentSchedule;
  final VoidCallback? onGenerateReport;
  final VoidCallback? onEditTerms;
  final VoidCallback? onTerminate;
  final VoidCallback? onLongPress;

  const LeaseCardWidget({
    super.key,
    required this.lease,
    this.onTap,
    this.onViewContract,
    this.onRenewLease,
    this.onPaymentSchedule,
    this.onGenerateReport,
    this.onEditTerms,
    this.onTerminate,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final status = lease['status'] as String;
    final statusColor = _getStatusColor(status);
    final progressValue = _calculateProgress();

    return Slidable(
      key: ValueKey(lease['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onViewContract?.call(),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.visibility,
            label: 'Voir',
          ),
          SlidableAction(
            onPressed: (context) => onRenewLease?.call(),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.refresh,
            label: 'Renouveler',
          ),
          SlidableAction(
            onPressed: (context) => onPaymentSchedule?.call(),
            backgroundColor: AppTheme.warningAccent,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.schedule,
            label: 'Paiements',
          ),
          SlidableAction(
            onPressed: (context) => onGenerateReport?.call(),
            backgroundColor: AppTheme.infoAccent,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.description,
            label: 'Rapport',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onEditTerms?.call(),
            backgroundColor: AppTheme.neutralMedium,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          SlidableAction(
            onPressed: (context) => onTerminate?.call(),
            backgroundColor: AppTheme.alertRed,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.close,
            label: 'Résilier',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contrat ${lease['contractNumber']}',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          lease['merchantName'] as String,
                          style: AppTheme.lightTheme.textTheme.bodyMedium
                              ?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      status,
                      style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'business',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      '${lease['propertyType']} - ${lease['propertyLocation']}',
                      style: AppTheme.lightTheme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'calendar_today',
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${lease['startDate']} - ${lease['endDate']}',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${lease['monthlyRent']} XOF/mois',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progression du bail',
                        style: AppTheme.lightTheme.textTheme.labelMedium,
                      ),
                      Text(
                        '${(progressValue * 100).toInt()}%',
                        style:
                            AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: AppTheme.lightTheme.colorScheme.outline
                        .withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Actif':
        return AppTheme.primaryGreen;
      case 'Expire bientôt':
        return AppTheme.warningAccent;
      case 'Expiré':
        return AppTheme.alertRed;
      case 'Brouillon':
        return AppTheme.neutralMedium;
      default:
        return AppTheme.neutralMedium;
    }
  }

  double _calculateProgress() {
    final startDate = DateTime.parse(lease['startDateRaw'] as String);
    final endDate = DateTime.parse(lease['endDateRaw'] as String);
    final currentDate = DateTime.now();

    if (currentDate.isBefore(startDate)) return 0.0;
    if (currentDate.isAfter(endDate)) return 1.0;

    final totalDuration = endDate.difference(startDate).inDays;
    final elapsedDuration = currentDate.difference(startDate).inDays;

    return (elapsedDuration / totalDuration).clamp(0.0, 1.0);
  }
}
