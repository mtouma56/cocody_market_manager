import 'package:flutter/material.dart';

import '../../core/app_export.dart';
import '../../services/leases_service.dart';
import '../../widgets/custom_app_bar.dart';

class ExpiringLeasesScreen extends StatefulWidget {
  const ExpiringLeasesScreen({Key? key}) : super(key: key);

  @override
  State<ExpiringLeasesScreen> createState() => _ExpiringLeasesScreenState();
}

class _ExpiringLeasesScreenState extends State<ExpiringLeasesScreen> {
  final LeasesService _leasesService = LeasesService();
  List<Map<String, dynamic>> _expiringLeases = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadExpiringLeases();
  }

  Future<void> _loadExpiringLeases() async {
    try {
      final leases = await _leasesService.getExpiringLeases(30); // 30 jours
      setState(() {
        _expiringLeases = leases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Baux expirant bientôt",
        centerTitle: true,
        backgroundColor: AppTheme.primaryGreen,
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
                        onPressed: _loadExpiringLeases,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _expiringLeases.isEmpty
                  ? _buildEmptyState()
                  : _buildLeasesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun bail expirant prochainement',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tous les baux sont valides pour les 30 prochains jours',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLeasesList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade200),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.event_note, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_expiringLeases.length} bail${_expiringLeases.length > 1 ? 'aux' : ''} expire${_expiringLeases.length > 1 ? 'nt' : ''} bientôt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                    Text(
                      'Préparez les renouvellements ou nouveaux contrats',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
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
            onRefresh: _loadExpiringLeases,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _expiringLeases.length,
              itemBuilder: (context, index) {
                final lease = _expiringLeases[index];
                return _buildLeaseCard(lease);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaseCard(Map<String, dynamic> lease) {
    final DateTime? dateFin =
        lease['date_fin'] != null ? DateTime.tryParse(lease['date_fin']) : null;
    final String formattedDate = dateFin != null
        ? '${dateFin.day.toString().padLeft(2, '0')}/${dateFin.month.toString().padLeft(2, '0')}/${dateFin.year}'
        : 'N/A';

    final int daysUntilExpiry =
        dateFin != null ? dateFin.difference(DateTime.now()).inDays : 0;

    final String merchantName = lease['commercants']?['nom'] ?? 'N/A';
    final String propertyNumber = lease['locaux']?['numero'] ?? 'N/A';
    final double monthlyRent =
        (lease['loyer_mensuel'] as num?)?.toDouble() ?? 0.0;

    Color urgencyColor = Colors.orange;
    String urgencyText = 'Expire dans $daysUntilExpiry jours';

    if (daysUntilExpiry <= 7) {
      urgencyColor = Colors.red;
      urgencyText = 'Expire dans $daysUntilExpiry jours (URGENT)';
    } else if (daysUntilExpiry <= 15) {
      urgencyColor = Colors.orange.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: urgencyColor.withAlpha(128), width: 1),
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
                    color: urgencyColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    urgencyText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: urgencyColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${monthlyRent.toStringAsFixed(0)} FCFA/mois',
                  style: const TextStyle(
                    fontSize: 16,
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
            _buildInfoRow(Icons.calendar_today, 'Date fin', formattedDate),
            const SizedBox(height: 8),
            _buildInfoRow(
                Icons.receipt, 'Contrat', lease['numero_contrat'] ?? 'N/A'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.leaseDetailsScreen,
                        arguments: lease['id'],
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Voir détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                      side: BorderSide(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addLeaseFormScreen,
                        arguments: {'renewFrom': lease['id']},
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Renouveler'),
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