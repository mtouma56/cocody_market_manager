import 'package:flutter/material.dart';

import '../../services/paiements_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../payment_details_screen/payment_details_screen.dart';
import '../../routes/app_routes.dart';

class PaymentsManagementScreen extends StatefulWidget {
  final String? initialCommercantId;
  final String? initialCommercantName;

  const PaymentsManagementScreen({
    super.key,
    this.initialCommercantId,
    this.initialCommercantName,
  });

  @override
  State<PaymentsManagementScreen> createState() =>
      _PaymentsManagementScreenState();
}

class _PaymentsManagementScreenState extends State<PaymentsManagementScreen> {
  final _service = PaiementsService();

  // Variables d'état NÉCESSAIRES
  String _currentFilter = 'Tous';
  List<dynamic> _paiements = [];
  List<dynamic> _allPaiements = []; // IMPORTANT : garde tous les paiements
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaiements();
  }

  Future<void> _loadPaiements() async {
    print('🟢 Chargement paiements');
    setState(() => _isLoading = true);

    try {
      final response = await _service.getPaiements();

      print('✅ ${response.length} paiements chargés');

      setState(() {
        _allPaiements = response;
        _isLoading = false;
      });

      // CRITIQUE : Appelle _applyFilters APRÈS avoir chargé
      _applyFilters();
    } catch (e) {
      print('❌ ERREUR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // _applyFilters CORRIGÉ avec logs
  void _applyFilters() {
    print('🔍 Application filtre: $_currentFilter');
    print('📊 Total paiements: ${_allPaiements.length}');

    List<dynamic> filtered = List.from(_allPaiements);

    // Filtre par statut
    if (_currentFilter != 'Tous') {
      // CORRECTION : Map les labels UI vers les statuts DB
      String statutDB = _currentFilter;

      // Convertir le label UI en statut DB
      if (_currentFilter == 'Payés') {
        statutDB = 'Payé'; // Singulier dans la DB
      }

      filtered =
          filtered.where((p) {
            final statut = p['statut']?.toString() ?? '';
            return statut == statutDB;
          }).toList();

      print('Après filtre statut "$statutDB": ${filtered.length} paiements');
    }

    // Filtre par recherche
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered =
          filtered.where((paiement) {
            final bail = paiement['baux'] as Map<String, dynamic>?;
            final commercant = bail?['commercants'] as Map<String, dynamic>?;
            final nomCommercant =
                commercant?['nom']?.toString().toLowerCase() ?? '';

            return nomCommercant.contains(searchTerm);
          }).toList();

      print('Après recherche: ${filtered.length} paiements');
    }

    print('✅ Résultat final: ${filtered.length} paiements');

    setState(() {
      _paiements = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcule depuis _allPaiements
    final countTous = _allPaiements.length;
    final countPayes = _allPaiements.where((p) => p['statut'] == 'Payé').length;
    final countEnAttente =
        _allPaiements.where((p) => p['statut'] == 'En attente').length;
    final countEnRetard =
        _allPaiements.where((p) => p['statut'] == 'En retard').length;

    return Scaffold(
      appBar: AppBar(title: Text('Paiements')),
      body: Column(
        children: [
          // Barre recherche
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par commerçant, ...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                print('🔎 Recherche: $value');
                _applyFilters();
              },
            ),
          ),

          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tous ($countTous)',
                  isSelected: _currentFilter == 'Tous',
                  onTap: () {
                    print('👆 Clic sur Tous');
                    setState(() => _currentFilter = 'Tous');
                    _applyFilters(); // IMPORTANT
                  },
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: 'En attente ($countEnAttente)',
                  isSelected: _currentFilter == 'En attente',
                  color: Colors.orange,
                  onTap: () {
                    print('👆 Clic sur En attente');
                    setState(() => _currentFilter = 'En attente');
                    _applyFilters(); // IMPORTANT
                  },
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: 'Payés ($countPayes)',
                  isSelected: _currentFilter == 'Payés',
                  color: Colors.green,
                  onTap: () {
                    print('👆 Clic sur Payés');
                    setState(() => _currentFilter = 'Payés');
                    _applyFilters(); // IMPORTANT
                  },
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: 'En retard ($countEnRetard)',
                  isSelected: _currentFilter == 'En retard',
                  color: Colors.red,
                  onTap: () {
                    print('👆 Clic sur En retard');
                    setState(() => _currentFilter = 'En retard');
                    _applyFilters(); // IMPORTANT
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_paiements.length} paiement${_paiements.length > 1 ? "s" : ""} trouvé${_paiements.length > 1 ? "s" : ""}',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          SizedBox(height: 8),

          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _paiements.isEmpty
                    ? Center(child: Text('Aucun paiement trouvé'))
                    : RefreshIndicator(
                      onRefresh: _loadPaiements,
                      child: ListView.builder(
                        itemCount: _paiements.length,
                        itemBuilder: (context, index) {
                          final paiement = _paiements[index];
                          return _buildPaiementCard(paiement);
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.addPaymentFormScreen,
          );

          if (result == true) {
            _loadPaiements();
          }
        },
        backgroundColor: Colors.green,
        tooltip: 'Créer un nouveau paiement',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildPaiementCard(Map<String, dynamic> paiement) {
    final bail = paiement['baux'] as Map<String, dynamic>?;
    final commercant = bail?['commercants'] as Map<String, dynamic>?;
    final local = bail?['locaux'] as Map<String, dynamic>?;

    final montant = (paiement['montant'] as num?)?.toDouble() ?? 0;
    final statut = paiement['statut']?.toString() ?? 'Inconnu';
    final moisConcerne = paiement['mois_concerne']?.toString() ?? 'N/A';
    final dateEcheance = paiement['date_echeance']?.toString() ?? 'N/A';
    final datePaiement = paiement['date_paiement']?.toString() ?? 'N/A';
    final nomCommercant =
        commercant?['nom']?.toString() ?? 'Commerçant inconnu';
    final numeroLocal = local?['numero']?.toString() ?? 'N/A';

    Color statutColor = Colors.grey;
    if (statut == 'Payé') statutColor = Colors.green;
    if (statut == 'En retard') statutColor = Colors.red;
    if (statut == 'Partiel') statutColor = Colors.orange;
    if (statut == 'En attente') statutColor = Colors.blue;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.payment, color: statutColor, size: 32),
        title: Text(
          '${montant.toStringAsFixed(0)} FCFA',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Expanded(
                  child: Text(nomCommercant, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.store, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('Local $numeroLocal'),
              ],
            ),
            SizedBox(height: 4),
            Text(
              'Échéance: $dateEcheance',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              'Payé le: $datePaiement',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statutColor.withAlpha(51),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statut,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statutColor,
            ),
          ),
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => PaymentDetailsScreen(paiementId: paiement['id']),
            ),
          );

          if (result == true) {
            _loadPaiements();
          }
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Colors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.grey.shade200,
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
