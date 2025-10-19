import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PaymentCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onTap;
  final VoidCallback onRecordPayment;
  final VoidCallback onSendReminder;
  final VoidCallback onViewHistory;
  final VoidCallback onGenerateReceipt;
  final VoidCallback onEditAmount;
  final VoidCallback onMarkDisputed;

  const PaymentCard({
    super.key,
    required this.payment,
    required this.onTap,
    required this.onRecordPayment,
    required this.onSendReminder,
    required this.onViewHistory,
    required this.onGenerateReceipt,
    required this.onEditAmount,
    required this.onMarkDisputed,
  });

  @override
  Widget build(BuildContext context) {
    final status = payment['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Slidable(
      key: ValueKey(payment['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onRecordPayment(),
            backgroundColor: AppTheme.primaryGreen,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.payment,
            label: 'Enregistrer',
            borderRadius: BorderRadius.circular(8),
          ),
          SlidableAction(
            onPressed: (_) => onSendReminder(),
            backgroundColor: AppTheme.warningAccent,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.notifications,
            label: 'Rappel',
            borderRadius: BorderRadius.circular(8),
          ),
          SlidableAction(
            onPressed: (_) => onViewHistory(),
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.history,
            label: 'Historique',
            borderRadius: BorderRadius.circular(8),
          ),
          SlidableAction(
            onPressed: (_) => onGenerateReceipt(),
            backgroundColor: AppTheme.infoAccent,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.receipt,
            label: 'Reçu',
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEditAmount(),
            backgroundColor: AppTheme.neutralMedium,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.edit,
            label: 'Modifier',
            borderRadius: BorderRadius.circular(8),
          ),
          SlidableAction(
            onPressed: (_) => onMarkDisputed(),
            backgroundColor: AppTheme.alertRed,
            foregroundColor: AppTheme.surfaceWhite,
            icon: Icons.report_problem,
            label: 'Litige',
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lightTheme.colorScheme.shadow
                    .withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
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
                          payment['merchantName'] as String,
                          style: GoogleFonts.roboto(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Local ${payment['propertyNumber']}',
                          style: GoogleFonts.roboto(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w400,
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                          ),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomIconWidget(
                          iconName: statusIcon,
                          color: statusColor,
                          size: 3.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          _getStatusLabel(status),
                          style: GoogleFonts.roboto(
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Montant',
                        style: GoogleFonts.roboto(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        payment['amount'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Échéance',
                        style: GoogleFonts.roboto(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w400,
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        payment['dueDate'] as String,
                        style: GoogleFonts.roboto(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                    ],
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
      case 'paid':
        return AppTheme.primaryGreen;
      case 'pending':
        return AppTheme.warningAccent;
      case 'overdue':
        return AppTheme.alertRed;
      case 'partial':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.neutralMedium;
    }
  }

  String _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return 'check_circle';
      case 'pending':
        return 'schedule';
      case 'overdue':
        return 'error';
      case 'partial':
        return 'pie_chart';
      default:
        return 'help';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      case 'partial':
        return 'Partiel';
      default:
        return 'Inconnu';
    }
  }
}
