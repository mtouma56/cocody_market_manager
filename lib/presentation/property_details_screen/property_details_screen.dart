import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/properties_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/property_info_section_widget.dart';
import './widgets/property_stats_card_widget.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  final PropertiesService _service = PropertiesService();

  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _currentTab = 'infos'; // 'infos', 'paiements', 'historique'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getPropertyDetails(widget.propertyId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Détails du Local'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_data == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Détails du Local'),
        body: const Center(child: Text('Erreur de chargement')),
      );
    }

    final local = _data!['local'];
    final bailActif = _data!['bail_actif'];
    final paiements = _data!['paiements'] as List;
    final stats = _data!['stats'];

    final numero = local['numero'] ?? '';
    final type = local['types_locaux']?['nom'] ?? '';
    final etage = local['etages']?['nom'] ?? '';
    final surface = local['types_locaux']?['surface_m2'] ?? 0;
    final statut = local['statut'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Local $numero',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Modifier local
              print('Modifier local $numero');
            },
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
              // En-tête avec informations du local
              Container(
                padding: EdgeInsets.all(4.w),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    Container(
                      width: 16.w,
                      height: 16.w,
                      decoration: BoxDecoration(
                        color: _getStatusColor(statut).withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 8.w,
                        color: _getStatusColor(statut),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Local $numero',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$type - ${surface}m²',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 14, color: Colors.grey),
                              SizedBox(width: 2.w),
                              Text(
                                etage,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                      decoration: BoxDecoration(
                        color: _getStatusColor(statut).withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statut,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _getStatusColor(statut),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Statistiques
              if (bailActif != null) ...[
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: PropertyStatsCardWidget(
                          title: 'Taux de paiement',
                          value:
                              '${(stats['taux_paiement'] as double).toStringAsFixed(1)}%',
                          icon: Icons.trending_up,
                          color: (stats['taux_paiement'] as double) >= 90
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: PropertyStatsCardWidget(
                          title: 'Revenus totaux',
                          value:
                              '${(stats['montant_total'] as double).toStringAsFixed(0)} F',
                          icon: Icons.payments,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                if (stats['montant_en_retard'] > 0)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.w),
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 3.w),
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
                                '${(stats['montant_en_retard'] as double).toStringAsFixed(0)} FCFA',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              SizedBox(height: 4.w),

              // Onglets
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    _TabButton(
                      label: 'Informations',
                      isSelected: _currentTab == 'infos',
                      onTap: () => setState(() => _currentTab = 'infos'),
                    ),
                    if (bailActif != null) ...[
                      SizedBox(width: 2.w),
                      _TabButton(
                        label: 'Paiements (${paiements.length})',
                        isSelected: _currentTab == 'paiements',
                        onTap: () => setState(() => _currentTab = 'paiements'),
                      ),
                    ],
                    SizedBox(width: 2.w),
                    _TabButton(
                      label: 'Historique',
                      isSelected: _currentTab == 'historique',
                      onTap: () => setState(() => _currentTab = 'historique'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.w),

              // Contenu selon onglet
              if (_currentTab == 'infos')
                PropertyInfoSectionWidget(
                  local: local,
                  bailActif: bailActif,
                )
              else if (_currentTab == 'paiements')
                _buildPaiementsTab(paiements)
              else
                _buildHistoriqueTab(local),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'Occupé':
        return Colors.green;
      case 'Disponible':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPaiementsTab(List paiements) {
    if (paiements.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8.w),
        child: Center(
          child: Text(
            'Aucun paiement enregistré',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
        ),
      );
    }

    return Column(
      children: paiements.map<Widget>((p) {
        final montant = (p['montant'] as num?)?.toDouble() ?? 0;
        final date = p['date_paiement'] as String? ?? '';
        final statut = p['statut'] as String? ?? '';
        final mois = p['mois'] as String? ?? '';

        Color statutColor = Colors.grey;
        if (statut == 'Payé') statutColor = Colors.green;
        if (statut == 'En retard') statutColor = Colors.red;
        if (statut == 'Partiel') statutColor = Colors.orange;

        return ListTile(
          leading: Icon(Icons.payment, color: statutColor),
          title: Text(
            '${montant.toStringAsFixed(0)} FCFA',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('$mois - $date'),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
            decoration: BoxDecoration(
              color: statutColor.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statut,
              style: TextStyle(
                fontSize: 10.sp,
                color: statutColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoriqueTab(Map<String, dynamic> local) {
    final baux = local['baux'] as List? ?? [];

    if (baux.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8.w),
        child: Center(
          child: Text(
            'Aucun bail enregistré',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
        ),
      );
    }

    return Column(
      children: baux.map<Widget>((bail) {
        final dateDebut = bail['date_debut'] as String? ?? '';
        final dateFin = bail['date_fin'] as String? ?? '';
        final statut = bail['statut'] as String? ?? '';
        final loyer = (bail['montant_loyer'] as num?)?.toDouble() ?? 0;
        final commercant = bail['commercants'];
        final nomCommercant = commercant?['nom'] as String? ?? 'N/A';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: statut == 'Actif'
                ? Colors.green.shade100
                : Colors.grey.shade100,
            child: Icon(
              Icons.receipt_long,
              color: statut == 'Actif' ? Colors.green : Colors.grey,
            ),
          ),
          title: Text(
            nomCommercant,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '$dateDebut → $dateFin\n${loyer.toStringAsFixed(0)} FCFA/mois',
            style: TextStyle(fontSize: 10.sp),
          ),
          trailing: Text(
            statut,
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
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
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
