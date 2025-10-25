import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/paiements_service.dart';
import '../../services/quittance_service.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String paiementId;

  const PaymentDetailsScreen({super.key, required this.paiementId});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final _service = PaiementsService();
  final _quittanceService = QuittanceService();

  Map<String, dynamic>? _paiement;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateAndLoadData();
  }

  Future<void> _validateAndLoadData() async {
    // Validation du paiementId
    if (widget.paiementId.isEmpty || widget.paiementId.length < 8) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'ID de paiement invalide';
      });
      return;
    }

    // Vérification que c'est un UUID valide
    final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false);
    if (!uuidRegex.hasMatch(widget.paiementId)) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Format d\'ID de paiement invalide';
      });
      return;
    }

    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _service.getPaiementDetails(widget.paiementId);
      setState(() {
        _paiement = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger les détails du paiement';
      });
      print('❌ Erreur chargement paiement: $e');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatMois(String? moisStr) {
    if (moisStr == null || moisStr.isEmpty) return 'N/A';
    try {
      final parts = moisStr.split('-');
      if (parts.length != 2) return moisStr;

      final year = parts[0];
      final month = int.parse(parts[1]);

      if (month < 1 || month > 12) return moisStr;

      const mois = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre'
      ];

      return '${mois[month - 1]} $year';
    } catch (e) {
      return moisStr;
    }
  }

  Future<void> _confirmerSuppression() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Voulez-vous vraiment supprimer ce paiement ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // TODO: Supprimer paiement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Fonction de suppression à implémenter'),
            backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _genererQuittance() async {
    if (_paiement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune donnée de paiement disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vérification des données nécessaires
    final bail = _paiement!['baux'];
    if (bail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données de bail manquantes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Affiche le loader avec message explicite
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Génération de la quittance...'),
            ],
          ),
        ),
      );

      // Génère la quittance avec gestion d'erreur détaillée
      await _quittanceService.genererQuittance(_paiement!);

      // Ferme le loader
      if (mounted) Navigator.pop(context);

      // Succès - Affiche message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quittance générée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Ferme le loader en cas d'erreur
      if (mounted) Navigator.pop(context);

      final errorMsg = e.toString().contains('Exception:')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Erreur technique: $e';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      print('❌ Erreur génération quittance: $e');
    }
  }

  void _afficherOptionsQuittance(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Quittance générée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('N° ${result['numeroQuittance'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            const Text('Que souhaitez-vous faire ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _quittanceService.genererQuittance(_paiement!);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quittance envoyée vers l\'imprimante'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur impression: ${e.toString()}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.print),
            label: const Text('Imprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails Paiement')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des détails...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails Paiement')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _validateAndLoadData,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_paiement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails Paiement')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Aucune donnée de paiement trouvée'),
            ],
          ),
        ),
      );
    }

    final montant = (_paiement!['montant'] as num?)?.toDouble() ?? 0;
    final statut = _paiement!['statut'] ?? 'N/A';
    final datePaiement = _formatDate(_paiement!['date_paiement']);
    final dateEcheance = _formatDate(_paiement!['date_echeance']);
    final moisConcerne = _formatMois(_paiement!['mois_concerne']);
    final modePaiement = _paiement!['mode_paiement'] ?? 'N/A';
    final notes = _paiement!['notes'];

    final bail = _paiement!['baux'];
    final local = bail?['locaux'];
    final commercant = bail?['commercants'];

    final numeroLocal = local?['numero'] ?? 'N/A';
    final nomCommercant = commercant?['nom'] ?? 'N/A';
    final numeroContrat = bail?['numero_contrat'] ?? 'N/A';

    Color statutColor = Colors.grey;
    IconData statutIcon = Icons.help_outline;
    if (statut == 'Payé') {
      statutColor = Colors.green;
      statutIcon = Icons.check_circle;
    }
    if (statut == 'En retard') {
      statutColor = Colors.red;
      statutIcon = Icons.error;
    }
    if (statut == 'Partiel') {
      statutColor = Colors.orange;
      statutIcon = Icons.warning;
    }
    if (statut == 'En attente') {
      statutColor = Colors.blue;
      statutIcon = Icons.schedule;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement $moisConcerne'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                '/edit-payment-screen',
                arguments: widget.paiementId,
              );

              if (result == true) {
                _loadData();
              }
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              if (statut == 'Payé')
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.receipt, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Générer quittance'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, _genererQuittance);
                  },
                ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer'),
                  ],
                ),
                onTap: () {
                  Future.delayed(Duration.zero, _confirmerSuppression);
                },
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec status amélioré
              Container(
                padding: const EdgeInsets.all(20),
                color: statutColor.withAlpha(26),
                child: Column(
                  children: [
                    Icon(statutIcon, size: 64, color: statutColor),
                    const SizedBox(height: 12),
                    Text(
                      '${montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: statutColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statut,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: statutColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      moisConcerne,
                      style:
                          TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    ),
                    if (statut == 'Payé') ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _genererQuittance,
                        icon: const Icon(Icons.receipt),
                        label: const Text('Générer Quittance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Informations paiement
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informations',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Date de paiement',
                        value: datePaiement),
                    _InfoRow(
                        icon: Icons.event,
                        label: 'Date d\'échéance',
                        value: dateEcheance),
                    _InfoRow(
                        icon: Icons.account_balance_wallet,
                        label: 'Mode de paiement',
                        value: modePaiement),
                    if (notes != null && notes.isNotEmpty)
                      _InfoRow(icon: Icons.note, label: 'Notes', value: notes),
                  ],
                ),
              ),

              const Divider(),

              // Lié à
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lié à',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    // Commerçant
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: const Text('Commerçant',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(nomCommercant,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (commercant != null && commercant['id'] != null) {
                            Navigator.pushNamed(
                              context,
                              '/merchant-details-screen',
                              arguments: commercant['id'],
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Local
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.store, color: Colors.green),
                        ),
                        title: const Text('Local',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(numeroLocal,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (local != null && local['id'] != null) {
                            Navigator.pushNamed(
                              context,
                              '/property-details-screen',
                              arguments: local['id'],
                            );
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Bail
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.receipt_long,
                              color: Colors.orange),
                        ),
                        title: const Text('Bail',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        subtitle: Text(numeroContrat,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          if (bail != null && bail['id'] != null) {
                            Navigator.pushNamed(
                              context,
                              '/lease-details-screen',
                              arguments: bail['id'],
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: statut == 'Payé'
          ? FloatingActionButton.extended(
              onPressed: _genererQuittance,
              icon: const Icon(Icons.receipt),
              label: const Text('Quittance'),
              backgroundColor: Colors.blue,
              tooltip: 'Générer la quittance PDF',
            )
          : null,
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
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}