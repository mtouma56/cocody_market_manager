import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NewLeaseFabWidget extends StatelessWidget {
  final VoidCallback? onPressed;
  final VoidCallback? onLeaseCreated;

  const NewLeaseFabWidget({
    super.key,
    this.onPressed,
    this.onLeaseCreated,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed ?? () => _showNewLeaseWizard(context),
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: AppTheme.surfaceWhite,
      elevation: 4.0,
      icon: CustomIconWidget(
        iconName: 'add',
        color: AppTheme.surfaceWhite,
        size: 24,
      ),
      label: Text(
        'Nouveau Bail',
        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
          color: AppTheme.surfaceWhite,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showNewLeaseWizard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nouveau Bail',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWizardStep(
                      context,
                      stepNumber: 1,
                      title: 'Sélectionner la propriété',
                      description: 'Choisissez la propriété à louer',
                      icon: 'business',
                      isCompleted: false,
                    ),
                    SizedBox(height: 2.h),
                    _buildWizardStep(
                      context,
                      stepNumber: 2,
                      title: 'Informations du commerçant',
                      description: 'Détails du locataire',
                      icon: 'person',
                      isCompleted: false,
                    ),
                    SizedBox(height: 2.h),
                    _buildWizardStep(
                      context,
                      stepNumber: 3,
                      title: 'Conditions du bail',
                      description: 'Durée, loyer et conditions',
                      icon: 'description',
                      isCompleted: false,
                    ),
                    SizedBox(height: 2.h),
                    _buildWizardStep(
                      context,
                      stepNumber: 4,
                      title: 'Signature et validation',
                      description: 'Finaliser le contrat',
                      icon: 'edit',
                      isCompleted: false,
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Call the onLeaseCreated callback if provided
                          onLeaseCreated?.call();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Assistant de création de bail ouvert'),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.surfaceWhite,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Commencer',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.surfaceWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStep(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
    required String icon,
    required bool isCompleted,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.primaryGreen
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: AppTheme.surfaceWhite,
                      size: 20,
                    )
                  : Text(
                      '$stepNumber',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: icon,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ],
      ),
    );
  }
}
