import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/leases_service.dart';
import '../edit_lease_screen/edit_lease_screen.dart';

class LeaseDetailsScreen extends StatefulWidget {
  final String leaseId;

  const LeaseDetailsScreen({super.key, required this.leaseId});

  @override
  State<LeaseDetailsScreen> createState() => _LeaseDetailsScreenState();
}

class _LeaseDetailsScreenState extends State<LeaseDetailsScreen> {
  final _service = LeasesService();

  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _currentTab =
      'informations'; // 'informations', 'paiements', 'documents'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getBailDetails(widget.leaseId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erreur: $e');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails Bail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails Bail')),
        body: const Center(child: Text('Erreur de chargement')),
      );
    }

    final bail = _data!['bail'];
    final stats = _data!['stats'];
    final paiements = _data!['paiements'] as List;
    final commercant = bail['commercants'];
    final local = bail['locaux'];

    final numContrat = bail['numero_contrat'] ?? 'N/A';
    final nomCommercant = commercant?['nom'] ?? 'N/A';
    final numeroLocal = local?['numero'] ?? 'N/A';
    final statut = bail['statut'] ?? 'N/A';

    Color statutColor = Colors.grey;
    if (statut == 'Actif') statutColor = Colors.green;
    if (statut == 'Expiré') statutColor = Colors.red;
    if (statut == 'Résilié') statutColor = Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text('Bail $numContrat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditLeaseScreen(bail: _data!['bail']),
                ),
              );
              if (result == true) _loadData(); // Recharge les données
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Résilier le bail'),
                  ],
                ),
                onTap: () async {
                  Future.delayed(Duration.zero, () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la résiliation'),
                        content: const Text(
                          'Voulez-vous vraiment résilier ce bail ?\n\n'
                          'Cette action va :\n'
                          '• Mettre le bail en statut "Résilié"\n'
                          '• Libérer le local (statut "Disponible")\n\n'
                          'Cette action est irréversible.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Résilier'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await _service.resilierBail(widget.leaseId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Bail résilié avec succès'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context, true); // Retour à la liste
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Erreur: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: statutColor.withAlpha(51),
                          child: Icon(
                            Icons.receipt_long,
                            size: 32,
                            color: statutColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bail $numContrat',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$nomCommercant - Local $numeroLocal',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statutColor.withAlpha(51),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statut,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statutColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Taux de paiement',
                        value: '${stats['taux_paiement'].toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                        color: stats['taux_paiement'] >= 90
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Total payé',
                        value: '${stats['total_paye'].toStringAsFixed(0)} F',
                        icon: Icons.payments,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),

              if (stats['en_retard'] > 0)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paiements en retard',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                              ),
                            ),
                            Text(
                              '${stats['paiements_en_retard']} paiement(s) - ${stats['en_retard'].toStringAsFixed(0)} FCFA',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Onglets
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Informations',
                      isSelected: _currentTab == 'informations',
                      onTap: () => setState(() => _currentTab = 'informations'),
                    ),
                    const SizedBox(width: 8),
                    _TabButton(
                      label: 'Paiements (${paiements.length})',
                      isSelected: _currentTab == 'paiements',
                      onTap: () => setState(() => _currentTab = 'paiements'),
                    ),
                    const SizedBox(width: 8),
                    _TabButton(
                      label: 'Documents',
                      isSelected: _currentTab == 'documents',
                      onTap: () => setState(() => _currentTab = 'documents'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Contenu selon onglet
              if (_currentTab == 'informations')
                _buildInformationsTab(bail, commercant, local)
              else if (_currentTab == 'paiements')
                _buildPaiementsTab(paiements)
              else
                _buildDocumentsTab(bail),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInformationsTab(Map bail, Map? commercant, Map? local) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations générales',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.numbers,
            label: 'Numéro contrat',
            value: bail['numero_contrat'] ?? 'N/A',
          ),
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Date début',
            value: _formatDate(bail['date_debut']),
          ),
          _InfoRow(
            icon: Icons.event,
            label: 'Date fin',
            value: _formatDate(bail['date_fin']),
          ),
          _InfoRow(
            icon: Icons.payments,
            label: 'Loyer mensuel',
            value:
                '${(bail['montant_loyer'] as num?)?.toStringAsFixed(0) ?? '0'} FCFA',
          ),
          _InfoRow(
            icon: Icons.account_balance_wallet,
            label: 'Caution',
            value:
                '${(bail['montant_caution'] as num?)?.toStringAsFixed(0) ?? '0'} FCFA',
          ),
          _InfoRow(
            icon: Icons.store,
            label: 'Pas de porte',
            value:
                '${(bail['montant_pas_de_porte'] as num?)?.toStringAsFixed(0) ?? '0'} FCFA',
          ),
          const SizedBox(height: 24),
          const Text(
            'Commerçant',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person,
            label: 'Nom',
            value: commercant?['nom'] ?? 'N/A',
          ),
          _InfoRow(
            icon: Icons.work,
            label: 'Activité',
            value: commercant?['activite'] ?? 'N/A',
          ),
          _InfoRow(
            icon: Icons.phone,
            label: 'Contact',
            value: commercant?['contact'] ?? 'N/A',
          ),
          const SizedBox(height: 24),
          const Text(
            'Local',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.store,
            label: 'Numéro',
            value: local?['numero'] ?? 'N/A',
          ),
          _InfoRow(
            icon: Icons.category,
            label: 'Type',
            value: local?['types_locaux']?['nom'] ?? 'N/A',
          ),
          _InfoRow(
            icon: Icons.straighten,
            label: 'Surface',
            value: '${local?['types_locaux']?['surface_m2'] ?? '0'}m²',
          ),
          _InfoRow(
            icon: Icons.layers,
            label: 'Étage',
            value: local?['etages']?['nom'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildPaiementsTab(List paiements) {
    if (paiements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text('Aucun paiement', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: paiements.map<Widget>((p) {
        final montant = (p['montant'] as num?)?.toDouble() ?? 0;
        final date = _formatDate(p['date_paiement']);
        final statut = p['statut'] ?? '';
        final mois = p['mois_concerne'] ?? '';

        Color statutColor = Colors.grey;
        if (statut == 'Payé') statutColor = Colors.green;
        if (statut == 'En retard') statutColor = Colors.red;
        if (statut == 'Partiel') statutColor = Colors.orange;
        if (statut == 'En attente') statutColor = Colors.blue;

        return ListTile(
          leading: Icon(Icons.payment, color: statutColor, size: 32),
          title: Text(
            '${montant.toStringAsFixed(0)} FCFA',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('$mois - $date'),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statutColor.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statut,
              style: TextStyle(
                fontSize: 11,
                color: statutColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/payment-details-screen',
              arguments: p['id'],
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildDocumentsTab(Map bail) {
    final caution = (bail['montant_caution'] as num?)?.toDouble() ?? 0;
    final pasDePorte = (bail['montant_pas_de_porte'] as num?)?.toDouble() ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Documents financiers',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.attach_money, color: Colors.green),
            ),
            title: const Text('Caution'),
            subtitle: const Text('Montant versé au début du bail'),
            trailing: Text(
              '${caution.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.door_front_door, color: Colors.blue),
            ),
            title: const Text('Pas de porte'),
            subtitle: const Text('Frais d\'entrée unique'),
            trailing: Text(
              '${pasDePorte.toStringAsFixed(0)} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Contrat',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: const Icon(Icons.picture_as_pdf, color: Colors.red),
            ),
            title: const Text('Contrat de bail'),
            subtitle: Text('Signé le ${_formatDate(bail['date_debut'])}'),
            trailing: const Icon(Icons.download),
            onTap: () {
              // TODO: Télécharger contrat
              print('Télécharger contrat');
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
