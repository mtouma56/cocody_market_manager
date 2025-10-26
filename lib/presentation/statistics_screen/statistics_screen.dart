import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/statistics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/payment_modes_chart_widget.dart';
import './widgets/revenue_chart_widget.dart';
import './widgets/top_merchants_chart_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final StatisticsService _service = StatisticsService();

  bool _isLoading = true;
  String _selectedPeriod = 'Ce mois';

  Map<String, double> _evolutionRevenus = {};
  List<Map<String, dynamic>> _topCommercants = [];
  Map<String, int> _repartitionModes = {};
  Map<String, dynamic> _comparaison = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _service.getEvolutionRevenus(6),
        _service.getTopCommercants(5),
        _service.getRepartitionModesPaiement(),
        _service.getComparaisonMois(),
      ]);

      setState(() {
        _evolutionRevenus = results[0] as Map<String, double>;
        _topCommercants = results[1] as List<Map<String, dynamic>>;
        _repartitionModes = results[2] as Map<String, int>;
        _comparaison = results[3] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Statistiques',
        variant: CustomAppBarVariant.standard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _exportStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _buildStatisticsContent(),
            ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 4,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF4CAF50),
          ),
          SizedBox(height: 4.w),
          const Text(
            'Chargement des statistiques...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sélecteur de période
          _buildPeriodSelector(),
          SizedBox(height: 4.w),

          // Comparaison mois actuel vs précédent
          _buildComparisonCard(),
          SizedBox(height: 3.w),

          // Graphique évolution revenus
          RevenueChartWidget(data: _evolutionRevenus),
          SizedBox(height: 3.w),

          // Top commerçants
          TopMerchantsChartWidget(data: _topCommercants),
          SizedBox(height: 3.w),

          // Répartition modes paiement
          PaymentModesChartWidget(data: _repartitionModes),
          SizedBox(height: 6.w),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Ce mois', 'Trimestre', 'Année', 'Personnalisée'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Période d\'analyse',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.w),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.w,
              children: periods.map((period) {
                final isSelected = period == _selectedPeriod;
                return FilterChip(
                  label: Text(
                    period,
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    if (period == 'Personnalisée') {
                      _showDateRangePicker();
                    } else {
                      _loadDataForPeriod(period);
                    }
                  },
                  selectedColor: const Color(0xFF4CAF50).withAlpha(51),
                  checkmarkColor: const Color(0xFF4CAF50),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard() {
    final actuel = _comparaison['actuel'] as double? ?? 0;
    final precedent = _comparaison['precedent'] as double? ?? 0;
    final variation = _comparaison['variation'] as double? ?? 0;

    final isPositive = variation >= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows, color: Colors.indigo, size: 20),
                SizedBox(width: 2.w),
                Text(
                  'Comparaison mensuelle',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
            Row(
              children: [
                Expanded(
                  child: _buildComparisonItem(
                    'Mois actuel',
                    actuel,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildComparisonItem(
                    'Mois précédent',
                    precedent,
                    Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
              decoration: BoxDecoration(
                color: isPositive ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${isPositive ? '+' : ''}${variation.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(String label, double value, Color color) {
    return Container(
      padding: EdgeInsets.all(2.5.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 1.w),
          Text(
            '${value.toStringAsFixed(0)} F',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );

    if (picked != null) {
      // Implémenter la logique de chargement pour la période personnalisée
      print('Période sélectionnée: ${picked.start} - ${picked.end}');
    } else {
      setState(() {
        _selectedPeriod = 'Ce mois';
      });
    }
  }

  void _loadDataForPeriod(String period) {
    // Implémenter la logique de chargement pour différentes périodes
    switch (period) {
      case 'Ce mois':
        _loadData();
        break;
      case 'Trimestre':
        // Charger données du trimestre
        _loadData();
        break;
      case 'Année':
        // Charger données de l'année
        _loadData();
        break;
    }
  }

  void _exportStatistics() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Génération du rapport statistiques...'),
              ),
            ],
          ),
        ),
      );

      // Simuler l'export
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📊 Rapport statistiques généré avec succès'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
