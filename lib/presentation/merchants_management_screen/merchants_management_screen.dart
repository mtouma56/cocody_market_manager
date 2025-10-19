import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/merchants_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/add_merchant_bottom_sheet_widget.dart';
import './widgets/merchant_card_widget.dart';
import './widgets/merchant_filter_bottom_sheet_widget.dart';
import './widgets/merchant_search_bar_widget.dart';

class MerchantsManagementScreen extends StatefulWidget {
  const MerchantsManagementScreen({super.key});

  @override
  State<MerchantsManagementScreen> createState() =>
      _MerchantsManagementScreenState();
}

class _MerchantsManagementScreenState extends State<MerchantsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _allMerchants = [];
  List<Map<String, dynamic>> _filteredMerchants = [];
  Map<String, dynamic> _currentFilters = {
    'status': 'Tous',
    'propertyType': 'Tous',
    'floor': 'Tous',
    'hasEmail': false,
    'hasPhone': false,
  };

  bool _isLoading = true;
  String? _error;
  DateTime? _lastSyncTime;

  final MerchantsService _merchantsService = MerchantsService();

  @override
  void initState() {
    super.initState();
    _loadMerchants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Charge les commerçants depuis Supabase
  Future<void> _loadMerchants() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final merchants = await _merchantsService.getAllMerchants();

      setState(() {
        _allMerchants = merchants;
        _isLoading = false;
        _lastSyncTime = DateTime.now();
      });

      _filterMerchants();
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  void _filterMerchants() {
    setState(() {
      _filteredMerchants = _allMerchants.where((merchant) {
        // Text search filter
        final searchQuery = _searchController.text.toLowerCase();
        final matchesSearch = searchQuery.isEmpty ||
            (merchant['name'] as String).toLowerCase().contains(searchQuery) ||
            (merchant['businessType'] as String)
                .toLowerCase()
                .contains(searchQuery) ||
            (merchant['phone'] as String).toLowerCase().contains(searchQuery) ||
            (merchant['email'] as String? ?? '')
                .toLowerCase()
                .contains(searchQuery);

        if (!matchesSearch) return false;

        // Status filter
        if (_currentFilters['status'] != 'Tous') {
          String filterStatus = _currentFilters['status'] as String;
          String merchantStatus = merchant['status'] as String;

          if (filterStatus == 'Actif' && merchantStatus != 'active')
            return false;
          if (filterStatus == 'Expire bientôt' && merchantStatus != 'expiring')
            return false;
          if (filterStatus == 'En retard' && merchantStatus != 'overdue')
            return false;
        }

        // Property type filter
        if (_currentFilters['propertyType'] != 'Tous') {
          String filterType = _currentFilters['propertyType'] as String;
          String merchantType = merchant['type'] ?? 'shop';

          Map<String, String> typeMapping = {
            'Boutique 9m²': 'shop',
            'Boutique 4.5m²': 'shop',
            'Banque': 'bank',
            'Restaurant': 'restaurant',
            'Box': 'box',
            'Étal de marché': 'market_stall',
          };

          if (typeMapping[filterType] != merchantType) return false;
        }

        // Floor filter
        if (_currentFilters['floor'] != 'Tous') {
          if (_currentFilters['floor'] != merchant['floor']) return false;
        }

        // Email filter
        if (_currentFilters['hasEmail'] as bool) {
          if ((merchant['email'] as String? ?? '').isEmpty) return false;
        }

        // Phone filter
        if (_currentFilters['hasPhone'] as bool) {
          if ((merchant['phone'] as String? ?? '').isEmpty) return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _refreshMerchants() async {
    HapticFeedback.lightImpact();
    await _loadMerchants();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Données synchronisées avec succès'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MerchantFilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onFiltersApplied: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          _filterMerchants();
        },
      ),
    );
  }

  void _showAddMerchantBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMerchantBottomSheetWidget(
        onMerchantAdded: (merchantData) {
          _loadMerchants(); // Recharger depuis Supabase
        },
      ),
    );
  }

  void _showMerchantContextMenu(
      BuildContext context, Map<String, dynamic> merchant) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'content_copy',
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Dupliquer le contact'),
              onTap: () {
                Navigator.pop(context);
                _duplicateMerchant(merchant);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'file_download',
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Exporter les détails'),
              onTap: () {
                Navigator.pop(context);
                _exportMerchantDetails(merchant);
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'notifications',
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Définir des rappels'),
              onTap: () {
                Navigator.pop(context);
                _setReminders(merchant);
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _duplicateMerchant(Map<String, dynamic> merchant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Duplication de "${merchant['name']}" - Fonctionnalité à venir'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _exportMerchantDetails(Map<String, dynamic> merchant) {
    final details = '''
Nom: ${merchant['name']}
Type d'activité: ${merchant['businessType']}
Téléphone: ${merchant['phone']}
Email: ${merchant['email'].isEmpty ? 'Non renseigné' : merchant['email']}
Adresse: ${merchant['address'] ?? 'Non renseignée'}
Propriété: ${merchant['number'] ?? 'Non assignée'} (${merchant['floor'] ?? 'Étage non défini'})
Statut: ${merchant['status']}
Notes: ${merchant['notes'] ?? 'Aucune note'}
''';

    Clipboard.setData(ClipboardData(text: details));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Détails copiés dans le presse-papiers'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _setReminders(Map<String, dynamic> merchant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rappels configurés pour ${merchant['name']}'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible d\'ouvrir l\'application téléphone'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  Future<void> _sendMessage(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible d\'ouvrir l\'application messages'),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  void _viewMerchantProfile(Map<String, dynamic> merchant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Profil de ${merchant['name']} - Fonctionnalité à venir'),
        backgroundColor: AppTheme.infoAccent,
      ),
    );
  }

  void _viewLease(Map<String, dynamic> merchant) {
    Navigator.pushNamed(context, '/lease-management-screen');
  }

  void _viewPaymentHistory(Map<String, dynamic> merchant) {
    Navigator.pushNamed(context, '/payments-management-screen');
  }

  void _editMerchant(Map<String, dynamic> merchant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Modification de ${merchant['name']} - Fonctionnalité à venir'),
        backgroundColor: AppTheme.infoAccent,
      ),
    );
  }

  void _removeMerchant(Map<String, dynamic> merchant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le commerçant'),
        content:
            Text('Êtes-vous sûr de vouloir supprimer ${merchant['name']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _merchantsService.removeMerchant(merchant['id']);
                Navigator.pop(context);
                await _loadMerchants();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${merchant['name']} supprimé'),
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement des commerçants...'),
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
            onPressed: _loadMerchants,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Commerçants',
        variant: CustomAppBarVariant.withActions,
        actions: [
          IconButton(
            onPressed: _showAddMerchantBottomSheet,
            icon: CustomIconWidget(
              iconName: 'add',
              size: 24,
              color: colorScheme.onSurface,
            ),
            tooltip: 'Ajouter un commerçant',
          ),
          IconButton(
            onPressed: () {
              _searchController.clear();
              _filterMerchants();
            },
            icon: CustomIconWidget(
              iconName: 'search',
              size: 24,
              color: colorScheme.onSurface,
            ),
            tooltip: 'Rechercher',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cocody Market Manager',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Gestion des commerçants',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  if (_lastSyncTime != null)
                    Text(
                      'Dernière sync: ${_lastSyncTime!.day}/${_lastSyncTime!.month} ${_lastSyncTime!.hour}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'dashboard',
                size: 24,
                color: colorScheme.onSurface,
              ),
              title: const Text('Tableau de bord'),
              onTap: () => Navigator.pushNamed(context, '/dashboard-screen'),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'business',
                size: 24,
                color: colorScheme.onSurface,
              ),
              title: const Text('Propriétés'),
              onTap: () =>
                  Navigator.pushNamed(context, '/properties-management-screen'),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'store',
                size: 24,
                color: colorScheme.primary,
              ),
              title: const Text('Commerçants'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'description',
                size: 24,
                color: colorScheme.onSurface,
              ),
              title: const Text('Baux'),
              onTap: () =>
                  Navigator.pushNamed(context, '/lease-management-screen'),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'payment',
                size: 24,
                color: colorScheme.onSurface,
              ),
              title: const Text('Paiements'),
              onTap: () =>
                  Navigator.pushNamed(context, '/payments-management-screen'),
            ),
            const Divider(),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'settings',
                size: 24,
                color: colorScheme.onSurface,
              ),
              title: const Text('Paramètres'),
              onTap: () => Navigator.pushNamed(context, '/settings-screen'),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Search Bar
                    MerchantSearchBarWidget(
                      controller: _searchController,
                      hintText: 'Rechercher par nom, activité, téléphone...',
                      onChanged: (value) => _filterMerchants(),
                      onFilterPressed: _showFilterBottomSheet,
                    ),

                    // Active Filters Indicator
                    if (_currentFilters.values.any((value) =>
                        (value is String && value != 'Tous') ||
                        (value is bool && value == true)))
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        padding: EdgeInsets.symmetric(
                            horizontal: 3.w, vertical: 1.h),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'filter_list',
                              size: 16,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'Filtres actifs',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentFilters = {
                                    'status': 'Tous',
                                    'propertyType': 'Tous',
                                    'floor': 'Tous',
                                    'hasEmail': false,
                                    'hasPhone': false,
                                  };
                                });
                                _filterMerchants();
                              },
                              child: CustomIconWidget(
                                iconName: 'clear',
                                size: 16,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Results Count
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredMerchants.length} commerçant${_filteredMerchants.length > 1 ? 's' : ''} trouvé${_filteredMerchants.length > 1 ? 's' : ''}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Merchants List
                    Expanded(
                      child: _filteredMerchants.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomIconWidget(
                                    iconName: 'store_mall_directory',
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    'Aucun commerçant trouvé',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  SizedBox(height: 1.h),
                                  Text(
                                    'Essayez de modifier vos critères de recherche',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshMerchants,
                              color: colorScheme.primary,
                              child: ListView.builder(
                                padding: EdgeInsets.only(bottom: 10.h),
                                itemCount: _filteredMerchants.length,
                                itemBuilder: (context, index) {
                                  final merchant = _filteredMerchants[index];
                                  return GestureDetector(
                                    onLongPress: () => _showMerchantContextMenu(
                                        context, merchant),
                                    child: MerchantCardWidget(
                                      merchant: merchant,
                                      onTap: () =>
                                          _viewMerchantProfile(merchant),
                                      onCall: () => _makePhoneCall(
                                          merchant['phone'] as String),
                                      onMessage: () => _sendMessage(
                                          merchant['phone'] as String),
                                      onViewLease: () => _viewLease(merchant),
                                      onPaymentHistory: () =>
                                          _viewPaymentHistory(merchant),
                                      onEdit: () => _editMerchant(merchant),
                                      onRemove: () => _removeMerchant(merchant),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 2,
        variant: CustomBottomBarVariant.standard,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMerchantBottomSheet,
        tooltip: 'Nouveau Commerçant',
        child: CustomIconWidget(
          iconName: 'add',
          size: 24,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
