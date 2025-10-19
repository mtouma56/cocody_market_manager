import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MerchantCardWidget extends StatelessWidget {
  final Map<String, dynamic> merchant;
  final VoidCallback? onTap;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;
  final VoidCallback? onViewLease;
  final VoidCallback? onPaymentHistory;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  const MerchantCardWidget({
    super.key,
    required this.merchant,
    this.onTap,
    this.onCall,
    this.onMessage,
    this.onViewLease,
    this.onPaymentHistory,
    this.onEdit,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(merchant['id']),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => onCall?.call(),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.surfaceWhite,
              icon: Icons.phone,
              label: 'Appeler',
              borderRadius: BorderRadius.circular(8),
            ),
            SlidableAction(
              onPressed: (context) => onMessage?.call(),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.surfaceWhite,
              icon: Icons.message,
              label: 'Message',
              borderRadius: BorderRadius.circular(8),
            ),
            SlidableAction(
              onPressed: (context) => onViewLease?.call(),
              backgroundColor: AppTheme.infoAccent,
              foregroundColor: AppTheme.surfaceWhite,
              icon: Icons.description,
              label: 'Bail',
              borderRadius: BorderRadius.circular(8),
            ),
            SlidableAction(
              onPressed: (context) => onPaymentHistory?.call(),
              backgroundColor: AppTheme.warningAccent,
              foregroundColor: AppTheme.surfaceWhite,
              icon: Icons.payment,
              label: 'Paiements',
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (context) => onEdit?.call(),
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: AppTheme.surfaceWhite,
              icon: Icons.edit,
              label: 'Modifier',
              borderRadius: BorderRadius.circular(8),
            ),
            SlidableAction(
              onPressed: (context) => onRemove?.call(),
              backgroundColor: AppTheme.alertRed,
              foregroundColor: AppTheme.surfaceWhite,
              icon: Icons.delete,
              label: 'Supprimer',
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  // Profile Photo
                  Container(
                    width: 15.w,
                    height: 15.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: merchant['profilePhoto'] != null
                          ? CustomImageWidget(
                              imageUrl: merchant['profilePhoto'] as String,
                              width: 15.w,
                              height: 15.w,
                              fit: BoxFit.cover,
                              semanticLabel:
                                  merchant['profilePhotoSemanticLabel']
                                          as String? ??
                                      "Photo de profil de ${merchant['name']}",
                            )
                          : Container(
                              color: colorScheme.primaryContainer,
                              child: Center(
                                child: Text(
                                  _getInitials(
                                      merchant['name'] as String? ?? ''),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 3.w),

                  // Merchant Information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                merchant['name'] as String? ??
                                    'Nom non disponible',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusIndicator(context,
                                merchant['status'] as String? ?? 'active'),
                          ],
                        ),
                        SizedBox(height: 0.5.h),

                        // Business Type
                        Text(
                          merchant['businessType'] as String? ??
                              'Type d\'activité non spécifié',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 1.h),

                        // Contact Information
                        Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'phone',
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                merchant['phone'] as String? ??
                                    'Téléphone non disponible',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),

                        // Email
                        if (merchant['email'] != null &&
                            (merchant['email'] as String).isNotEmpty)
                          Row(
                            children: [
                              CustomIconWidget(
                                iconName: 'email',
                                size: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  merchant['email'] as String,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Property Assignment
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildPropertyTypeIcon(context,
                          merchant['propertyType'] as String? ?? 'shop'),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.h),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          merchant['propertyNumber'] as String? ?? 'N/A',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Widget _buildStatusIndicator(BuildContext context, String status) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'active':
        statusColor = AppTheme.primaryGreen;
        statusText = 'Actif';
        break;
      case 'expiring':
        statusColor = AppTheme.warningAccent;
        statusText = 'Expire bientôt';
        break;
      case 'overdue':
        statusColor = AppTheme.alertRed;
        statusText = 'En retard';
        break;
      default:
        statusColor = AppTheme.neutralMedium;
        statusText = 'Inconnu';
    }

    return Container(
      width: 2.w,
      height: 2.w,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPropertyTypeIcon(BuildContext context, String propertyType) {
    IconData iconData;
    Color iconColor = Theme.of(context).colorScheme.primary;

    switch (propertyType.toLowerCase()) {
      case 'shop':
      case 'boutique':
        iconData = Icons.store;
        break;
      case 'bank':
      case 'banque':
        iconData = Icons.account_balance;
        break;
      case 'restaurant':
        iconData = Icons.restaurant;
        break;
      case 'box':
        iconData = Icons.inventory;
        break;
      case 'market_stall':
      case 'étal':
        iconData = Icons.shopping_basket;
        break;
      default:
        iconData = Icons.business;
    }

    return Container(
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CustomIconWidget(
        iconName: iconData.codePoint.toString(),
        size: 20,
        color: iconColor,
      ),
    );
  }
}
