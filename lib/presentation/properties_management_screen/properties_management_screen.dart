import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/properties_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/add_property_bottom_sheet_widget.dart';
import './widgets/floor_selector_widget.dart';
import './widgets/property_card_widget.dart';
import './widgets/property_type_filter_widget.dart';

class PropertiesManagementScreen extends StatefulWidget {
  const PropertiesManagementScreen({super.key});

  @override
  State<PropertiesManagementScreen> createState() =>
      _PropertiesManagementScreenState();
}

class _PropertiesManagementScreenState
    extends State<PropertiesManagementScreen> {
  String _selectedFloor = 'rdc';
  List<String> _selectedTypes = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _filteredProperties = [];
  bool _isLoading = true;
  String? _error;

  // New filter and sort state
  List<StatusFilter> _statusFilters = [StatusFilter.all];
  SortOption _currentSort = SortOption.propertyNumber;
  bool _sortAscending = true;

  final PropertiesService _propertiesService = PropertiesService();

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Convert status filters to API format
      List<String>? apiStatusFilters;
      if (!_statusFilters.contains(StatusFilter.all)) {
        apiStatusFilters = _statusFilters
            .map((filter) => _convertStatusFilterToApi(filter))
            .toList();
      }

      // Convert sort option to API format
      String sortBy = _convertSortOptionToApi(_currentSort);

      final properties = await _propertiesService.getAllProperties(
        statusFilters: apiStatusFilters,
        sortBy: sortBy,
        ascending: _sortAscending,
      );

      setState(() {
        _properties = properties;
        _isLoading = false;
      });

      _filterProperties();
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  void _filterProperties() {
    setState(() {
      _filteredProperties = _properties.where((property) {
        // Floor filter
        bool floorMatch = property['floor'] == _selectedFloor;

        // Type filter
        bool typeMatch =
            _selectedTypes.isEmpty || _selectedTypes.contains(property['type']);

        // Search filter
        bool searchMatch = _searchQuery.isEmpty ||
            (property['number'] as String)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (property['tenant']?['name'] as String?)
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true ||
            (property['tenant']?['business'] as String?)
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ==
                true;

        return floorMatch && typeMatch && searchMatch;
      }).toList();
    });
  }

  void _onFloorSelected(String floor) {
    setState(() {
      _selectedFloor = floor;
    });
    _filterProperties();
    HapticFeedback.lightImpact();
  }

  void _onTypeToggled(String type) {
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
    _filterProperties();
    HapticFeedback.lightImpact();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProperties();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = '';
        _filterProperties();
      }
    });
    HapticFeedback.lightImpact();
  }

  // New filter and sort handlers
  void _onFiltersChanged(List<StatusFilter> filters) {
    setState(() {
      _statusFilters = filters;
    });
    _loadProperties();
    HapticFeedback.lightImpact();
  }

  void _onSortChanged(SortOption sortOption, bool ascending) {
    setState(() {
      _currentSort = sortOption;
      _sortAscending = ascending;
    });
    _loadProperties();
    HapticFeedback.lightImpact();
  }

  String _convertStatusFilterToApi(StatusFilter filter) {
    switch (filter) {
      case StatusFilter.available:
        return 'available';
      case StatusFilter.occupied:
        return 'occupied';
      case StatusFilter.maintenance:
        return 'maintenance';
      case StatusFilter.all:
      default:
        return 'all';
    }
  }

  String _convertSortOptionToApi(SortOption option) {
    switch (option) {
      case SortOption.propertyNumber:
        return 'numero';
      case SortOption.propertyType:
        return 'type';
      case SortOption.floor:
        return 'floor';
      case SortOption.status:
        return 'statut';
    }
  }

  Future<void> _onPropertyAdded(Map<String, dynamic> newProperty) async {
    // Recharge la liste depuis Supabase au lieu d'ajouter localement
    await _loadProperties();
    HapticFeedback.mediumImpact();
  }

  void _showAddPropertyBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPropertyBottomSheetWidget(
        onPropertyAdded: _onPropertyAdded,
      ),
    );
  }

  void _onPropertyTap(Map<String, dynamic> property) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(
      context,
      AppRoutes.propertyDetailsScreen,
      arguments: property['id'],
    );
  }

  void _onViewDetails(Map<String, dynamic> property) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails du Local ${property['number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Étage: ${_getFloorLabel(property['floor'])}'),
            Text('Type: ${_getPropertyTypeLabel(property['type'])}'),
            Text('Superficie: ${property['size']}'),
            Text('Statut: ${_getStatusLabel(property['status'])}'),
            if (property['tenant'] != null) ...[
              const SizedBox(height: 8),
              const Text('Locataire:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Nom: ${property['tenant']['name']}'),
              Text('Activité: ${property['tenant']['business']}'),
              Text('Téléphone: ${property['tenant']['phone']}'),
            ],
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

  void _onEditStatus(Map<String, dynamic> property) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le statut - ${property['number']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Disponible'),
              leading: Radio<String>(
                value: 'available',
                groupValue: property['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updatePropertyStatus(property, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('Occupé'),
              leading: Radio<String>(
                value: 'occupied',
                groupValue: property['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updatePropertyStatus(property, value!);
                },
              ),
            ),
            ListTile(
              title: const Text('Maintenance'),
              leading: Radio<String>(
                value: 'maintenance',
                groupValue: property['status'],
                onChanged: (value) {
                  Navigator.pop(context);
                  _updatePropertyStatus(property, value!);
                },
              ),
            ),
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

  Future<void> _updatePropertyStatus(
      Map<String, dynamic> property, String newStatus) async {
    try {
      await _propertiesService.updatePropertyStatus(property['id'], newStatus);

      setState(() {
        final index = _properties.indexWhere((p) => p['id'] == property['id']);
        if (index != -1) {
          _properties[index]['status'] = newStatus;
        }
      });

      _filterProperties();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut du local ${property['number']} mis à jour'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $error'),
          backgroundColor: AppTheme.lightTheme.colorScheme.error,
        ),
      );
    }
  }

  void _onContactTenant(Map<String, dynamic> property) {
    HapticFeedback.lightImpact();
    if (property['tenant'] != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Contacter le locataire'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nom: ${property['tenant']['name']}'),
              Text('Téléphone: ${property['tenant']['phone']}'),
              Text('Activité: ${property['tenant']['business']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonction d\'appel à venir')),
                );
              },
              child: const Text('Appeler'),
            ),
          ],
        ),
      );
    }
  }

  void _onMaintenance(Map<String, dynamic> property) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maintenance - ${property['number']}'),
        content: const Text('Marquer ce local en maintenance ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePropertyStatus(property, 'maintenance');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  String _getFloorLabel(String floor) {
    switch (floor) {
      case 'rdc':
        return 'RDC';
      case '1er':
        return '1er étage';
      case '2eme':
        return '2ème étage';
      case '3eme':
        return '3ème étage';
      default:
        return floor;
    }
  }

  String _getPropertyTypeLabel(String? type) {
    switch (type) {
      case '9m2_shop':
        return 'Boutique 9m²';
      case '4.5m2_shop':
        return 'Boutique 4.5m²';
      case 'bank':
        return 'Banque';
      case 'restaurant':
        return 'Restaurant';
      case 'box':
        return 'Box';
      case 'market_stall':
        return 'Étal Marché';
      default:
        return 'Local Commercial';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Disponible';
      case 'occupied':
        return 'Occupé';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Inconnu';
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadProperties();
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
          Text('Chargement des locaux...'),
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
            onPressed: _loadProperties,
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
                  hintText: 'Rechercher locaux, locataires...',
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
              title: 'Locaux',
              variant: CustomAppBarVariant.withActions,
              onSearchPressed: _toggleSearch,
              onFilterChanged: _onFiltersChanged,
              onSortChanged: _onSortChanged,
              currentFilters: _statusFilters,
              currentSortOption: _currentSort,
              currentSortAscending: _sortAscending,
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
                    'Gestion des locaux commerciaux',
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
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 24,
              ),
              title: const Text('Locaux'),
              selected: true,
              selectedTileColor: AppTheme.lightTheme.colorScheme.secondary
                  .withValues(alpha: 0.1),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'store',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
              title: const Text('Commerçants'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/merchants-management-screen');
              },
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
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  child: Column(
                    children: [
                      // Floor selector
                      FloorSelectorWidget(
                        selectedFloor: _selectedFloor,
                        onFloorSelected: _onFloorSelected,
                      ),

                      // Property type filters
                      PropertyTypeFilterWidget(
                        selectedTypes: _selectedTypes,
                        onTypeToggled: _onTypeToggled,
                      ),

                      // Properties count
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 1.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_filteredProperties.length} local${_filteredProperties.length > 1 ? 'aux' : ''} trouvé${_filteredProperties.length > 1 ? 's' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.lightTheme.colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            if (_selectedTypes.isNotEmpty ||
                                _searchQuery.isNotEmpty)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedTypes.clear();
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                  _filterProperties();
                                },
                                child: const Text('Effacer filtres'),
                              ),
                          ],
                        ),
                      ),

                      // Properties grid
                      Expanded(
                        child: _filteredProperties.isEmpty
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
                                      'Aucun local trouvé',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      'Essayez de modifier vos filtres',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.lightTheme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : GridView.builder(
                                padding: EdgeInsets.all(2.w),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      MediaQuery.of(context).size.width > 600
                                          ? 3
                                          : 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 2.w,
                                  mainAxisSpacing: 2.w,
                                ),
                                itemCount: _filteredProperties.length,
                                itemBuilder: (context, index) {
                                  final property = _filteredProperties[index];
                                  return PropertyCardWidget(
                                    property: property,
                                    onTap: () => _onPropertyTap(property),
                                    onViewDetails: () =>
                                        _onViewDetails(property),
                                    onEditStatus: () => _onEditStatus(property),
                                    onContactTenant: () =>
                                        _onContactTenant(property),
                                    onMaintenance: () =>
                                        _onMaintenance(property),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPropertyBottomSheet,
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: CustomIconWidget(
          iconName: 'add',
          color: AppTheme.lightTheme.colorScheme.onPrimary,
          size: 24,
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 1,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }
}
