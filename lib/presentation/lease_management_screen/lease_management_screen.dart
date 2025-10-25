import 'package:flutter/material.dart';

import '../../services/leases_service.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../lease_details_screen/lease_details_screen.dart';
import '../../routes/app_routes.dart';

class LeaseManagementScreen extends StatefulWidget {
  final String? initialCommercantId;
  final String? initialCommercantName;

  const LeaseManagementScreen({
    super.key,
    this.initialCommercantId,
    this.initialCommercantName,
  });

  @override
  State<LeaseManagementScreen> createState() => _LeaseManagementScreenState();
}

class _LeaseManagementScreenState extends State<LeaseManagementScreen> {
  // Variables d'état nécessaires
  String _currentFilter = 'Tous';
  List<dynamic> _baux = [];
  List<dynamic> _allBaux = []; // Garde TOUS les baux pour filtrage
  bool _isLoading = true;
  final _searchController = TextEditingController();

  final LeasesService _service = LeasesService();

  @override
  void initState() {
    super.initState();

    // Si commercant passé en paramètre, applique le filtre
    if (widget.initialCommercantId != null) {
      _searchController.text = widget.initialCommercantName ?? '';
    }

    _loadBaux();
  }

  // Méthode _loadBaux COMPLÈTE avec relations
  Future<void> _loadBaux() async {
    print('🔵 Début chargement baux');
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> response;

      // Si un commerçant spécifique est demandé, filtre par commerçant
      if (widget.initialCommercantId != null) {
        response =
            await _service.getLeasesByMerchant(widget.initialCommercantId);
      } else {
        // Sinon charge tous les baux
        response = await _service.getAllLeases();
      }

      print('✅ Reçu ${response.length} baux');
      if (response.isNotEmpty) {
        print('Premier bail: ${response[0]['contractNumber']}');
        print('Tenant: ${response[0]['tenantName']}');
      }

      // Convertit les données du service vers le format attendu par l'UI
      final convertedBaux = response
          .map((lease) => {
                'id': lease['id'],
                'numero_contrat': lease['contractNumber'],
                'statut': _convertStatusFromService(lease['status']),
                'date_debut': lease['startDate'],
                'date_fin': lease['endDate'],
                'montant_loyer': lease['monthlyRent'],
                'commercant_id': lease['merchantId'],
                'commercants': {
                  'nom': lease['tenantName'],
                  'activite': lease['tenantBusiness'],
                  'contact': lease['tenantPhone'],
                  'email': lease['tenantEmail'],
                },
                'locaux': {
                  'numero': lease['propertyNumber'],
                  'types_locaux': {
                    'nom': _convertPropertyTypeToName(lease['propertyType']),
                  },
                  'etages': {
                    'nom': _convertFloorToName(lease['propertyFloor']),
                  },
                },
              })
          .toList();

      setState(() {
        _allBaux = convertedBaux;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ ERREUR chargement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  // Convertit le status code du service vers le status français
  String _convertStatusFromService(String statusCode) {
    switch (statusCode) {
      case 'active':
        return 'Actif';
      case 'expiring':
        return 'Expire bientôt';
      case 'expired':
        return 'Expiré';
      case 'terminated':
        return 'Résilié';
      default:
        return 'Actif';
    }
  }

  // Convertit le code du type de propriété vers le nom français
  String _convertPropertyTypeToName(String typeCode) {
    switch (typeCode) {
      case '9m2_shop':
        return 'Boutique 9m²';
      case '4.5m2_shop':
        return 'Boutique 4.5m²';
      case 'restaurant':
        return 'Restaurant';
      case 'bank':
        return 'Banque';
      case 'box':
        return 'Box';
      case 'market_stall':
        return 'Étal';
      default:
        return 'Boutique';
    }
  }

  // Convertit le code d'étage vers le nom français
  String _convertFloorToName(String floorCode) {
    switch (floorCode) {
      case 'rdc':
        return 'Rez-de-chaussée';
      case '1er':
        return '1er étage';
      case '2eme':
        return '2ème étage';
      case '3eme':
        return '3ème étage';
      default:
        return 'Rez-de-chaussée';
    }
  }

  // Méthode _applyFilters pour filtrer localement
  void _applyFilters() {
    List<dynamic> filtered = List.from(_allBaux);

    // Filtre par statut
    if (_currentFilter == 'Actif') {
      filtered = filtered.where((b) => b['statut'] == 'Actif').toList();
    } else if (_currentFilter == 'Expire bientôt') {
      filtered =
          filtered.where((b) => b['statut'] == 'Expire bientôt').toList();
    } else if (_currentFilter == 'Expirés') {
      filtered = filtered.where((b) => b['statut'] == 'Expiré').toList();
    }

    // Filtre par recherche
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((bail) {
        final commercant = bail['commercants'];
        final local = bail['locaux'];

        final nomCommercant = commercant != null
            ? (commercant['nom'] ?? '').toString().toLowerCase()
            : '';
        final numeroLocal = local != null
            ? (local['numero'] ?? '').toString().toLowerCase()
            : '';
        final numeroContrat =
            (bail['numero_contrat'] ?? '').toString().toLowerCase();

        return nomCommercant.contains(searchTerm) ||
            numeroLocal.contains(searchTerm) ||
            numeroContrat.contains(searchTerm);
      }).toList();
    }

    setState(() {
      _baux = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcule les compteurs depuis _allBaux
    final countTous = _allBaux.length;
    final countActifs = _allBaux.where((b) => b['statut'] == 'Actif').length;
    final countExpireBientot =
        _allBaux.where((b) => b['statut'] == 'Expire bientôt').length;
    final countExpires = _allBaux.where((b) => b['statut'] == 'Expiré').length;

    return Scaffold(
      appBar: AppBar(title: Text('Baux')),
      body: Column(
        children: [
          // Barre recherche
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par commerçant, contrat...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _applyFilters(),
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
                    setState(() => _currentFilter = 'Tous');
                    _applyFilters();
                  },
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: 'Actif ($countActifs)',
                  isSelected: _currentFilter == 'Actif',
                  onTap: () {
                    setState(() => _currentFilter = 'Actif');
                    _applyFilters();
                  },
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: 'Expire bientôt ($countExpireBientot)',
                  isSelected: _currentFilter == 'Expire bientôt',
                  color: Colors.orange,
                  onTap: () {
                    setState(() => _currentFilter = 'Expire bientôt');
                    _applyFilters();
                  },
                ),
                SizedBox(width: 8),
                _FilterChip(
                  label: 'Expirés ($countExpires)',
                  isSelected: _currentFilter == 'Expirés',
                  color: Colors.red,
                  onTap: () {
                    setState(() => _currentFilter = 'Expirés');
                    _applyFilters();
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Texte compteur
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_baux.length} bail${_baux.length > 1 ? "x" : ""} trouvé${_baux.length > 1 ? "s" : ""}',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          SizedBox(height: 8),

          // Liste
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _baux.isEmpty
                    ? Center(child: Text('Aucun bail trouvé'))
                    : RefreshIndicator(
                        onRefresh: _loadBaux,
                        child: ListView.builder(
                          itemCount: _baux.length,
                          itemBuilder: (context, index) {
                            final bail = _baux[index];
                            return _buildBailCard(bail);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigation vers le formulaire de création de bail
          print('🔵 Navigation vers nouveau bail');
          final result = await Navigator.pushNamed(
            context,
            AppRoutes.addLeaseFormScreen,
          );

          // Si un bail a été créé avec succès, recharge la liste
          if (result == true) {
            print('✅ Bail créé, rechargement liste...');
            _loadBaux();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Ajouter un nouveau bail',
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 3,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  // Widget _buildBailCard avec navigation
  Widget _buildBailCard(Map<String, dynamic> bail) {
    // EXTRAIRE avec vérifications NULL
    final commercant = bail['commercants'] as Map<String, dynamic>?;
    final local = bail['locaux'] as Map<String, dynamic>?;
    final typeLocal = local?['types_locaux'] as Map<String, dynamic>?;

    final numeroContrat = bail['numero_contrat']?.toString() ?? 'N/A';
    final nomCommercant =
        commercant?['nom']?.toString() ?? 'Commerçant inconnu';
    final numeroLocal = local?['numero']?.toString() ?? 'N/A';
    final typeLocalNom = typeLocal?['nom']?.toString() ?? 'Type inconnu';
    final montantLoyer = (bail['montant_loyer'] as num?)?.toDouble() ?? 0;
    final dateFin = bail['date_fin']?.toString() ?? '';
    final statut = bail['statut']?.toString() ?? 'Inconnu';

    // Couleurs statut
    Color statutColor = Colors.grey;
    if (statut == 'Actif') statutColor = Colors.green;
    if (statut == 'Expire bientôt') statutColor = Colors.orange;
    if (statut == 'Expiré') statutColor = Colors.red;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(
          'Bail $numeroContrat',
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
                Text('Local $numeroLocal • $typeLocalNom'),
              ],
            ),
            SizedBox(height: 4),
            Text(
              '${montantLoyer.toStringAsFixed(0)} FCFA/mois',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontSize: 15,
              ),
            ),
            if (dateFin.isNotEmpty)
              Text(
                'Fin: $dateFin',
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
              builder: (context) => LeaseDetailsScreen(leaseId: bail['id']),
            ),
          );

          if (result == true) {
            _loadBaux(); // Recharge si modifié
          }
        },
      ),
    );
  }
}

// Widget _FilterChip
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
