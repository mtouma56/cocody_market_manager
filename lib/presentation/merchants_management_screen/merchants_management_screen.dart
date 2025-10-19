import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

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
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  List<Map<String, dynamic>> _merchants = [];
  List<Map<String, dynamic>> _filteredMerchants = [];
  bool _isLoading = true;
  String? _error;

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

  Future<void> _loadMerchants() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final merchants = await _merchantsService.getAllMerchants();

      setState(() {
        _merchants = merchants;
        _isLoading = false;
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
      _filteredMerchants =
          _merchants.where((merchant) {
            // Status filter
            bool statusMatch =
                _selectedStatus == 'all' ||
                merchant['status'] == _selectedStatus;

            // Search filter
            bool searchMatch =
                _searchQuery.isEmpty ||
                (merchant['name'] as String).toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (merchant['businessType'] as String).toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (merchant['phone'] as String).toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            return statusMatch && searchMatch;
          }).toList();
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterMerchants();
    HapticFeedback.lightImpact();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterMerchants();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = '';
        _filterMerchants();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => MerchantFilterBottomSheetWidget(
            onFiltersApplied: (filters) {
              // Handle the filters map returned from the bottom sheet
              if (filters['status'] != null && filters['status'] != 'Tous') {
                String status = filters['status'];
                switch (status) {
                  case 'Actif':
                    _onStatusFilterChanged('active');
                    break;
                  case 'Expire bientôt':
                    _onStatusFilterChanged('expiring');
                    break;
                  case 'En retard':
                    _onStatusFilterChanged('overdue');
                    break;
                  default:
                    _onStatusFilterChanged('all');
                }
              } else {
                _onStatusFilterChanged('all');
              }
            },
          ),
    );
  }

  void _showAddMerchantBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AddMerchantBottomSheetWidget(
            onMerchantAdded: (merchant) {
              _loadMerchants(); // Refresh the list
            },
          ),
    );
  }

  void _onMerchantTap(Map<String, dynamic> merchant) {
    HapticFeedback.lightImpact();
    _showMerchantDetails(merchant);
  }

  void _showMerchantDetails(Map<String, dynamic> merchant) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(merchant['name']),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activité: ${merchant['businessType']}'),
                Text('Téléphone: ${merchant['phone']}'),
                if (merchant['email']?.isNotEmpty == true)
                  Text('Email: ${merchant['email']}'),
                Text('Statut: ${_getStatusLabel(merchant['status'])}'),
                if (merchant['number'] != null) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Local:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Numéro: ${merchant['number']}'),
                  Text('Type: ${merchant['type']}'),
                  Text('Étage: ${merchant['floor']}'),
                ],
                if (merchant['notes']?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Notes:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(merchant['notes']),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              if (merchant['phone']?.isNotEmpty == true)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _callMerchant(merchant['phone']);
                  },
                  child: const Text('Appeler'),
                ),
            ],
          ),
    );
  }

  void _callMerchant(String phoneNumber) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appel de $phoneNumber'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'inactive':
        return 'Inactif';
      case 'expiring':
        return 'Expire bientôt';
      case 'overdue':
        return 'En retard';
      default:
        return 'Inconnu';
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadMerchants();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Données mises à jour'),
        duration: Duration(seconds: 1),
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
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar:
          _isSearchActive
              ? AppBar(
                backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                elevation: 1,
                leading: IconButton(
                  onPressed: _toggleSearch,
                  icon: CustomIconWidget(
                    iconName: 'arrow_back',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
                title: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Rechercher commerçants...',
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearchChanged,
                ),
                actions: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                      icon: CustomIconWidget(
                        iconName: 'clear',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 24,
                      ),
                    ),
                ],
              )
              : CustomAppBar(
                title: 'Commerçants',
                variant: CustomAppBarVariant.withActions,
                onSearchPressed: _toggleSearch,
              ),
      drawer: Drawer(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomIconWidget(
                    iconName: 'business',
                    color: AppTheme.lightTheme.colorScheme.onPrimary,
                    size: 40,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Cocody Market Manager',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Gestion des commerçants',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onPrimary
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'dashboard',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Tableau de bord'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/dashboard-screen');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'business',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Locaux'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/properties-management-screen');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'store',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 24,
              ),
              title: const Text('Commerçants'),
              selected: true,
              selectedTileColor: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.1),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'description',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Baux'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/lease-management-screen');
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'payment',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Paiements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/payments-management-screen');
              },
            ),
            const Divider(),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'settings',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings-screen');
              },
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? _buildLoadingState()
              : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppTheme.lightTheme.colorScheme.primary,
                child: Column(
                  children: [
                    // Search bar
                    if (!_isSearchActive)
                      MerchantSearchBarWidget(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onFilterPressed: _showFilterBottomSheet,
                      ),

                    // Merchants count
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_filteredMerchants.length} commerçant${_filteredMerchants.length > 1 ? 's' : ''} trouvé${_filteredMerchants.length > 1 ? 's' : ''}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color:
                                  AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_selectedStatus != 'all' ||
                              _searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedStatus = 'all';
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                                _filterMerchants();
                              },
                              child: const Text('Effacer filtres'),
                            ),
                        ],
                      ),
                    ),

                    // Merchants list
                    Expanded(
                      child:
                          _filteredMerchants.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'search_off',
                                      color:
                                          AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onSurfaceVariant,
                                      size: 64,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Aucun commerçant trouvé',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                        color:
                                            AppTheme
                                                .lightTheme
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      'Essayez de modifier vos filtres',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                        color:
                                            AppTheme
                                                .lightTheme
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: EdgeInsets.all(2.w),
                                itemCount: _filteredMerchants.length,
                                itemBuilder: (context, index) {
                                  final merchant = _filteredMerchants[index];
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 2.w),
                                    child: MerchantCardWidget(
                                      merchant: merchant,
                                      onTap: () => _onMerchantTap(merchant),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMerchantBottomSheet,
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: CustomIconWidget(
          iconName: 'add',
          color: AppTheme.lightTheme.colorScheme.onPrimary,
          size: 24,
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 2,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }
}