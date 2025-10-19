import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SystemInfoSectionWidget extends StatelessWidget {
  const SystemInfoSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations Système',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            _buildInfoItem(
              context,
              'Version de l\'Application',
              'v1.2.3 (Build 45)',
              CustomIconWidget(
                iconName: 'info',
                color: colorScheme.primary,
                size: 24,
              ),
              Colors.transparent,
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildInfoItem(
              context,
              'Dernière Synchronisation',
              '18/10/2025 19:25',
              CustomIconWidget(
                iconName: 'sync',
                color: colorScheme.primary,
                size: 24,
              ),
              Colors.green,
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildInfoItem(
              context,
              'Utilisation du Stockage',
              '245 MB / 500 MB utilisés',
              CustomIconWidget(
                iconName: 'storage',
                color: colorScheme.primary,
                size: 24,
              ),
              Colors.orange,
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildInfoItem(
              context,
              'État de la Connexion',
              'Connecté - Signal Fort',
              CustomIconWidget(
                iconName: 'wifi',
                color: colorScheme.primary,
                size: 24,
              ),
              Colors.green,
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildInfoItem(
              context,
              'Base de Données',
              '1,247 propriétés • 856 commerçants',
              CustomIconWidget(
                iconName: 'database',
                color: colorScheme.primary,
                size: 24,
              ),
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String title,
    String value,
    Widget icon,
    Color statusColor,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          icon,
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          statusColor != Colors.transparent
              ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
