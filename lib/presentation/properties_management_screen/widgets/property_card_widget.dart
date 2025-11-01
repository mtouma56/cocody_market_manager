import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class PropertyCardWidget extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;
  final VoidCallback? onEditStatus;
  final VoidCallback? onContactTenant;
  final VoidCallback? onMaintenance;

  const PropertyCardWidget({
    super.key,
    required this.property,
    this.onTap,
    this.onViewDetails,
    this.onEditStatus,
    this.onContactTenant,
    this.onMaintenance,
  });

  @override
  Widget build(BuildContext context) {
    final String status = property['status'] ?? 'available';
    final bool isOccupied = status == 'occupied';
    final bool isMaintenance = status == 'maintenance';

    Color statusColor = AppTheme.lightTheme.colorScheme.primary;
    if (isOccupied) {
      statusColor = AppTheme.lightTheme.colorScheme.secondary;
    } else if (isMaintenance) {
      statusColor = AppTheme.lightTheme.colorScheme.error;
    }

    return Slidable(
      key: ValueKey(property['id']),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onViewDetails?.call(),
            backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
            foregroundColor: AppTheme.lightTheme.colorScheme.onSecondary,
            icon: Icons.visibility,
            label: 'Voir',
          ),
          SlidableAction(
            onPressed: (context) => onEditStatus?.call(),
            backgroundColor: AppTheme.warning,
            foregroundColor: AppTheme.lightTheme.colorScheme.onTertiary,
            icon: Icons.edit,
            label: 'Modifier',
          ),
          if (isOccupied)
            SlidableAction(
              onPressed: (context) => onContactTenant?.call(),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
              icon: Icons.phone,
              label: 'Contact',
            ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => onMaintenance?.call(),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            foregroundColor: AppTheme.lightTheme.colorScheme.onError,
            icon: Icons.build,
            label: 'Maintenance',
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: () => _showContextMenu(context),
        child: Container(
          margin: EdgeInsets.all(1.5.w),
          decoration: BoxDecoration(
            color: AppTheme.lightTheme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                width: double.infinity,
                height: 0.8.h,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property number and type icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          property['number'] ?? 'N/A',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color:
                                    AppTheme.lightTheme.colorScheme.onSurface,
                              ),
                        ),
                        CustomIconWidget(
                          iconName: _getPropertyTypeIcon(property['type']),
                          color: statusColor,
                          size: 20,
                        ),
                      ],
                    ),

                    SizedBox(height: 1.h),

                    // Property type and size
                    Text(
                      _getPropertyTypeLabel(property['type']),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),

                    if (property['size'] != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        '${property['size']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme
                                  .lightTheme.colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],

                    SizedBox(height: 1.5.h),

                    // Status and tenant info
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 2.w, vertical: 0.5.h),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatusLabel(status),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),

                    if (isOccupied && property['tenant'] != null) ...[
                      SizedBox(height: 1.h),
                      Text(
                        property['tenant']['name'] ?? 'Locataire',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (property['tenant']['business'] != null)
                        Text(
                          property['tenant']['business'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 9.sp,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPropertyTypeIcon(String? type) {
    switch (type) {
      case '9m2_shop':
      case '4.5m2_shop':
        return 'store';
      case 'bank':
        return 'account_balance';
      case 'restaurant':
        return 'restaurant';
      case 'box':
        return 'inventory_2';
      case 'market_stall':
        return 'storefront';
      default:
        return 'business';
    }
  }

  String _getPropertyTypeLabel(String? type) {
    switch (type) {
      case '9m2_shop':
        return 'Boutique 9m²';
      case '4.5m2_shop':
        return 'Boutique 4.5m²';
      case 'bank':
        return 'Banque';
      case 'restaurant':
        return 'Restaurant';
      case 'box':
        return 'Box';
      case 'market_stall':
        return 'Étal Marché';
      default:
        return 'Local Commercial';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'occupied':
        return 'Occupé';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Inconnu';
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'visibility',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 24,
              ),
              title: const Text('Voir les détails'),
              onTap: () {
                Navigator.pop(context);
                onViewDetails?.call();
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'edit',
                color: AppTheme.warning,
                size: 24,
              ),
              title: const Text('Modifier le statut'),
              onTap: () {
                Navigator.pop(context);
                onEditStatus?.call();
              },
            ),
            if (property['status'] == 'occupied')
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'phone',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 24,
                ),
                title: const Text('Contacter le locataire'),
                onTap: () {
                  Navigator.pop(context);
                  onContactTenant?.call();
                },
              ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'build',
                color: AppTheme.lightTheme.colorScheme.error,
                size: 24,
              ),
              title: const Text('Maintenance'),
              onTap: () {
                Navigator.pop(context);
                onMaintenance?.call();
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}