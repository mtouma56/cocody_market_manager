import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_export.dart';
import '../../services/merchants_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/unified_drawer.dart';
import '../lease_management_screen/lease_management_screen.dart';
import '../payments_management_screen/payments_management_screen.dart';
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

  // Add callback methods for swipe actions
  void _callMerchant(Map<String, dynamic> merchant) {
    final phoneNumber = merchant['phone'] as String?;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      HapticFeedback.lightImpact();
      _launchPhone(phoneNumber);
    } else {
      _showSnackBar('Numéro de téléphone non disponible');
    }
  }

  void _messageMerchant(Map<String, dynamic> merchant) {
    final phoneNumber = merchant['phone'] as String?;
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      HapticFeedback.lightImpact();
      _launchSMS(phoneNumber);
    } else {
      _showSnackBar('Numéro de téléphone non disponible');
    }
  }

  void _viewMerchantLease(Map<String, dynamic> merchant) {
    HapticFeedback.lightImpact();
    // Navigate vers Baux filtrés par ce commerçant
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeaseManagementScreen(
          initialCommercantId: merchant['id'],
          initialCommercantName: merchant['name'],
        ),
      ),
    );
  }

  void _viewMerchantPaymentHistory(Map<String, dynamic> merchant) {
    HapticFeedback.lightImpact();
    // Navigate vers Paiements filtrés par ce commerçant
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentsManagementScreen(
          initialCommercantId: merchant['id'],
          initialCommercantName: merchant['name'],
        ),
      ),
    );
  }

  void _editMerchant(Map<String, dynamic> merchant) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddMerchantBottomSheetWidget(
        onMerchantAdded: (updatedMerchant) {
          _loadMerchants(); // Refresh the list
        },
      ),
    );
  }

  void _removeMerchant(Map<String, dynamic> merchant) {
    HapticFeedback.mediumImpact();
    _showDeleteConfirmationDialog(merchant);
  }

  // Helper methods for launching external apps
  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackBar('Impossible d\'ouvrir l\'application téléphone');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'appel: $e');
    }
  }

  Future<void> _launchSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showSnackBar('Impossible d\'ouvrir l\'application SMS');
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'envoi SMS: $e');
    }
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> merchant) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer le commerçant "${merchant['name']}" ?\n\nCette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performDeleteMerchant(merchant);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.surface,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteMerchant(Map<String, dynamic> merchant) async {
    try {
      await _merchantsService.removeMerchant(merchant['id']);
      _showSnackBar('Commerçant supprimé avec succès');
      _loadMerchants(); // Refresh the list
    } catch (e) {
      _showSnackBar('Erreur lors de la suppression: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

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
      _filteredMerchants = _merchants.where((merchant) {
        // Status filter
        bool statusMatch =
            _selectedStatus == 'all' || merchant['status'] == _selectedStatus;

        // Search filter - with null safety
        bool searchMatch = _searchQuery.isEmpty ||
            (merchant['name'] as String? ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
            (merchant['businessType'] as String? ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (merchant['phone'] as String? ?? '').toLowerCase().contains(
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
      builder: (context) => MerchantFilterBottomSheetWidget(
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
      builder: (context) => AddMerchantBottomSheetWidget(
        onMerchantAdded: (merchant) {
          _loadMerchants(); // Refresh the list
        },
      ),
    );
  }

  void _onMerchantTap(Map<String, dynamic> merchant) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      '/merchant-details-screen',
      arguments: merchant['id'],
    );
  }

  void _showMerchantDetails(Map<String, dynamic> merchant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                _callMerchant(merchant);
              },
              child: const Text('Appeler'),
            ),
        ],
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
      appBar: _isSearchActive
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
      drawer: UnifiedDrawer(currentRoute: AppRoutes.merchantsManagementScreen),
      body: _isLoading
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
                                    color: AppTheme.lightTheme.colorScheme
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

                      // Merchants list - UPDATE this section
                      Expanded(
                        child: _filteredMerchants.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomIconWidget(
                                      iconName: 'search_off',
                                      color: AppTheme.lightTheme.colorScheme
                                          .onSurfaceVariant,
                                      size: 64,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Aucun commerçant trouvé',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      'Essayez de modifier vos filtres',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
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
                                      onCall: () => _callMerchant(merchant),
                                      onMessage: () =>
                                          _messageMerchant(merchant),
                                      onViewLease: () =>
                                          _viewMerchantLease(merchant),
                                      onPaymentHistory: () =>
                                          _viewMerchantPaymentHistory(
                                        merchant,
                                      ),
                                      onEdit: () => _editMerchant(merchant),
                                      onRemove: () => _removeMerchant(merchant),
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
