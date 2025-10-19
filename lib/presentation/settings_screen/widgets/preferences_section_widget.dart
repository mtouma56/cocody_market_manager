import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PreferencesSectionWidget extends StatefulWidget {
  const PreferencesSectionWidget({super.key});

  @override
  State<PreferencesSectionWidget> createState() =>
      _PreferencesSectionWidgetState();
}

class _PreferencesSectionWidgetState extends State<PreferencesSectionWidget> {
  String _selectedLanguage = 'Français';
  String _selectedCurrency = 'XOF (Franc CFA)';
  String _selectedDateFormat = 'DD/MM/YYYY';
  bool _notificationsEnabled = true;

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
              'Préférences de l\'Application',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            _buildPreferenceItem(
              context,
              'Langue',
              _selectedLanguage,
              CustomIconWidget(
                iconName: 'language',
                color: colorScheme.primary,
                size: 24,
              ),
              () => _showLanguageDialog(context),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildPreferenceItem(
              context,
              'Format de Devise',
              _selectedCurrency,
              CustomIconWidget(
                iconName: 'attach_money',
                color: colorScheme.primary,
                size: 24,
              ),
              () => _showCurrencyDialog(context),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildPreferenceItem(
              context,
              'Format de Date',
              _selectedDateFormat,
              CustomIconWidget(
                iconName: 'calendar_today',
                color: colorScheme.primary,
                size: 24,
              ),
              () => _showDateFormatDialog(context),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildSwitchItem(
              context,
              'Notifications',
              'Recevoir les notifications push',
              _notificationsEnabled,
              CustomIconWidget(
                iconName: 'notifications',
                color: colorScheme.primary,
                size: 24,
              ),
              (value) => setState(() => _notificationsEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(
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

  Widget _buildSwitchItem(
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

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner la Langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption('Français', _selectedLanguage == 'Français'),
            _buildDialogOption('English', _selectedLanguage == 'English'),
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

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Format de Devise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
                'XOF (Franc CFA)', _selectedCurrency == 'XOF (Franc CFA)'),
            _buildDialogOption('EUR (Euro)', _selectedCurrency == 'EUR (Euro)'),
            _buildDialogOption(
                'USD (Dollar)', _selectedCurrency == 'USD (Dollar)'),
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

  void _showDateFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Format de Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption(
                'DD/MM/YYYY', _selectedDateFormat == 'DD/MM/YYYY'),
            _buildDialogOption(
                'MM/DD/YYYY', _selectedDateFormat == 'MM/DD/YYYY'),
            _buildDialogOption(
                'YYYY-MM-DD', _selectedDateFormat == 'YYYY-MM-DD'),
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
            if (option.contains('Français') || option.contains('English')) {
              _selectedLanguage = value;
            } else if (option.contains('XOF') ||
                option.contains('EUR') ||
                option.contains('USD')) {
              _selectedCurrency = value;
            } else {
              _selectedDateFormat = value;
            }
          });
          Navigator.pop(context);
        }
      },
    );
  }
}
