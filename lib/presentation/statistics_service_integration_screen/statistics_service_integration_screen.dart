import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/statistics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';

class StatisticsServiceIntegrationScreen extends StatefulWidget {
  const StatisticsServiceIntegrationScreen({super.key});

  @override
  State<StatisticsServiceIntegrationScreen> createState() =>
      _StatisticsServiceIntegrationScreenState();
}

class _StatisticsServiceIntegrationScreenState
    extends State<StatisticsServiceIntegrationScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  bool _isLoading = false;
  Map<String, dynamic> _serviceStatus = {};

  @override
  void initState() {
    super.initState();
    _checkServiceConnectivity();
  }

  Future<void> _checkServiceConnectivity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Test des différents services de statistiques
      final results = await Future.wait([
        _testRevenueEvolution(),
        _testTopMerchants(),
        _testPaymentMethods(),
        _testMonthlyComparison(),
      ]);

      setState(() {
        _serviceStatus = {
          'revenue_evolution': results[0],
          'top_merchants': results[1],
          'payment_methods': results[2],
          'monthly_comparison': results[3],
          'overall_status': results.every((r) => r['success'] == true),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _serviceStatus = {
          'error': e.toString(),
          'overall_status': false,
        };
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _testRevenueEvolution() async {
    try {
      final result = await _statisticsService.getEvolutionRevenus(6);
      return {
        'success': true,
        'data_count': result.length,
        'service': 'Revenue Evolution',
        'description': 'Évolution des revenus sur 6 mois',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'service': 'Revenue Evolution',
        'description': 'Évolution des revenus sur 6 mois',
      };
    }
  }

  Future<Map<String, dynamic>> _testTopMerchants() async {
    try {
      final result = await _statisticsService.getTopCommercants(5);
      return {
        'success': true,
        'data_count': result.length,
        'service': 'Top Merchants',
        'description': 'Top 5 commerçants par revenus',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'service': 'Top Merchants',
        'description': 'Top 5 commerçants par revenus',
      };
    }
  }

  Future<Map<String, dynamic>> _testPaymentMethods() async {
    try {
      final result = await _statisticsService.getRepartitionModesPaiement();
      return {
        'success': true,
        'data_count': result.length,
        'service': 'Payment Methods',
        'description': 'Répartition des modes de paiement',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'service': 'Payment Methods',
        'description': 'Répartition des modes de paiement',
      };
    }
  }

  Future<Map<String, dynamic>> _testMonthlyComparison() async {
    try {
      final result = await _statisticsService.getComparaisonMois();
      return {
        'success': true,
        'data_count': result.length,
        'service': 'Monthly Comparison',
        'description': 'Comparaison mensuelle des revenus',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'service': 'Monthly Comparison',
        'description': 'Comparaison mensuelle des revenus',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Services Statistiques',
        variant: CustomAppBarVariant.standard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _checkServiceConnectivity,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildServiceStatus(),
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
            'Test de connectivité des services...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatus() {
    final overallStatus = _serviceStatus['overall_status'] ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut global
          _buildOverallStatusCard(overallStatus),
          SizedBox(height: 6.w),

          // Services individuels
          _buildSectionTitle('Services Analytics'),
          SizedBox(height: 4.w),

          if (_serviceStatus.containsKey('revenue_evolution'))
            _buildServiceCard(_serviceStatus['revenue_evolution']),

          if (_serviceStatus.containsKey('top_merchants'))
            _buildServiceCard(_serviceStatus['top_merchants']),

          if (_serviceStatus.containsKey('payment_methods'))
            _buildServiceCard(_serviceStatus['payment_methods']),

          if (_serviceStatus.containsKey('monthly_comparison'))
            _buildServiceCard(_serviceStatus['monthly_comparison']),

          SizedBox(height: 6.w),

          // Actions
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildOverallStatusCard(bool isHealthy) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isHealthy
                ? [Colors.green.shade50, Colors.green.shade100]
                : [Colors.red.shade50, Colors.red.shade100],
          ),
        ),
        child: Column(
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.error,
              size: 48,
              color: isHealthy ? Colors.green : Colors.red,
            ),
            SizedBox(height: 3.w),
            Text(
              isHealthy ? 'Services Opérationnels' : 'Problème Détecté',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isHealthy ? Colors.green[800] : Colors.red[800],
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              isHealthy
                  ? 'Tous les services de statistiques sont connectés et fonctionnels'
                  : 'Un ou plusieurs services rencontrent des problèmes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final isSuccess = service['success'] ?? false;
    final serviceName = service['service'] ?? 'Service';
    final description = service['description'] ?? '';
    final dataCount = service['data_count'] ?? 0;
    final error = service['error'];

    return Card(
      margin: EdgeInsets.only(bottom: 3.w),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? Colors.green.withAlpha(26)
                        : Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSuccess ? 'OK' : 'ERREUR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isSuccess && dataCount > 0) ...[
              SizedBox(height: 3.w),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.data_usage, color: Colors.blue, size: 16),
                    SizedBox(width: 2.w),
                    Text(
                      '$dataCount entrées de données récupérées',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isSuccess && error != null) ...[
              SizedBox(height: 3.w),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 16),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Actions'),
        SizedBox(height: 4.w),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _checkServiceConnectivity,
                icon: const Icon(Icons.refresh),
                label: const Text('Retester'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/statistics-screen');
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Voir Stats'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 3.w),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
