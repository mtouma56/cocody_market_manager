import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../services/payments_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../add_payment_form_screen/add_payment_form_screen.dart';

class PaymentsManagementScreen extends StatefulWidget {
  const PaymentsManagementScreen({super.key});

  @override
  State<PaymentsManagementScreen> createState() =>
      _PaymentsManagementScreenState();
}

class _PaymentsManagementScreenState extends State<PaymentsManagementScreen> {
  String _selectedStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  bool _isLoading = true;
  String? _error;

  final PaymentsService _paymentsService = PaymentsService();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final payments = await _paymentsService.getAllPayments();

      if (mounted) {
        setState(() {
          _payments = payments ?? [];
          _isLoading = false;
        });

        _filterPayments();
      }
    } catch (error) {
      print('❌ ERREUR _loadPayments: $error');
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
          _payments = [];
        });
      }
    }
  }

  void _filterPayments() {
    setState(() {
      _filteredPayments =
          _payments.where((payment) {
            // Status filter
            bool statusMatch =
                _selectedStatus == 'all' ||
                (payment['status']?.toString() ?? '') == _selectedStatus;

            // Search filter
            bool searchMatch =
                _searchQuery.isEmpty ||
                (payment['tenantName']?.toString() ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (payment['contractNumber']?.toString() ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (payment['propertyNumber']?.toString() ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());

            return statusMatch && searchMatch;
          }).toList();

      // Sort by urgency then by due date
      _filteredPayments.sort((a, b) {
        const urgencyOrder = {'high': 0, 'medium': 1, 'low': 2};
        int urgencyA = urgencyOrder[a['urgency']?.toString()] ?? 2;
        int urgencyB = urgencyOrder[b['urgency']?.toString()] ?? 2;

        if (urgencyA != urgencyB) {
          return urgencyA.compareTo(urgencyB);
        }

        try {
          DateTime dateA = DateTime.parse(a['dueDate']?.toString() ?? '');
          DateTime dateB = DateTime.parse(b['dueDate']?.toString() ?? '');
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
    _filterPayments();
    HapticFeedback.lightImpact();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterPayments();
  }

  void _toggleSearch() {
    setState(() {
      _isSearchActive = !_isSearchActive;
      if (!_isSearchActive) {
        _searchController.clear();
        _searchQuery = '';
        _filterPayments();
      }
    });
    HapticFeedback.lightImpact();
  }

  void _onPaymentTap(Map<String, dynamic> payment) {
    HapticFeedback.lightImpact();
    _showPaymentDetails(payment);
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Paiement ${payment['monthConcerned'] ?? 'N/A'}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Locataire: ${payment['tenantName'] ?? 'N/A'}'),
                Text('Activité: ${payment['tenantBusiness'] ?? 'N/A'}'),
                Text(
                  'Local: ${payment['propertyNumber'] ?? 'N/A'} (${payment['propertyFloor'] ?? 'N/A'})',
                ),
                Text(
                  'Montant: ${_formatAmount((payment['amount'] as num?)?.toDouble() ?? 0)} FCFA',
                ),
                Text(
                  'Échéance: ${_formatDate(payment['dueDate']?.toString() ?? '')}',
                ),
                if (payment['paymentDate'] != null)
                  Text(
                    'Payé le: ${_formatDate(payment['paymentDate']?.toString() ?? '')}',
                  ),
                if (payment['paymentMethod'] != null)
                  Text(
                    'Mode: ${_getPaymentMethodLabel(payment['paymentMethod']?.toString())}',
                  ),
                Text(
                  'Statut: ${_getStatusLabel(payment['status']?.toString())}',
                ),
                Text('Contrat: ${payment['contractNumber'] ?? 'N/A'}'),
                if (payment['notes']?.toString().isNotEmpty == true)
                  Text('Notes: ${payment['notes']}'),
                if (payment['tenantPhone']?.toString().isNotEmpty == true)
                  Text('Téléphone: ${payment['tenantPhone']}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              if (payment['status'] == 'pending' ||
                  payment['status'] == 'overdue')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _markAsPaid(payment);
                  },
                  child: const Text('Marquer payé'),
                ),
              if (payment['tenantPhone']?.toString().isNotEmpty == true)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _callTenant(payment['tenantPhone']?.toString() ?? '');
                  },
                  child: const Text('Appeler'),
                ),
            ],
          ),
    );
  }

  void _markAsPaid(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer le paiement'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Marquer comme payé le paiement de ${_formatAmount((payment['amount'] as num?)?.toDouble() ?? 0)} FCFA pour ${payment['tenantName'] ?? 'N/A'} ?',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Mode de paiement',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                    DropdownMenuItem(
                      value: 'transfer',
                      child: Text('Virement'),
                    ),
                    DropdownMenuItem(
                      value: 'mobile_money',
                      child: Text('Mobile Money'),
                    ),
                    DropdownMenuItem(value: 'check', child: Text('Chèque')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _updatePaymentStatus(
                        payment['id']?.toString() ?? '',
                        'paid',
                        value,
                      );
                      Navigator.pop(context);
                    }
                  },
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

  Future<void> _updatePaymentStatus(
    String paymentId,
    String status,
    String? paymentMethod,
  ) async {
    try {
      await _paymentsService.updatePaymentStatus(
        paymentId,
        status,
        paymentMethod: paymentMethod,
      );

      await _loadPayments(); // Reload data

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Statut mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _showNewPaymentDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPaymentFormScreen()),
    );
    if (result == true) {
      _loadPayments();
    }
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
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
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      default:
        return 'Inconnu';
    }
  }

  String _getPaymentMethodLabel(String? method) {
    switch (method) {
      case 'cash':
        return 'Espèces';
      case 'transfer':
        return 'Virement';
      case 'mobile_money':
        return 'Mobile Money';
      case 'check':
        return 'Chèque';
      default:
        return 'Non spécifié';
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    await _loadPayments();
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
          Text('Chargement des paiements...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 64),
          SizedBox(height: 2.h),
          Text(
            'Erreur de chargement',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.red),
          ),
          SizedBox(height: 1.h),
          Text(
            _error ?? 'Une erreur est survenue',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton(
            onPressed: _loadPayments,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    final metrics = _calculateMetrics();

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              'Total',
              '${metrics['totalCount']}',
              'Paiements',
              Colors.blue,
              Icons.payment,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildMetricCard(
              'En attente',
              '${metrics['pendingCount']}',
              '${_formatAmount(metrics['pendingAmount'])} FCFA',
              Colors.orange,
              Icons.schedule,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildMetricCard(
              'Payés',
              '${metrics['paidCount']}',
              '${_formatAmount(metrics['paidAmount'])} FCFA',
              Colors.green,
              Icons.check_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String count,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 1.h),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    final statuses = [
      {'code': 'all', 'label': 'Tous'},
      {'code': 'pending', 'label': 'En attente'},
      {'code': 'paid', 'label': 'Payés'},
      {'code': 'overdue', 'label': 'En retard'},
    ];

    return Container(
      padding: EdgeInsets.all(2.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              statuses.map((status) {
                final isSelected = _selectedStatus == status['code'];
                return Padding(
                  padding: EdgeInsets.only(right: 2.w),
                  child: FilterChip(
                    label: Text(status['label'] ?? ''),
                    selected: isSelected,
                    onSelected:
                        (_) => _onStatusFilterChanged(status['code'] ?? ''),
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

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final urgencyColor = _getUrgencyColor(payment['urgency']?.toString());
    final statusColor = _getStatusColor(payment['status']?.toString());

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      elevation: 2,
      child: InkWell(
        onTap: () => _onPaymentTap(payment),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with month and urgency
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paiement ${payment['monthConcerned'] ?? 'N/A'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: urgencyColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getUrgencyLabel(payment['urgency']?.toString()),
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
                      payment['tenantName']?.toString() ?? 'N/A',
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
                    'Local ${payment['propertyNumber'] ?? 'N/A'} • ${payment['tenantBusiness'] ?? 'N/A'}',
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
                    '${_formatAmount((payment['amount'] as num?)?.toDouble() ?? 0)} FCFA',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(payment['status']?.toString()),
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.w),

              // Dates
              Text(
                'Échéance: ${_formatDate(payment['dueDate']?.toString() ?? '')}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              if (payment['paymentDate'] != null)
                Text(
                  'Payé le: ${_formatDate(payment['paymentDate']?.toString() ?? '')}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.green[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateMetrics() {
    double totalAmount = 0;
    double paidAmount = 0;
    double pendingAmount = 0;
    double overdueAmount = 0;
    int totalCount = _payments.length;
    int paidCount = 0;
    int pendingCount = 0;
    int overdueCount = 0;

    for (var payment in _payments) {
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
      final status = payment['status']?.toString() ?? '';

      totalAmount += amount;

      switch (status) {
        case 'paid':
          paidAmount += amount;
          paidCount++;
          break;
        case 'pending':
          pendingAmount += amount;
          pendingCount++;
          break;
        case 'overdue':
          overdueAmount += amount;
          overdueCount++;
          break;
      }
    }

    return {
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'overdueAmount': overdueAmount,
      'totalCount': totalCount,
      'paidCount': paidCount,
      'pendingCount': pendingCount,
      'overdueCount': overdueCount,
    };
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
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar:
          _isSearchActive
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
                    hintText: 'Rechercher paiements...',
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
                title: 'Paiements',
                variant: CustomAppBarVariant.withActions,
                onSearchPressed: _toggleSearch,
              ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.payment, color: Colors.white, size: 40),
                  SizedBox(height: 1.h),
                  Text(
                    'Cocody Market Manager',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Gestion des paiements',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
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
              leading: const Icon(Icons.description),
              title: const Text('Baux'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/lease-management-screen');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.payment,
                color: Theme.of(context).primaryColor,
              ),
              title: const Text('Paiements'),
              selected: true,
              selectedTileColor: Theme.of(context).primaryColor.withAlpha(26),
              onTap: () => Navigator.pop(context),
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
      body:
          _isLoading
              ? _buildLoadingState()
              : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                onRefresh: _onRefresh,
                color: Theme.of(context).primaryColor,
                child: Column(
                  children: [
                    // Metrics cards
                    _buildMetricsCards(),

                    // Status filter chips
                    _buildStatusFilterChips(),

                    // Payments count
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_filteredPayments.length} paiement${_filteredPayments.length > 1 ? 's' : ''} trouvé${_filteredPayments.length > 1 ? 's' : ''}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
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
                                _filterPayments();
                              },
                              child: const Text('Effacer filtres'),
                            ),
                        ],
                      ),
                    ),

                    // Payments list
                    Expanded(
                      child:
                          _filteredPayments.isEmpty
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
                                      'Aucun paiement trouvé',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 1.h),
                                    Text(
                                      'Essayez de modifier vos filtres',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                padding: EdgeInsets.only(bottom: 2.w),
                                itemCount: _filteredPayments.length,
                                itemBuilder: (context, index) {
                                  final payment = _filteredPayments[index];
                                  return _buildPaymentCard(payment);
                                },
                              ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPaymentDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }
}
