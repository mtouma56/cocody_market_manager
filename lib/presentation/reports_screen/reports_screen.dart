import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/paiements_service.dart';
import '../../services/rapport_service.dart';
import '../../widgets/custom_bottom_bar.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _service = PaiementsService();
  final _rapportService = RapportService();

  String _periodeSelectionnee = 'Aujourd\'hui';
  String _typeRapport = 'Tous'; // Type de rapport
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now();

  List<dynamic> _paiements = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chargerPaiements();
  }

  Future<void> _chargerPaiements() async {
    setState(() => _isLoading = true);

    try {
      final paiements = await _service.getPaiements();

      // Logique spéciale pour les rapports en retard et en attente
      final paiementsFiltres = paiements.where((p) {
        final statut = p['statut'] ?? '';

        // Filtrer par type de rapport
        switch (_typeRapport) {
          case 'Paiements en retard':
            // ENGLOBE TOUS les paiements en retard, sans exception
            return statut == 'En retard';
          case 'Paiements en attente':
            // ENGLOBE TOUS les paiements en attente, sans exception
            return statut == 'En attente';
          case 'Paiements effectués':
            if (statut != 'Payé' && statut != 'Partiel') return false;
            break;
          case 'Tous':
          default:
            // Pour "Tous", appliquer le filtre de date
            break;
        }

        // Filtrer par date UNIQUEMENT pour les rapports "Tous" et "Paiements effectués"
        if (_typeRapport != 'Paiements en retard' &&
            _typeRapport != 'Paiements en attente') {
          final datePaiement = p['date_paiement'] ?? p['date_echeance'];
          if (datePaiement == null) return false;

          final date = DateTime.parse(datePaiement);
          return date.isAfter(_dateDebut.subtract(const Duration(days: 1))) &&
              date.isBefore(_dateFin.add(const Duration(days: 1)));
        }

        return true; // Inclure tous les paiements pour les rapports spéciaux
      }).toList();

      setState(() {
        _paiements = paiementsFiltres;
        _isLoading = false;
      });

      print('✅ Chargé ${paiementsFiltres.length} paiements pour $_typeRapport');
    } catch (e) {
      print('❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  void _selectionnerTypeRapport(String type) {
    setState(() {
      _typeRapport = type;
    });
    _chargerPaiements();
  }

  void _selectionnerPeriode(String periode) {
    // Ignorer la sélection de période pour les rapports spéciaux
    if (_typeRapport == 'Paiements en retard' ||
        _typeRapport == 'Paiements en attente') {
      return;
    }

    setState(() {
      _periodeSelectionnee = periode;
      final now = DateTime.now();

      switch (periode) {
        case 'Aujourd\'hui':
          _dateDebut = DateTime(now.year, now.month, now.day);
          _dateFin = DateTime(now.year, now.month, now.day);
          break;
        case 'Cette semaine':
          final weekday = now.weekday;
          _dateDebut = now.subtract(Duration(days: weekday - 1));
          _dateFin = now.add(Duration(days: 7 - weekday));
          break;
        case 'Ce mois':
          _dateDebut = DateTime(now.year, now.month, 1);
          _dateFin = DateTime(now.year, now.month + 1, 0);
          break;
        case 'Personnalisée':
          return;
      }
    });
    _chargerPaiements();
  }

  Future<void> _choisirDateDebut() async {
    // Bloquer pour les rapports spéciaux
    if (_typeRapport == 'Paiements en retard' ||
        _typeRapport == 'Paiements en attente') {
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _dateDebut,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _dateDebut = date);
      _chargerPaiements();
    }
  }

  Future<void> _choisirDateFin() async {
    // Bloquer pour les rapports spéciaux
    if (_typeRapport == 'Paiements en retard' ||
        _typeRapport == 'Paiements en attente') {
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: _dateFin,
      firstDate: _dateDebut,
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() => _dateFin = date);
      _chargerPaiements();
    }
  }

  double _calculerTotal() {
    return _paiements.fold(
        0.0, (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0));
  }

  Map<String, int> _compterParStatut() {
    final map = <String, int>{};
    for (var p in _paiements) {
      final statut = p['statut'] ?? 'Inconnu';
      map[statut] = (map[statut] ?? 0) + 1;
    }
    return map;
  }

  Color _getColorForRapportType(String type) {
    switch (type) {
      case 'Paiements en retard':
        return Colors.red;
      case 'Paiements en attente':
        return Colors.orange;
      case 'Paiements effectués':
        return Colors.green;
      case 'Tous':
      default:
        return Colors.blue;
    }
  }

  IconData _getIconForRapportType(String type) {
    switch (type) {
      case 'Paiements en retard':
        return Icons.warning;
      case 'Paiements en attente':
        return Icons.schedule;
      case 'Paiements effectués':
        return Icons.check_circle;
      case 'Tous':
      default:
        return Icons.assessment;
    }
  }

  String _getDescriptionForRapportType(String type) {
    switch (type) {
      case 'Paiements en retard':
        return 'Englobe TOUS les paiements en retard, sans exception';
      case 'Paiements en attente':
        return 'Englobe TOUS les paiements en attente, sans exception';
      case 'Paiements effectués':
        return 'Paiements réellement encaissés (payé et partiel)';
      case 'Tous':
      default:
        return 'Tous les paiements selon la période sélectionnée';
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculerTotal();
    final statsStatut = _compterParStatut();
    final rapportColor = _getColorForRapportType(_typeRapport);
    final isRapportSpecial = _typeRapport == 'Paiements en retard' ||
        _typeRapport == 'Paiements en attente';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerPaiements,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélection du type de rapport avec description
          Container(
            padding: const EdgeInsets.all(16),
            color: rapportColor.withAlpha(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getIconForRapportType(_typeRapport),
                        color: rapportColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Type de rapport',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rapportColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: rapportColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getDescriptionForRapportType(_typeRapport),
                          style: TextStyle(fontSize: 11, color: rapportColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    'Tous',
                    'Paiements effectués',
                    'Paiements en retard',
                    'Paiements en attente',
                  ].map((type) {
                    final isSelected = _typeRapport == type;
                    final typeColor = _getColorForRapportType(type);
                    return ChoiceChip(
                      label: Text(type),
                      selected: isSelected,
                      onSelected: (_) => _selectionnerTypeRapport(type),
                      selectedColor: typeColor.withAlpha(77),
                      backgroundColor: typeColor.withAlpha(26),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Color.lerp(typeColor, Colors.black, 0.2) ??
                                typeColor
                            : Color.lerp(typeColor, Colors.black, 0.4) ??
                                typeColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Filtres période (masqués pour rapports spéciaux)
          if (!isRapportSpecial)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Période',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Aujourd\'hui',
                      'Cette semaine',
                      'Ce mois',
                      'Personnalisée',
                    ].map((p) {
                      final isSelected = _periodeSelectionnee == p;
                      return ChoiceChip(
                        label: Text(p),
                        selected: isSelected,
                        onSelected: (_) => _selectionnerPeriode(p),
                        selectedColor: Colors.green,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_periodeSelectionnee == 'Personnalisée') ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _choisirDateDebut,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              'Du : ${DateFormat('dd/MM/yyyy').format(_dateDebut)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _choisirDateFin,
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              'Au : ${DateFormat('dd/MM/yyyy').format(_dateFin)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Statistiques
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: Color.lerp(rapportColor, Colors.white, 0.9) ??
                        rapportColor.withAlpha(26),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            _typeRapport == 'Paiements effectués'
                                ? 'Total encaissé'
                                : 'Total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${total.toStringAsFixed(0)} FCFA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  Color.lerp(rapportColor, Colors.black, 0.1) ??
                                      rapportColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Nombre',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_paiements.length}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Liste paiements avec informations spéciales pour partiels en retard
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _paiements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_getIconForRapportType(_typeRapport),
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              isRapportSpecial
                                  ? 'Aucun ${_typeRapport.toLowerCase().replaceAll('paiements ', '')} trouvé'
                                  : 'Aucun ${_typeRapport.toLowerCase()} pour cette période',
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _paiements.length,
                        itemBuilder: (context, index) {
                          final p = _paiements[index];
                          final bail = p['baux'] as Map<String, dynamic>?;
                          final commercant =
                              bail?['commercants'] as Map<String, dynamic>?;
                          final local =
                              bail?['locaux'] as Map<String, dynamic>?;

                          final montant =
                              (p['montant'] as num?)?.toDouble() ?? 0;
                          final montantInitial =
                              (p['montant_initial'] as num?)?.toDouble() ??
                                  montant;
                          final statut = p['statut'] ?? '';
                          final date =
                              p['date_paiement'] ?? p['date_echeance'] ?? '';
                          final mode = p['mode_paiement'] ?? '';

                          Color statutColor = Colors.grey;
                          if (statut == 'Payé') statutColor = Colors.green;
                          if (statut == 'Partiel') statutColor = Colors.orange;
                          if (statut == 'En retard') statutColor = Colors.red;
                          if (statut == 'En attente')
                            statutColor = Colors.orange.shade300;

                          // Informations spéciales pour paiements partiels en retard
                          final isPartielEnRetard =
                              statut == 'En retard' && montant < montantInitial;
                          final montantRestant =
                              isPartielEnRetard ? montantInitial - montant : 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: statutColor.withAlpha(51),
                                child: Icon(
                                    statut == 'En retard'
                                        ? Icons.warning
                                        : statut == 'En attente'
                                            ? Icons.schedule
                                            : Icons.payment,
                                    color: statutColor),
                              ),
                              title: Text(
                                commercant?['nom'] ?? 'N/A',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Local ${local?['numero'] ?? 'N/A'}'),
                                  Text(
                                    '${date.isNotEmpty ? DateFormat('dd/MM/yyyy').format(DateTime.parse(date)) : 'N/A'} • ${mode.isNotEmpty ? mode : 'N/A'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  // Informations détaillées pour partiels en retard
                                  if (isPartielEnRetard) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Montant initial: ${montantInitial.toStringAsFixed(0)} F',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red.shade800),
                                          ),
                                          Text(
                                            'Payé partiellement: ${montant.toStringAsFixed(0)} F',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange.shade800),
                                          ),
                                          Text(
                                            'Montant restant: ${montantRestant.toStringAsFixed(0)} F',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red.shade900,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    isPartielEnRetard
                                        ? '${montantRestant.toStringAsFixed(0)} F'
                                        : '${montant.toStringAsFixed(0)} F',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isPartielEnRetard
                                          ? Colors.red.shade700
                                          : null,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statutColor.withAlpha(51),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPartielEnRetard
                                          ? 'Partiel en retard'
                                          : statut,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statutColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

      // Bouton export PDF
      floatingActionButton: _paiements.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () async {
                try {
                  await _rapportService.genererRapportPDF(
                    paiements: _paiements,
                    dateDebut: _dateDebut,
                    dateFin: _dateFin,
                    periode: isRapportSpecial
                        ? 'Toutes périodes'
                        : _periodeSelectionnee,
                    typeRapport: _typeRapport,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rapport PDF généré'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export PDF'),
              backgroundColor: Colors.red,
            )
          : null,

      // Bottom Navigation Bar
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 5, // Reports est à l'index 5
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }
}
