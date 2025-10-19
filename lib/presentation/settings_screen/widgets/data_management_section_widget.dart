import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class DataManagementSectionWidget extends StatefulWidget {
  const DataManagementSectionWidget({super.key});

  @override
  State<DataManagementSectionWidget> createState() =>
      _DataManagementSectionWidgetState();
}

class _DataManagementSectionWidgetState
    extends State<DataManagementSectionWidget> {
  String _syncFrequency = 'Automatique';
  String _storageLimit = '500 MB';
  bool _isBackingUp = false;
  bool _isExporting = false;
  double _backupProgress = 0.0;
  double _exportProgress = 0.0;

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
              'Gestion des Données',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            _buildDataItem(
              context,
              'Fréquence de Synchronisation',
              _syncFrequency,
              CustomIconWidget(
                iconName: 'sync',
                color: colorScheme.primary,
                size: 24,
              ),
              () => _showSyncFrequencyDialog(context),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildDataItem(
              context,
              'Limite de Stockage Hors Ligne',
              _storageLimit,
              CustomIconWidget(
                iconName: 'storage',
                color: colorScheme.primary,
                size: 24,
              ),
              () => _showStorageLimitDialog(context),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildActionItem(
              context,
              'Sauvegarde des Données',
              'Créer une sauvegarde complète',
              CustomIconWidget(
                iconName: 'backup',
                color: colorScheme.primary,
                size: 24,
              ),
              _isBackingUp,
              _backupProgress,
              () => _performBackup(),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildActionItem(
              context,
              'Exporter les Données',
              'Exporter vers CSV/PDF',
              CustomIconWidget(
                iconName: 'file_download',
                color: colorScheme.primary,
                size: 24,
              ),
              _isExporting,
              _exportProgress,
              () => _performExport(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(
    BuildContext context,
    String title,
    String value,
    Widget icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
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
            CustomIconWidget(
              iconName: 'chevron_right',
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    Widget icon,
    bool isLoading,
    double progress,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
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
                  isLoading
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'En cours... ${(progress * 100).toInt()}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  colorScheme.outline.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary),
                            ),
                          ],
                        )
                      : Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ],
              ),
            ),
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  )
                : CustomIconWidget(
                    iconName: 'chevron_right',
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
          ],
        ),
      ),
    );
  }

  void _showSyncFrequencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fréquence de Synchronisation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption('Automatique', _syncFrequency == 'Automatique'),
            _buildDialogOption(
                'Toutes les heures', _syncFrequency == 'Toutes les heures'),
            _buildDialogOption('Quotidienne', _syncFrequency == 'Quotidienne'),
            _buildDialogOption('Manuelle', _syncFrequency == 'Manuelle'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showStorageLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limite de Stockage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption('100 MB', _storageLimit == '100 MB'),
            _buildDialogOption('250 MB', _storageLimit == '250 MB'),
            _buildDialogOption('500 MB', _storageLimit == '500 MB'),
            _buildDialogOption('1 GB', _storageLimit == '1 GB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOption(String option, bool isSelected) {
    return RadioListTile<String>(
      title: Text(option),
      value: option,
      groupValue: isSelected ? option : null,
      onChanged: (value) {
        if (value != null) {
          setState(() {
            if (option.contains('Automatique') ||
                option.contains('heures') ||
                option.contains('Quotidienne') ||
                option.contains('Manuelle')) {
              _syncFrequency = value;
            } else {
              _storageLimit = value;
            }
          });
          Navigator.pop(context);
        }
      },
    );
  }

  void _performBackup() async {
    setState(() {
      _isBackingUp = true;
      _backupProgress = 0.0;
    });

    // Simulate backup process
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _backupProgress = i / 100;
      });
    }

    setState(() {
      _isBackingUp = false;
      _backupProgress = 0.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sauvegarde terminée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _performExport() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    // Simulate export process
    for (int i = 0; i <= 100; i += 15) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _exportProgress = i / 100;
      });
    }

    setState(() {
      _isExporting = false;
      _exportProgress = 0.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export terminé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
