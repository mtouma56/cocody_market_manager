import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_bottom_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Bienvenue sur Cocody Market Manager',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestion moderne du Marché Cocody Saint Jean',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            Text(
              'Navigation rapide',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),

            // Carte Commerçants
            _buildNavigationCard(
              title: 'Commerçants',
              subtitle: 'Gérer les marchands et leurs informations',
              icon: Icons.store,
              color: AppTheme.secondary,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.merchantsManagementScreen,
              ),
            ),
            const SizedBox(height: 16),

            // Carte Locaux
            _buildNavigationCard(
              title: 'Locaux',
              subtitle: 'Consulter les propriétés et leur occupation',
              icon: Icons.business,
              color: AppTheme.primary,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.propertiesManagementScreen,
              ),
            ),
            const SizedBox(height: 16),

            // Carte Baux
            _buildNavigationCard(
              title: 'Baux',
              subtitle: 'Gérer les contrats de location',
              icon: Icons.description,
              color: Colors.indigo,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.leaseManagementScreen,
              ),
            ),
            const SizedBox(height: 16),

            // Carte Paiements
            _buildNavigationCard(
              title: 'Paiements',
              subtitle: 'Suivre les encaissements et les retards',
              icon: Icons.payment,
              color: AppTheme.success,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.paymentsManagementScreen,
              ),
            ),
            const SizedBox(height: 32),

            // Section Actions rapides
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.analytics,
                    label: 'Statistiques',
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.statisticsScreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.assessment,
                    label: 'Rapports',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.reportsScreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.warning,
                    label: 'Retards',
                    color: AppTheme.error,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.overduePaymentsScreen,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.settings,
                    label: 'Paramètres',
                    color: Colors.grey,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.settingsScreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 0,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildNavigationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
