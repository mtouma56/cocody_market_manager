import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/leases_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/lease_card_widget.dart';
import './widgets/lease_search_widget.dart';
import './widgets/lease_status_filter_widget.dart';
import './widgets/new_lease_fab_widget.dart';

class LeaseManagementScreen extends StatefulWidget {
  const LeaseManagementScreen({super.key});

  @override
  State<LeaseManagementScreen> createState() => _LeaseManagementScreenState();
}

class _LeaseManagementScreenState extends State<LeaseManagementScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  String _selectedStatus = 'Tous';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allLeases = [];
  List<Map<String, dynamic>> _filteredLeases = [];
  Map<String, int> _leasesStats = {};

  final LeasesService _leasesService = LeasesService();

  @override
  void initState() {
    super.initState();
    _loadLeases();
  }

  /// Charge les baux depuis Supabase
  Future<void> _loadLeases() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final leases = await _leasesService.getAllLeases();
      final stats = await _leasesService.getLeasesStats();

      setState(() {
        _allLeases = leases;
        _leasesStats = stats;
        _isLoading = false;
      });

      _applyFilters();
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allLeases);

    if (_selectedStatus != 'Tous') {
      filtered = filtered
          .where((lease) => lease['status'] == _selectedStatus)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((lease) {
        return (lease['merchantName'] as String)
                .toLowerCase()
                .contains(query) ||
            (lease['contractNumber'] as String).toLowerCase().contains(query) ||
            (lease['propertyLocation'] as String)
                .toLowerCase()
                .contains(query) ||
            (lease['businessType'] as String).toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _filteredLeases = filtered;
    });
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryGreen),
          SizedBox(height: 16),
          Text('Chargement des baux...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'error',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.error,
                ),
          ),
          SizedBox(height: 1.h),
          Text(
            _error ?? 'Une erreur est survenue',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: _loadLeases,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Baux',
        variant: CustomAppBarVariant.withActions,
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Filtrer les baux',
          ),
          IconButton(
            onPressed: () => _showNewLeaseWizard(context),
            icon: CustomIconWidget(
              iconName: 'add',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
            tooltip: 'Nouveau bail',
          ),
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 24,
            ),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Exporter les baux'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Statistiques'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    LeaseStatusFilterWidget(
                      selectedStatus: _selectedStatus,
                      onStatusChanged: _onStatusFilterChanged,
                    ),
                    LeaseSearchWidget(
                      searchQuery: _searchQuery,
                      onSearchChanged: _onSearchChanged,
                      onFilterPressed: _showAdvancedFilters,
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        key: _refreshIndicatorKey,
                        onRefresh: _refreshLeases,
                        color: AppTheme.primaryGreen,
                        child: _filteredLeases.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: EdgeInsets.only(
                                  top: 1.h,
                                  bottom: 10.h,
                                ),
                                itemCount: _filteredLeases.length,
                                itemBuilder: (context, index) {
                                  final lease = _filteredLeases[index];
                                  return LeaseCardWidget(
                                    lease: lease,
                                    onTap: () => _navigateToLeaseDetails(lease),
                                    onViewContract: () => _viewContract(lease),
                                    onRenewLease: () => _renewLease(lease),
                                    onPaymentSchedule: () =>
                                        _showPaymentSchedule(lease),
                                    onGenerateReport: () =>
                                        _generateReport(lease),
                                    onEditTerms: () => _editLeaseTerms(lease),
                                    onTerminate: () => _terminateLease(lease),
                                    onLongPress: () => _showContextMenu(lease),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: NewLeaseFabWidget(
        onPressed: () => _showNewLeaseWizard(context),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 3,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
      _applyFilters();
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  Future<void> _refreshLeases() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    await _loadLeases();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Baux mis à jour'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'description_outlined',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'Aucun bail trouvé',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isNotEmpty
                ? 'Aucun résultat pour "${_searchQuery}"'
                : 'Commencez par créer un nouveau bail',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton.icon(
            onPressed: () => _showNewLeaseWizard(context),
            icon: CustomIconWidget(
              iconName: 'add',
              color: AppTheme.surfaceWhite,
              size: 20,
            ),
            label: const Text('Nouveau Bail'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: AppTheme.surfaceWhite,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Options de filtrage',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                children: [
                  _buildFilterOption('Trier par date de fin', Icons.sort),
                  _buildFilterOption('Trier par montant', Icons.attach_money),
                  _buildFilterOption('Grouper par étage', Icons.layers),
                  _buildFilterOption('Afficher les alertes', Icons.warning),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.lightTheme.colorScheme.onSurface),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title appliqué'),
            backgroundColor: AppTheme.primaryBlue,
          ),
        );
      },
    );
  }

  void _showAdvancedFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtres avancés'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Baux expirant dans 30 jours'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Paiements en retard'),
              value: false,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Contrats à renouveler'),
              value: false,
              onChanged: (value) {},
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
                SnackBar(
                  content: const Text('Filtres appliqués'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportLeases();
        break;
      case 'statistics':
        _showStatistics();
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings-screen');
        break;
    }
  }

  void _exportLeases() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export de ${_filteredLeases.length} baux en cours...'),
        backgroundColor: AppTheme.primaryBlue,
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques des baux'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Total des baux: ${_leasesStats['total'] ?? _allLeases.length}'),
            Text('Baux actifs: ${_leasesStats['actif'] ?? 0}'),
            Text('Baux expirant: ${_leasesStats['expire_bientot'] ?? 0}'),
            Text('Baux expirés: ${_leasesStats['expire'] ?? 0}'),
            Text('Brouillons: ${_leasesStats['brouillon'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _navigateToLeaseDetails(Map<String, dynamic> lease) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Détails du bail ${lease['contractNumber']}'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _viewContract(Map<String, dynamic> lease) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture du contrat ${lease['contractNumber']}'),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _renewLease(Map<String, dynamic> lease) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renouveler le bail'),
        content: Text(
            'Voulez-vous renouveler le bail de ${lease['merchantName']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Processus de renouvellement initié'),
                  backgroundColor: AppTheme.primaryGreen,
                ),
              );
            },
            child: const Text('Renouveler'),
          ),
        ],
      ),
    );
  }

  void _showPaymentSchedule(Map<String, dynamic> lease) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Échéancier de ${lease['merchantName']}'),
        backgroundColor: AppTheme.warningAccent,
      ),
    );
  }

  void _generateReport(Map<String, dynamic> lease) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Génération du rapport pour ${lease['contractNumber']}'),
        backgroundColor: AppTheme.infoAccent,
      ),
    );
  }

  void _editLeaseTerms(Map<String, dynamic> lease) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Modification des termes du bail ${lease['contractNumber']}'),
        backgroundColor: AppTheme.neutralMedium,
      ),
    );
  }

  void _terminateLease(Map<String, dynamic> lease) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Résilier le bail'),
        content: Text(
            'Êtes-vous sûr de vouloir résilier le bail de ${lease['merchantName']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _leasesService.terminateLease(lease['id']);
                Navigator.pop(context);
                await _loadLeases();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Bail résilié'),
                    backgroundColor: AppTheme.alertRed,
                  ),
                );
              } catch (error) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $error'),
                    backgroundColor: AppTheme.alertRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertRed,
            ),
            child: const Text('Résilier'),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(Map<String, dynamic> lease) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Dupliquer le bail'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Bail dupliqué'),
                    backgroundColor: AppTheme.primaryBlue,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exporter en PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Export PDF en cours...'),
                    backgroundColor: AppTheme.infoAccent,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Définir rappels'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Rappels configurés'),
                    backgroundColor: AppTheme.warningAccent,
                  ),
                );
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _showNewLeaseWizard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Assistant Nouveau Bail',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Créez un nouveau bail en 4 étapes simples',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    _buildWizardStep(
                      context,
                      stepNumber: 1,
                      title: 'Sélectionner la propriété',
                      description: 'Choisissez parmi les locaux disponibles',
                      icon: 'business',
                      isCompleted: false,
                    ),
                    SizedBox(height: 2.h),
                    _buildWizardStep(
                      context,
                      stepNumber: 2,
                      title: 'Informations du commerçant',
                      description: 'Détails du locataire et de son activité',
                      icon: 'person',
                      isCompleted: false,
                    ),
                    SizedBox(height: 2.h),
                    _buildWizardStep(
                      context,
                      stepNumber: 3,
                      title: 'Conditions du bail',
                      description: 'Durée, loyer mensuel et clauses spéciales',
                      icon: 'description',
                      isCompleted: false,
                    ),
                    SizedBox(height: 2.h),
                    _buildWizardStep(
                      context,
                      stepNumber: 4,
                      title: 'Signature électronique',
                      description: 'Finalisation et signature du contrat',
                      icon: 'edit',
                      isCompleted: false,
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Assistant de création de bail lancé'),
                              backgroundColor: AppTheme.primaryGreen,
                              action: SnackBarAction(
                                label: 'Continuer',
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: AppTheme.surfaceWhite,
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Commencer la création',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
                            color: AppTheme.surfaceWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizardStep(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String description,
    required String icon,
    required bool isCompleted,
  }) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.primaryGreen
                  : AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? CustomIconWidget(
                      iconName: 'check',
                      color: AppTheme.surfaceWhite,
                      size: 20,
                    )
                  : Text(
                      '$stepNumber',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CustomIconWidget(
            iconName: icon,
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 8.w,
                  backgroundColor: AppTheme.surfaceWhite,
                  child: CustomIconWidget(
                    iconName: 'business',
                    color: AppTheme.primaryGreen,
                    size: 32,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Marché Cocody',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.surfaceWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Gestion des Baux',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.surfaceWhite.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: 'dashboard',
                  title: 'Tableau de bord',
                  route: '/dashboard-screen',
                ),
                _buildDrawerItem(
                  icon: 'business',
                  title: 'Propriétés',
                  route: '/properties-management-screen',
                ),
                _buildDrawerItem(
                  icon: 'store',
                  title: 'Commerçants',
                  route: '/merchants-management-screen',
                ),
                _buildDrawerItem(
                  icon: 'description',
                  title: 'Baux',
                  route: '/lease-management-screen',
                  isSelected: true,
                ),
                _buildDrawerItem(
                  icon: 'payment',
                  title: 'Paiements',
                  route: '/payments-management-screen',
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: 'settings',
                  title: 'Paramètres',
                  route: '/settings-screen',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required String icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: icon,
        color: isSelected
            ? AppTheme.primaryGreen
            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? AppTheme.primaryGreen
              : AppTheme.lightTheme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
        }
      },
    );
  }
}
