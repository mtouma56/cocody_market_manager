import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SecuritySectionWidget extends StatefulWidget {
  const SecuritySectionWidget({super.key});

  @override
  State<SecuritySectionWidget> createState() => _SecuritySectionWidgetState();
}

class _SecuritySectionWidgetState extends State<SecuritySectionWidget> {
  bool _biometricEnabled = true;
  String _sessionTimeout = '30 minutes';

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
              'Paramètres de Sécurité',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            _buildSwitchItem(
              context,
              'Authentification Biométrique',
              'Utiliser l\'empreinte digitale ou Face ID',
              _biometricEnabled,
              CustomIconWidget(
                iconName: 'fingerprint',
                color: colorScheme.primary,
                size: 24,
              ),
              (value) => setState(() => _biometricEnabled = value),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildSecurityItem(
              context,
              'Délai d\'Expiration de Session',
              _sessionTimeout,
              CustomIconWidget(
                iconName: 'timer',
                color: colorScheme.primary,
                size: 24,
              ),
              () => _showSessionTimeoutDialog(context),
            ),
            Divider(
                height: 2.h, color: colorScheme.outline.withValues(alpha: 0.2)),
            _buildSecurityItem(
              context,
              'Changer le Mot de Passe',
              'Modifier votre mot de passe actuel',
              CustomIconWidget(
                iconName: 'lock',
                color: colorScheme.primary,
                size: 24,
              ),
              () => _showChangePasswordDialog(context),
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

  Widget _buildSecurityItem(
    BuildContext context,
    String title,
    String subtitle,
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
                    subtitle,
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

  void _showSessionTimeoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Délai d\'Expiration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogOption('15 minutes', _sessionTimeout == '15 minutes'),
            _buildDialogOption('30 minutes', _sessionTimeout == '30 minutes'),
            _buildDialogOption('1 heure', _sessionTimeout == '1 heure'),
            _buildDialogOption('2 heures', _sessionTimeout == '2 heures'),
            _buildDialogOption('Jamais', _sessionTimeout == 'Jamais'),
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

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Changer le Mot de Passe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    suffixIcon: IconButton(
                      icon: CustomIconWidget(
                        iconName: obscureCurrentPassword
                            ? 'visibility'
                            : 'visibility_off',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                          obscureCurrentPassword = !obscureCurrentPassword),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    suffixIcon: IconButton(
                      icon: CustomIconWidget(
                        iconName: obscureNewPassword
                            ? 'visibility'
                            : 'visibility_off',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => obscureNewPassword = !obscureNewPassword),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    suffixIcon: IconButton(
                      icon: CustomIconWidget(
                        iconName: obscureConfirmPassword
                            ? 'visibility'
                            : 'visibility_off',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                          obscureConfirmPassword = !obscureConfirmPassword),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text ==
                    confirmPasswordController.text) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mot de passe modifié avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Les mots de passe ne correspondent pas'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Modifier'),
            ),
          ],
        ),
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
            _sessionTimeout = value;
          });
          Navigator.pop(context);
        }
      },
    );
  }
}
