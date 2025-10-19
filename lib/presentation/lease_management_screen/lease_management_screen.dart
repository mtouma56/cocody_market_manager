import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../services/leases_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';

class LeaseManagementScreen extends StatefulWidget {
  const LeaseManagementScreen({super.key});

  @override
  State<LeaseManagementScreen> createState() => _LeaseManagementScreenState();
}

class _LeaseManagementScreenState extends State<LeaseManagementScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  List<Map<String, dynamic>> _leases = [];
  List<Map<String, dynamic>> _filteredLeases = [];
  bool _isLoading = true;
  String? _error;

  final LeasesService _leasesService = LeasesService();

  @override
  void initState() {
    super.initState();
    _loadLeases();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLeases() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final leases = await _leasesService.getAllLeases();

      if (mounted) {
        setState(() {
          _leases = leases ?? [];
          _isLoading = false;
        });

        _filterLeases();
      }
    } catch (error) {
      print('❌ ERREUR _loadLeases: $error');
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
          _leases = [];
        });
      }
    }
  }

  void _filterLeases() {
    setState(() {
      _filteredLeases = _leases.where((lease) {
        // Status filter
        bool statusMatch = _selectedStatus == 'all' ||
            (lease['status']?.toString() ?? '') == _selectedStatus;

        // Search filter
        bool searchMatch = _searchQuery.isEmpty ||
            (lease['tenantName']?.toString() ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
            (lease['contractNumber']?.toString() ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
            (lease['propertyNumber']?.toString() ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

        return statusMatch && searchMatch;
      }).toList();

      // Sort by urgency then by end date
      _filteredLeases.sort((a, b) {
        const urgencyOrder = {'high': 0, 'medium': 1, 'low': 2};
        int urgencyA = urgencyOrder[a['urgency']?.toString()] ?? 2;
        int urgencyB = urgencyOrder[b['urgency']?.toString()] ?? 2;

        if (urgencyA != urgencyB) {
          return urgencyA.compareTo(urgencyB);
        }

        try {
          DateTime dateA = DateTime.parse(a['endDate']?.toString() ?? '');
          DateTime dateB = DateTime.parse(b['endDate']?.toString() ?? '');
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });
    });
  }

  void _onStatusFilterChanged(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _filterLeases();
    HapticFeedback.lightImpact();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterLeases();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = '';
        _filterLeases();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onLeaseTap(Map<String, dynamic> lease) {
    HapticFeedback.lightImpact();
    _showLeaseDetails(lease);
  }

  void _showLeaseDetails(Map<String, dynamic> lease) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bail ${lease['contractNumber'] ?? 'N/A'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Locataire: ${lease['tenantName'] ?? 'N/A'}'),
            Text('Activité: ${lease['tenantBusiness'] ?? 'N/A'}'),
            Text(
                'Local: ${lease['propertyNumber'] ?? 'N/A'} (${lease['propertyFloor'] ?? 'N/A'})'),
            Text(
                'Type: ${_getPropertyTypeLabel(lease['propertyType']?.toString())}'),
            Text('Superficie: ${lease['propertySize'] ?? 'N/A'}'),
            Text(
                'Loyer: ${_formatAmount((lease['monthlyRent'] as num?)?.toDouble() ?? 0)} FCFA/mois'),
            Text('Début: ${_formatDate(lease['startDate']?.toString() ?? '')}'),
            Text('Fin: ${_formatDate(lease['endDate']?.toString() ?? '')}'),
            Text('Statut: ${_getStatusLabel(lease['status']?.toString())}'),
            Text(
                'Prochain paiement: ${_formatDate(lease['nextPaymentDate']?.toString() ?? '')}'),
            if (lease['tenantPhone']?.toString().isNotEmpty == true)
              Text('Téléphone: ${lease['tenantPhone']}'),
            if (lease['tenantEmail']?.toString().isNotEmpty == true)
              Text('Email: ${lease['tenantEmail']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          if (lease['tenantPhone']?.toString().isNotEmpty == true)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _callTenant(lease['tenantPhone']?.toString() ?? '');
              },
              child: const Text('Appeler'),
            ),
        ],
      ),
    );
  }

  void _callTenant(String phoneNumber) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Appel de $phoneNumber'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  String _formatDate(String dateStr) {
    try {
      if (dateStr.isEmpty) return 'N/A';
      DateTime date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'expiring':
        return 'Expire bientôt';
      case 'expired':
        return 'Expiré';
      default:
        return 'Inconnu';
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

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadLeases();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données mises à jour'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
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
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          SizedBox(height: 2.h),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                ),
          ),
          SizedBox(height: 1.h),
          Text(
            _error ?? 'Une erreur est survenue',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
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

  Widget _buildStatusFilterChips() {
    final statuses = [
      {'code': 'all', 'label': 'Tous'},
      {'code': 'active', 'label': 'Actifs'},
      {'code': 'expiring', 'label': 'Expirent bientôt'},
      {'code': 'expired', 'label': 'Expirés'},
    ];

    return Container(
      padding: EdgeInsets.all(2.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: statuses.map((status) {
            final isSelected = _selectedStatus == status['code'];
            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: FilterChip(
                label: Text(status['label'] ?? ''),
                selected: isSelected,
                onSelected: (_) => _onStatusFilterChanged(status['code'] ?? ''),
                backgroundColor: Colors.grey[200],
                selectedColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLeaseCard(Map<String, dynamic> lease) {
    final urgencyColor = _getUrgencyColor(lease['urgency']?.toString());
    final statusColor = _getStatusColor(lease['status']?.toString());

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      elevation: 2,
      child: InkWell(
        onTap: () => _onLeaseTap(lease),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with contract number and urgency
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bail ${lease['contractNumber'] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: urgencyColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getUrgencyLabel(lease['urgency']?.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.w),

              // Tenant info
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      lease['tenantName']?.toString() ?? 'N/A',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.w),

              // Property info
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Text(
                    'Local ${lease['propertyNumber'] ?? 'N/A'} • ${_getPropertyTypeLabel(lease['propertyType']?.toString())}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              SizedBox(height: 1.w),

              // Amount and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatAmount((lease['monthlyRent'] as num?)?.toDouble() ?? 0)} FCFA/mois',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(lease['status']?.toString()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.w),

              // Dates
              Text(
                'Fin: ${_formatDate(lease['endDate']?.toString() ?? '')} • Prochain paiement: ${_formatDate(lease['nextPaymentDate']?.toString() ?? '')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getUrgencyColor(String? urgency) {
    switch (urgency) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _getUrgencyLabel(String? urgency) {
    switch (urgency) {
      case 'high':
        return 'URGENT';
      case 'medium':
        return 'ATTENTION';
      default:
        return 'OK';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'expiring':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _isSearchActive
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 1,
              leading: IconButton(
                onPressed: _toggleSearch,
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              title: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Rechercher baux...',
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
                    icon: const Icon(Icons.clear, color: Colors.black87),
                  ),
              ],
            )
          : CustomAppBar(
              title: 'Baux',
              variant: CustomAppBarVariant.withActions,
              onSearchPressed: _toggleSearch,
            ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Cocody Market Manager',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Gestion des baux',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Tableau de bord'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/dashboard-screen');
              },
            ),
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Locaux'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/properties-management-screen');
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Commerçants'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/merchants-management-screen');
              },
            ),
            ListTile(
              leading: Icon(Icons.description,
                  color: Theme.of(context).primaryColor),
              title: const Text('Baux'),
              selected: true,
              selectedTileColor: Theme.of(context).primaryColor.withAlpha(26),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('Paiements'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/payments-management-screen');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
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
                  color: Theme.of(context).primaryColor,
                  child: Column(
                    children: [
                      // Status filter chips
                      _buildStatusFilterChips(),

                      // Lease count
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4.w, vertical: 1.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_filteredLeases.length} bail${_filteredLeases.length > 1 ? 'aux' : ''} trouvé${_filteredLeases.length > 1 ? 's' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
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
                                  _filterLeases();
                                },
                                child: const Text('Effacer filtres'),
                              ),
                          ],
                        ),
                      ),

                      // Leases list
                      Expanded(
                        child: _filteredLeases.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      color: Colors.grey[400],
                                      size: 64,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Aucun bail trouvé',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      'Essayez de modifier vos filtres',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey[500],
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.only(bottom: 2.w),
                                itemCount: _filteredLeases.length,
                                itemBuilder: (context, index) {
                                  final lease = _filteredLeases[index];
                                  return _buildLeaseCard(lease);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fonctionnalité en cours de développement'),
            ),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 3,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }
}
