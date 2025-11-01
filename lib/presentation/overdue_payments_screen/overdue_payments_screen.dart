import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/payments_service.dart';
import '../../widgets/custom_app_bar.dart';

class OverduePaymentsScreen extends StatefulWidget {
  const OverduePaymentsScreen({Key? key}) : super(key: key);

  @override
  State<OverduePaymentsScreen> createState() => _OverduePaymentsScreenState();
}

class _OverduePaymentsScreenState extends State<OverduePaymentsScreen> {
  final PaymentsService _paymentsService = PaymentsService();
  List<Map<String, dynamic>> _overduePayments = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadOverduePayments();
  }

  Future<void> _loadOverduePayments() async {
    try {
      final payments = await _paymentsService.getOverduePayments();
      setState(() {
        _overduePayments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsPaid(String paymentId) async {
    try {
      await _paymentsService.markPaymentAsPaid(paymentId);
      await _loadOverduePayments(); // Recharger la liste
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement marqué comme payé'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Paiements en retard",
        centerTitle: true,
        backgroundColor: AppTheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOverduePayments,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _overduePayments.isEmpty
                  ? _buildEmptyState()
                  : _buildPaymentsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun paiement en retard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tous les paiements sont à jour !',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.red.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_overduePayments.length} paiement${_overduePayments.length > 1 ? 's' : ''} en retard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    Text(
                      'Action requise pour régulariser la situation',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadOverduePayments,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _overduePayments.length,
              itemBuilder: (context, index) {
                final payment = _overduePayments[index];
                return _buildPaymentCard(payment);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final DateTime? dateEcheance = payment['date_echeance'] != null
        ? DateTime.tryParse(payment['date_echeance'])
        : null;
    final String formattedDate = dateEcheance != null
        ? '${dateEcheance.day.toString().padLeft(2, '0')}/${dateEcheance.month.toString().padLeft(2, '0')}/${dateEcheance.year}'
        : 'N/A';

    final int daysLate = dateEcheance != null
        ? DateTime.now().difference(dateEcheance).inDays
        : 0;

    final String merchantName =
        payment['baux']?['commercants']?['nom'] ?? 'N/A';
    final String propertyNumber =
        payment['baux']?['locaux']?['numero'] ?? 'N/A';
    final double amount = (payment['montant'] as num?)?.toDouble() ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$daysLate jour${daysLate > 1 ? 's' : ''} de retard',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${amount.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.person, 'Commerçant', merchantName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.business, 'Local', propertyNumber),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Échéance', formattedDate),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.paymentDetailsScreen,
                        arguments: payment['id'],
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsPaid(payment['id']),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Marquer payé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}