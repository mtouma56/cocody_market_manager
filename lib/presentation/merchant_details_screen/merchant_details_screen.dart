import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/merchants_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/merchant_stat_card_widget.dart';
import './widgets/merchant_tab_button_widget.dart';

class MerchantDetailsScreen extends StatefulWidget {
  final String merchantId;

  const MerchantDetailsScreen({super.key, required this.merchantId});

  @override
  State<MerchantDetailsScreen> createState() => _MerchantDetailsScreenState();
}

class _MerchantDetailsScreenState extends State<MerchantDetailsScreen> {
  final MerchantsService _service = MerchantsService();

  Map<String, dynamic>? _data;
  bool _isLoading = true;
  String _currentTab = 'locaux'; // 'locaux', 'paiements', 'historique'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getCommercantDetails(widget.merchantId);
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
        appBar: const CustomAppBar(
          title: 'Détails Commerçant',
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_data == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Détails Commerçant',
        ),
        body: const Center(child: Text('Erreur de chargement')),
      );
    }

    final commercant = _data!['commercant'];
    final stats = _data!['stats'];
    final baux = _data!['baux'] as List;
    final paiements = _data!['paiements'] as List;

    final bauxActifs = baux.where((b) => b['statut'] == 'Actif').toList();
    final locaux = bauxActifs.map((b) => b['locaux']).toList();

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: commercant['nom'] ?? 'Commerçant',
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Modifier commerçant
              print('Modifier commerçant');
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
              // En-tête avec photo
              Container(
                padding: EdgeInsets.all(4.w),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 8.w,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: commercant['photo_url'] != null
                          ? NetworkImage(commercant['photo_url'])
                          : null,
                      child: commercant['photo_url'] == null
                          ? Text(
                              (commercant['nom'] ?? '').isNotEmpty
                                  ? commercant['nom']
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'C',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commercant['nom'] ?? '',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (commercant['activite'] != null)
                            Text(
                              commercant['activite'],
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          SizedBox(height: 1.h),
                          if (commercant['contact'] != null)
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey),
                                SizedBox(width: 2.w),
                                Text(
                                  commercant['contact'],
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
                  ],
                ),
              ),

              // Stats
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Row(
                  children: [
                    Expanded(
                      child: MerchantStatCardWidget(
                        title: 'Locaux actifs',
                        value: '${stats['baux_actifs']}',
                        icon: Icons.store,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: MerchantStatCardWidget(
                        title: 'Total payé',
                        value:
                            '${(stats['total_paye'] as double).toStringAsFixed(0)} F',
                        icon: Icons.payments,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              // Alerte paiements en retard
              if (stats['en_retard'] > 0)
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
                              '${(stats['en_retard'] as double).toStringAsFixed(0)} FCFA',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 4.w),

              // Onglets
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    MerchantTabButtonWidget(
                      label: 'Locaux (${locaux.length})',
                      isSelected: _currentTab == 'locaux',
                      onTap: () => setState(() => _currentTab = 'locaux'),
                    ),
                    SizedBox(width: 2.w),
                    MerchantTabButtonWidget(
                      label: 'Paiements (${paiements.length})',
                      isSelected: _currentTab == 'paiements',
                      onTap: () => setState(() => _currentTab = 'paiements'),
                    ),
                    SizedBox(width: 2.w),
                    MerchantTabButtonWidget(
                      label: 'Historique',
                      isSelected: _currentTab == 'historique',
                      onTap: () => setState(() => _currentTab = 'historique'),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.w),

              // Contenu selon onglet
              if (_currentTab == 'locaux')
                _buildLocauxTab(locaux)
              else if (_currentTab == 'paiements')
                _buildPaiementsTab(paiements)
              else
                _buildHistoriqueTab(baux),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocauxTab(List locaux) {
    if (locaux.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8.w),
        child: Center(
          child: Text(
            'Aucun local actif',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
        ),
      );
    }

    return Column(
      children: locaux.map<Widget>((local) {
        final numero = local?['numero'] as String? ?? '';
        final type = local?['types_locaux']?['nom'] as String? ?? '';
        final etage = local?['etages']?['nom'] as String? ?? '';
        final localId = local?['id'] as String? ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.store, color: Colors.blue),
          ),
          title: Text(
            numero,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('$type - $etage'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            if (localId.isNotEmpty) {
              Navigator.pushNamed(
                context,
                AppRoutes.propertyDetailsScreen,
                arguments: localId,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Impossible d\'ouvrir les détails de ce local'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildPaiementsTab(List paiements) {
    if (paiements.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8.w),
        child: Center(
          child: Text(
            'Aucun paiement',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
          ),
        ),
      );
    }

    return Column(
      children: paiements.take(10).map<Widget>((p) {
        final montant = (p['montant'] as num?)?.toDouble() ?? 0;
        final date = p['date_paiement'] as String? ?? '';
        final statut = p['statut'] as String? ?? '';
        final local = p['baux']?['locaux'];
        final numero = local?['numero'] as String? ?? '';

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
          subtitle: Text('$numero - $date'),
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

  Widget _buildHistoriqueTab(List baux) {
    return Column(
      children: baux.map<Widget>((bail) {
        final local = bail['locaux'];
        final numero = local?['numero'] as String? ?? '';
        final dateDebut = bail['date_debut'] as String? ?? '';
        final dateFin = bail['date_fin'] as String? ?? '';
        final statut = bail['statut'] as String? ?? '';
        final loyer = (bail['montant_loyer'] as num?)?.toDouble() ?? 0;

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
            numero,
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
