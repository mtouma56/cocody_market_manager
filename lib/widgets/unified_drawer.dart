import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class UnifiedDrawer extends StatelessWidget {
  final String currentRoute;

  const UnifiedDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.business, color: Colors.white, size: 48),
                SizedBox(height: 16),
                Text(
                  'Marché Cocody Saint Jean',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gestion locative complète',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Section principale
                _buildDrawerItem(
                  context,
                  'Dashboard',
                  Icons.dashboard,
                  AppRoutes.dashboardScreen,
                  isSelected: currentRoute == AppRoutes.dashboardScreen,
                ),

                // Section gestion des biens
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'GESTION DES BIENS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  'Locaux',
                  Icons.business,
                  AppRoutes.propertiesManagementScreen,
                  isSelected:
                      currentRoute == AppRoutes.propertiesManagementScreen,
                ),
                _buildDrawerItem(
                  context,
                  'Commerçants',
                  Icons.store,
                  AppRoutes.merchantsManagementScreen,
                  isSelected:
                      currentRoute == AppRoutes.merchantsManagementScreen,
                ),
                _buildDrawerItem(
                  context,
                  'Baux',
                  Icons.description,
                  AppRoutes.leaseManagementScreen,
                  isSelected: currentRoute == AppRoutes.leaseManagementScreen,
                ),

                // Section financière
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'GESTION FINANCIÈRE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  'Paiements',
                  Icons.payment,
                  AppRoutes.paymentsManagementScreen,
                  isSelected:
                      currentRoute == AppRoutes.paymentsManagementScreen,
                ),
                _buildDrawerItem(
                  context,
                  'Paiements en retard',
                  Icons.warning_amber,
                  AppRoutes.overduePaymentsScreen,
                  isSelected: currentRoute == AppRoutes.overduePaymentsScreen,
                ),
                _buildDrawerItem(
                  context,
                  'Baux expirant',
                  Icons.timer,
                  AppRoutes.expiringLeasesScreen,
                  isSelected: currentRoute == AppRoutes.expiringLeasesScreen,
                ),

                // Section rapports et données
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'RAPPORTS & DONNÉES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                _buildDrawerItem(
                  context,
                  'Rapports',
                  Icons.assessment,
                  AppRoutes.reportsScreen,
                  isSelected: currentRoute == AppRoutes.reportsScreen,
                ),
                _buildDrawerItem(
                  context,
                  'Statistiques',
                  Icons.analytics,
                  AppRoutes.statisticsScreen,
                  isSelected: currentRoute == AppRoutes.statisticsScreen,
                ),
                _buildDrawerItem(
                  context,
                  'Documents',
                  Icons.folder,
                  AppRoutes.documentsScreen,
                  isSelected: currentRoute == AppRoutes.documentsScreen,
                ),

                const Divider(thickness: 1, height: 32),

                // Section système
                _buildDrawerItem(
                  context,
                  'Paramètres',
                  Icons.settings,
                  AppRoutes.settingsScreen,
                  isSelected: currentRoute == AppRoutes.settingsScreen,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route, {
    bool isSelected = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF4CAF50).withAlpha(26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
        }
      },
    );
  }
}
