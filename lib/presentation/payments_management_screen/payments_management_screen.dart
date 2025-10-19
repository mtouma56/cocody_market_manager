import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/payments_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/new_payment_dialog.dart';
import './widgets/payment_card.dart';
import './widgets/payment_metrics_card.dart';
import './widgets/payment_search_bar.dart';
import './widgets/payment_status_filter.dart';

class PaymentsManagementScreen extends StatefulWidget {
  const PaymentsManagementScreen({super.key});

  @override
  State<PaymentsManagementScreen> createState() =>
      _PaymentsManagementScreenState();
}

class _PaymentsManagementScreenState extends State<PaymentsManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedStatus = 'all';
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  Map<String, dynamic> _metrics = {};

  final PaymentsService _paymentsService = PaymentsService();

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  /// Charge les paiements depuis Supabase
  Future<void> _loadPayments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final payments = await _paymentsService.getAllPayments();
      final metrics = await _paymentsService.getPaymentMetrics();

      setState(() {
        _payments = payments;
        _metrics = metrics;
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
    setState(() {
      _filteredPayments = _payments.where((payment) {
        // Status filter
        if (_selectedStatus != 'all' && payment['status'] != _selectedStatus) {
          return false;
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final merchantName =
              (payment['merchantName'] as String).toLowerCase();
          final propertyNumber =
              (payment['propertyNumber'] as String).toLowerCase();
          final amount = (payment['amount'] as String).toLowerCase();
          final query = _searchQuery.toLowerCase();

          return merchantName.contains(query) ||
              propertyNumber.contains(query) ||
              amount.contains(query);
        }

        return true;
      }).toList();
    });
  }

  List<Map<String, dynamic>> get _statusFilters {
    return [
      {
        'status': 'all',
        'label': 'Tous',
        'count': _payments.length,
        'color': AppTheme.neutralMedium,
      },
      {
        'status': 'paid',
        'label': 'Payés',
        'count': _payments.where((p) => p['status'] == 'paid').length,
        'color': AppTheme.primaryGreen,
      },
      {
        'status': 'pending',
        'label': 'En attente',
        'count': _payments.where((p) => p['status'] == 'pending').length,
        'color': AppTheme.warningAccent,
      },
      {
        'status': 'overdue',
        'label': 'En retard',
        'count': _payments.where((p) => p['status'] == 'overdue').length,
        'color': AppTheme.alertRed,
      },
    ];
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
            onPressed: _loadPayments,
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
      drawer: _buildDrawer(),
      appBar: CustomAppBar(
        title: 'Paiements',
        variant: CustomAppBarVariant.withActions,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'add',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
            onPressed: _showNewPaymentDialog,
            tooltip: 'Nouveau paiement',
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
            onPressed: _exportPayments,
            tooltip: 'Exporter',
          ),
          PopupMenuButton<String>(
            icon: CustomIconWidget(
              iconName: 'more_vert',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Paramètres'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Aide'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _refreshPayments,
                  child: Column(
                    children: [
                      _buildMetricsSection(),
                      SizedBox(height: 2.h),
                      PaymentStatusFilter(
                        statusFilters: _statusFilters,
                        selectedStatus: _selectedStatus,
                        onStatusChanged: (status) {
                          setState(() {
                            _selectedStatus = status;
                          });
                          _applyFilters();
                        },
                      ),
                      SizedBox(height: 1.h),
                      PaymentSearchBar(
                        searchQuery: _searchQuery,
                        onSearchChanged: (query) {
                          setState(() {
                            _searchQuery = query;
                          });
                          _applyFilters();
                        },
                        onFilterPressed: _showFilterDialog,
                      ),
                      Expanded(
                        child: _filteredPayments.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: EdgeInsets.only(bottom: 2.h),
                                itemCount: _filteredPayments.length,
                                itemBuilder: (context, index) {
                                  final payment = _filteredPayments[index];
                                  return PaymentCard(
                                    payment: payment,
                                    onTap: () => _showPaymentDetails(payment),
                                    onRecordPayment: () =>
                                        _recordPayment(payment),
                                    onSendReminder: () =>
                                        _sendReminder(payment),
                                    onViewHistory: () =>
                                        _viewPaymentHistory(payment),
                                    onGenerateReceipt: () =>
                                        _generateReceipt(payment),
                                    onEditAmount: () =>
                                        _editPaymentAmount(payment),
                                    onMarkDisputed: () =>
                                        _markAsDisputed(payment),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPaymentDialog,
        backgroundColor: AppTheme.primaryGreen,
        child: CustomIconWidget(
          iconName: 'add',
          color: AppTheme.surfaceWhite,
          size: 6.w,
        ),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4,
        variant: CustomBottomBarVariant.standard,
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
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomIconWidget(
                  iconName: 'store',
                  color: AppTheme.primaryGreen,
                  size: 12.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Cocody Market Manager',
                  style: GoogleFonts.roboto(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Gestion des paiements',
                  style: GoogleFonts.roboto(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem('Dashboard', 'dashboard', '/dashboard-screen'),
                _buildDrawerItem(
                    'Locaux', 'business', '/properties-management-screen'),
                _buildDrawerItem(
                    'Commerçants', 'store', '/merchants-management-screen'),
                _buildDrawerItem(
                    'Baux', 'description', '/lease-management-screen'),
                _buildDrawerItem(
                    'Paiements', 'payment', '/payments-management-screen',
                    isSelected: true),
                _buildDrawerItem('Paramètres', 'settings', '/settings-screen'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, String iconName, String route,
      {bool isSelected = false}) {
    return ListTile(
      leading: CustomIconWidget(
        iconName: iconName,
        color: isSelected
            ? AppTheme.primaryGreen
            : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
        size: 6.w,
      ),
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 14.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? AppTheme.primaryGreen
              : AppTheme.lightTheme.colorScheme.onSurface,
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

  Widget _buildMetricsSection() {
    if (_metrics.isEmpty) return const SizedBox.shrink();

    final totalCollected = _metrics['totalCollected'] ?? 0;
    final totalPending = _metrics['totalPending'] ?? 0;
    final totalOverdue = _metrics['totalOverdue'] ?? 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Expanded(
            child: PaymentMetricsCard(
              title: 'Collecté ce mois',
              amount: '${(totalCollected / 1000000).toStringAsFixed(1)}M FCFA',
              subtitle: '${_metrics['paidCount'] ?? 0} paiements',
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              textColor: AppTheme.primaryGreen,
              icon: Icons.trending_up,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: PaymentMetricsCard(
              title: 'En attente',
              amount: '${(totalPending / 1000000).toStringAsFixed(1)}M FCFA',
              subtitle: '${_metrics['pendingCount'] ?? 0} paiements',
              backgroundColor: AppTheme.warningAccent.withValues(alpha: 0.1),
              textColor: AppTheme.warningAccent,
              icon: Icons.schedule,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: PaymentMetricsCard(
              title: 'En retard',
              amount: '${(totalOverdue / 1000000).toStringAsFixed(1)}M FCFA',
              subtitle: '${_metrics['overdueCount'] ?? 0} paiements',
              backgroundColor: AppTheme.alertRed.withValues(alpha: 0.1),
              textColor: AppTheme.alertRed,
              icon: Icons.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'payment',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'Aucun paiement trouvé',
            style: GoogleFonts.roboto(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Essayez de modifier vos filtres de recherche',
            style: GoogleFonts.roboto(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshPayments() async {
    await _loadPayments();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paiements mis à jour',
            style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
          ),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showNewPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => NewPaymentDialog(
        onPaymentCreated: (payment) {
          _loadPayments(); // Recharger depuis Supabase
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nouveau paiement créé',
                style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
              ),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        },
      ),
    );
  }

  void _recordPayment(Map<String, dynamic> payment) async {
    try {
      await _paymentsService.recordPayment(payment['id']);
      await _loadPayments(); // Recharger les données

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Paiement enregistré pour ${payment['merchantName']}',
            style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Erreur: $error',
            style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
          ),
          backgroundColor: AppTheme.alertRed,
        ),
      );
    }
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détails du paiement',
                      style: GoogleFonts.roboto(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    _buildDetailRow('Commerçant', payment['merchantName']),
                    _buildDetailRow('Local', payment['propertyNumber']),
                    _buildDetailRow('Montant', payment['amount']),
                    _buildDetailRow('Échéance', payment['dueDate']),
                    _buildDetailRow(
                        'Statut', _getStatusLabel(payment['status'])),
                    if (payment['paidDate'] != null)
                      _buildDetailRow('Date de paiement', payment['paidDate']),
                    if (payment['daysOverdue'] != null)
                      _buildDetailRow(
                          'Jours de retard', '${payment['daysOverdue']} jours'),
                    _buildDetailRow('Description', payment['description']),
                    if (payment['contractNumber'] != null)
                      _buildDetailRow('N° Contrat', payment['contractNumber']),
                    if (payment['paymentMethod'] != null)
                      _buildDetailRow(
                          'Mode de paiement', payment['paymentMethod']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30.w,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      case 'partial':
        return 'Partiel';
      default:
        return 'Inconnu';
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Text(
                'Filtres avancés',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                children: [
                  ListTile(
                    leading: CustomIconWidget(
                      iconName: 'date_range',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 6.w,
                    ),
                    title: Text('Filtrer par période'),
                    onTap: () {
                      Navigator.pop(context);
                      _showDateRangeFilter();
                    },
                  ),
                  ListTile(
                    leading: CustomIconWidget(
                      iconName: 'attach_money',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 6.w,
                    ),
                    title: Text('Filtrer par montant'),
                    onTap: () {
                      Navigator.pop(context);
                      _showAmountRangeFilter();
                    },
                  ),
                  ListTile(
                    leading: CustomIconWidget(
                      iconName: 'business',
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 6.w,
                    ),
                    title: Text('Filtrer par local'),
                    onTap: () {
                      Navigator.pop(context);
                      _showPropertyFilter();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendReminder(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rappel envoyé à ${payment['merchantName']}',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.warningAccent,
      ),
    );
  }

  void _viewPaymentHistory(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Historique des paiements pour ${payment['merchantName']}',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _generateReceipt(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reçu généré pour ${payment['merchantName']}',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.infoAccent,
      ),
    );
  }

  void _editPaymentAmount(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Modification du montant pour ${payment['merchantName']}',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.neutralMedium,
      ),
    );
  }

  void _markAsDisputed(Map<String, dynamic> payment) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Paiement marqué en litige pour ${payment['merchantName']}',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.alertRed,
      ),
    );
  }

  void _exportPayments() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Export des ${_filteredPayments.length} paiements en cours...',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.primaryBlue,
      ),
    );
  }

  void _showDateRangeFilter() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filtre par période - Fonctionnalité à venir',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.infoAccent,
      ),
    );
  }

  void _showAmountRangeFilter() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filtre par montant - Fonctionnalité à venir',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.infoAccent,
      ),
    );
  }

  void _showPropertyFilter() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Filtre par local - Fonctionnalité à venir',
          style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
        ),
        backgroundColor: AppTheme.infoAccent,
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'settings':
        Navigator.pushNamed(context, '/settings-screen');
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aide - Fonctionnalité à venir',
              style: GoogleFonts.roboto(color: AppTheme.surfaceWhite),
            ),
            backgroundColor: AppTheme.infoAccent,
          ),
        );
        break;
    }
  }
}
