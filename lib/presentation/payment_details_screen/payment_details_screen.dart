import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/paiements_service.dart';
import '../../services/quittance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final String paiementId;

  const PaymentDetailsScreen({super.key, required this.paiementId});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final _service = PaiementsService();
  final _quittanceService = QuittanceService();
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _paiement;
  List<dynamic> _historique = [];
  bool _isLoading = true;
  String? _errorMessage;

  Future<void> _marquerCommePaye() async {
    if (_paiement == null) return;

    final montantAttendu = (_paiement!['montant'] as num?)?.toDouble() ?? 0;
    final montantController = TextEditingController(
      text: montantAttendu.toStringAsFixed(0),
    );
    String modePaiement = 'Espèces';
    final notesController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Marquer comme payé',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Montant attendu: ${montantAttendu.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: montantController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant reçu (FCFA)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: modePaiement,
                      decoration: const InputDecoration(
                        labelText: 'Mode de paiement',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Espèces', child: Text('Espèces')),
                        DropdownMenuItem(
                            value: 'Mobile Money', child: Text('Mobile Money')),
                        DropdownMenuItem(
                            value: 'Virement', child: Text('Virement')),
                        DropdownMenuItem(
                            value: 'Chèque', child: Text('Chèque')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          modePaiement = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optionnel)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.note),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final montant =
                        double.tryParse(montantController.text) ?? 0;
                    if (montant <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez saisir un montant valide'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, {
                      'montant': montant,
                      'mode_paiement': modePaiement,
                      'notes': notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Valider paiement'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      try {
        // Affiche loader
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Validation du paiement...'),
              ],
            ),
          ),
        );

        // Valide le paiement
        await _service.validerPaiementExistant(
          paiementId: widget.paiementId,
          montantPaye: result['montant'],
          modePaiement: result['mode_paiement'],
          notes: result['notes'],
        );

        // Ferme le loader
        if (mounted) Navigator.pop(context);

        // Recharge les données
        await _loadData();

        // Message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement validé avec succès'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Ferme le loader
        if (mounted) Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la validation: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        print('❌ Erreur validation paiement: $e');
      }
    }
  }

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
      await _loadHistorique();
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

  Future<void> _loadHistorique() async {
    try {
      final historique = await supabase
          .from('quittances_historique')
          .select('*')
          .eq('paiement_id', widget.paiementId)
          .order('date_generation', ascending: false);

      setState(() {
        _historique = historique;
      });
    } catch (e) {
      print('❌ Erreur historique: $e');
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

  String _formatDateWithTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

  Future<void> _genererQuittance({bool isPartiel = false}) async {
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
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                  'Génération de ${isPartiel ? "reçu partiel" : "quittance"}...'),
            ],
          ),
        ),
      );

      // Génère la quittance avec gestion d'erreur détaillée
      await _quittanceService.genererQuittance(_paiement!,
          isPartiel: isPartiel);

      // Ferme le loader
      if (mounted) Navigator.pop(context);

      // Recharge l'historique après génération nouvelle
      await _loadHistorique();
      setState(() {});

      // Succès - Affiche message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${isPartiel ? "Reçu partiel" : "Quittance"} généré avec succès'),
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

  Widget _buildQuittanceButton() {
    final statut = _paiement?['statut'] ?? '';

    // CAS 1 : Paiement COMPLET → UNIQUEMENT Quittance
    if (statut == 'Payé') {
      return FloatingActionButton.extended(
        onPressed: () async {
          try {
            await _quittanceService.genererQuittance(
              _paiement!,
              isPartiel: false,
              isReimpression: false,
            );
            await _loadHistorique();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Quittance générée'),
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
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('Générer Quittance'),
        backgroundColor: Colors.blue,
      );
    }

    // CAS 2 : Paiement PARTIEL → UNIQUEMENT Reçu partiel
    else if (statut == 'Partiel') {
      return FloatingActionButton.extended(
        onPressed: () async {
          try {
            await _quittanceService.genererQuittance(
              _paiement!,
              isPartiel: true,
              isReimpression: false,
            );
            await _loadHistorique();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reçu partiel généré'),
                backgroundColor: Colors.orange,
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
        },
        icon: const Icon(Icons.receipt),
        label: const Text('Générer Reçu Partiel'),
        backgroundColor: Colors.orange,
      );
    }

    // CAS 3 : En attente / En retard → AUCUN bouton
    else {
      return const SizedBox.shrink(); // Invisible
    }
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

    // Détermine si on peut marquer comme payé
    final peutMarquerPaye =
        ['En attente', 'Partiel', 'En retard'].contains(statut);

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
              if (peutMarquerPaye)
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Marquer payé'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () => _marquerCommePaye());
                  },
                ),
              // SEULEMENT si paiement payé OU partiel
              if (statut == 'Payé' || statut == 'Partiel')
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(
                        statut == 'Payé' ? Icons.receipt_long : Icons.receipt,
                        color: statut == 'Payé' ? Colors.blue : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(statut == 'Payé'
                          ? 'Générer Quittance'
                          : 'Générer Reçu Partiel'),
                    ],
                  ),
                  onTap: () async {
                    Future.delayed(Duration.zero, () async {
                      try {
                        await _quittanceService.genererQuittance(
                          _paiement!,
                          isPartiel: statut == 'Partiel',
                          isReimpression: false,
                        );
                        await _loadHistorique();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document généré'),
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
                    });
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
                    const SizedBox(height: 16),

                    // Boutons d'action selon le statut
                    if (peutMarquerPaye) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _marquerCommePaye,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Marquer payé'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    // Bouton conditionnel selon le statut - LOGIQUE CORRIGÉE
                    if (statut == 'Payé') ...[
                      // UNIQUEMENT Quittance pour paiement complet
                      ElevatedButton.icon(
                        onPressed: () => _genererQuittance(),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Générer Quittance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    if (statut == 'Partiel') ...[
                      // UNIQUEMENT Reçu partiel pour paiement partiel
                      ElevatedButton.icon(
                        onPressed: () => _genererQuittance(isPartiel: true),
                        icon: const Icon(Icons.receipt),
                        label: const Text('Générer Reçu Partiel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

              // Section historique documents
              if (_historique.isNotEmpty) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Documents générés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ..._historique.map((doc) {
                  final typeDoc = doc['type_document'] ?? '';
                  final dateGen = doc['date_generation'] ?? '';
                  final montantDoc =
                      (doc['montant_documente'] as num?)?.toDouble() ?? 0;
                  final resteDu = (doc['reste_du'] as num?)?.toDouble();
                  final numeroQuittance = doc['numero_quittance'] ?? '';

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: typeDoc == 'Quittance'
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        child: Icon(
                          typeDoc == 'Quittance'
                              ? Icons.receipt_long
                              : Icons.receipt,
                          color: typeDoc == 'Quittance'
                              ? Colors.green
                              : Colors.orange,
                          size: 28,
                        ),
                      ),
                      title: Text(
                        typeDoc.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            'N° $numeroQuittance',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          Text(
                            'Généré le : ${_formatDateWithTime(dateGen)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${montantDoc.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green.shade700,
                            ),
                          ),
                          if (resteDu != null)
                            Text(
                              'Reste dû : ${resteDu.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.print,
                            color: Colors.blue, size: 28),
                        tooltip: 'Réimprimer',
                        onPressed: () async {
                          try {
                            // Régénère SANS enregistrer à nouveau
                            await _quittanceService.genererQuittance(
                              _paiement!,
                              isPartiel: typeDoc == 'Reçu partiel',
                              isReimpression:
                                  true, // ← N'enregistre pas à nouveau
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Document réimprimé'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur réimpression: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                const Divider(thickness: 2),
                const SizedBox(height: 8),
              ],

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
      floatingActionButton: peutMarquerPaye
          ? FloatingActionButton.extended(
              onPressed: _marquerCommePaye,
              icon: const Icon(Icons.check_circle),
              label: const Text('Marquer payé'),
              backgroundColor: Colors.green,
              tooltip: 'Marquer ce paiement comme payé',
            )
          : _buildQuittanceButton(),
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
