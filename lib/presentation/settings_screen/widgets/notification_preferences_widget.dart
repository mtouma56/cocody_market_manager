import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class NotificationPreferencesWidget extends StatefulWidget {
  const NotificationPreferencesWidget({super.key});

  @override
  State<NotificationPreferencesWidget> createState() =>
      _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState
    extends State<NotificationPreferencesWidget> {
  bool _paymentReminders = true;
  bool _leaseRenewals = true;
  bool _systemAlerts = false;
  bool _maintenanceNotifications = true;
  bool _newTenantAlerts = true;

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
              'Préférences de Notification',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            _buildNotificationItem(
              context,
              'Rappels de Paiement',
              'Notifications pour les paiements en retard',
              _paymentReminders,
              CustomIconWidget(
                iconName: 'payment',
                color: colorScheme.primary,
                size: 24,
              ),
              (value) => setState(() => _paymentReminders = value),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildNotificationItem(
              context,
              'Renouvellements de Bail',
              'Alertes pour les baux arrivant à échéance',
              _leaseRenewals,
              CustomIconWidget(
                iconName: 'event',
                color: colorScheme.primary,
                size: 24,
              ),
              (value) => setState(() => _leaseRenewals = value),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildNotificationItem(
              context,
              'Alertes Système',
              'Notifications de maintenance et mises à jour',
              _systemAlerts,
              CustomIconWidget(
                iconName: 'settings',
                color: colorScheme.primary,
                size: 24,
              ),
              (value) => setState(() => _systemAlerts = value),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildNotificationItem(
              context,
              'Notifications de Maintenance',
              'Alertes pour les travaux de maintenance',
              _maintenanceNotifications,
              CustomIconWidget(
                iconName: 'build',
                color: colorScheme.primary,
                size: 24,
              ),
              (value) => setState(() => _maintenanceNotifications = value),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildNotificationItem(
              context,
              'Nouveaux Commerçants',
              'Notifications pour les nouvelles inscriptions',
              _newTenantAlerts,
              CustomIconWidget(
                iconName: 'person_add',
                color: colorScheme.primary,
                size: 24,
              ),
              (value) => setState(() => _newTenantAlerts = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Widget icon,
    ValueChanged<bool> onChanged,
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
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
