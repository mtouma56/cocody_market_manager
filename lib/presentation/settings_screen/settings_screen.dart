import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/data_management_section_widget.dart';
import './widgets/notification_preferences_widget.dart';
import './widgets/preferences_section_widget.dart';
import './widgets/profile_section_widget.dart';
import './widgets/security_section_widget.dart';
import './widgets/system_info_section_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorScheme.surface,
      drawer: _buildDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshSettings,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: 1.h),
                      ProfileSectionWidget(
                        onEditPressed: () => _showEditProfileDialog(context),
                      ),
                      const PreferencesSectionWidget(),
                      const DataManagementSectionWidget(),
                      const SecuritySectionWidget(),
                      const NotificationPreferencesWidget(),
                      const SystemInfoSectionWidget(),
                      SizedBox(height: 2.h),
                      _buildLogoutButton(context),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: CustomIconWidget(
              iconName: 'menu',
              color: colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Menu',
          ),
          SizedBox(width: 2.w),
          Text(
            'Paramètres',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          CustomIconWidget(
            iconName: 'settings',
            color: colorScheme.primary,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomImageWidget(
                    imageUrl:
                        "https://images.pexels.com/photos/2379004/pexels-photo-2379004.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                    width: 16.w,
                    height: 16.w,
                    fit: BoxFit.cover,
                    semanticLabel:
                        "Photo de profil d'un administrateur professionnel en costume sombre avec un sourire confiant",
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Jean-Baptiste Kouassi',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Administrateur',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 2.h),
                children: [
                  _buildDrawerItem(
                    context,
                    'Tableau de Bord',
                    'dashboard',
                    '/dashboard-screen',
                  ),
                  _buildDrawerItem(
                    context,
                    'Gestion des Locaux',
                    'business',
                    '/properties-management-screen',
                  ),
                  _buildDrawerItem(
                    context,
                    'Commerçants',
                    'store',
                    '/merchants-management-screen',
                  ),
                  _buildDrawerItem(
                    context,
                    'Gestion des Baux',
                    'description',
                    '/lease-management-screen',
                  ),
                  _buildDrawerItem(
                    context,
                    'Paiements',
                    'payment',
                    '/payments-management-screen',
                  ),
                  Divider(
                    height: 3.h,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                    indent: 4.w,
                    endIndent: 4.w,
                  ),
                  _buildDrawerItem(
                    context,
                    'Paramètres',
                    'settings',
                    '/settings-screen',
                    isSelected: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    String iconName,
    String route, {
    bool isSelected = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: isSelected
          ? BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: ListTile(
        leading: CustomIconWidget(
          iconName: iconName,
          color:
              isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 24,
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: isSelected
            ? null
            : () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  route,
                  (route) => false,
                );
              },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: CustomIconWidget(
          iconName: 'logout',
          color: colorScheme.onError,
          size: 20,
        ),
        label: Text(
          'Déconnexion',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onError,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'Jean-Baptiste Kouassi');
    final emailController =
        TextEditingController(text: 'admin@marche-cocody.ci');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil mis à jour avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ? Cette action nécessitera une vérification biométrique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBiometricLogout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _performBiometricLogout(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Vérification Biométrique'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: 'fingerprint',
              color: Theme.of(context).colorScheme.primary,
              size: 48,
            ),
            SizedBox(height: 2.h),
            const Text(
              'Veuillez confirmer votre identité avec votre empreinte digitale ou Face ID',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login-screen',
                (route) => false,
              );
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshSettings() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres mis à jour'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
