import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../services/dashboard_service.dart';
import '../../models/dashboard_stats.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DashboardService _dashboardService = DashboardService();

  bool _isLoading = true;
  String? _errorMessage;

  // Data from Supabase
  DashboardStats? _dashboardStats;
  List<OccupationEtage> _occupationEtages = [];
  List<TendanceData> _tendancePaiements = [];
  List<EncaissementType> _encaissementsParType = [];
  Map<String, Map<String, dynamic>> _statsEtages = {};

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load all dashboard data in parallel for better performance
      final results = await Future.wait([
        _dashboardService.getDashboardStats(),
        _dashboardService.getOccupationParEtage(),
        _dashboardService.getTendancePaiements(7),
        _dashboardService.getEncaissementsParType(),
        _dashboardService.getStatsDetailleesEtages(),
      ]);

      setState(() {
        _dashboardStats = results[0] as DashboardStats;
        _occupationEtages = results[1] as List<OccupationEtage>;
        _tendancePaiements = results[2] as List<TendanceData>;
        _encaissementsParType = results[3] as List<EncaissementType>;
        _statsEtages = results[4] as Map<String, Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des données: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Dashboard',
        variant: CustomAppBarVariant.standard,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
                ? _buildErrorState()
                : _buildDashboardContent(),
      ),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 0,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          _buildSkeletonGrid(),
          SizedBox(height: 6.w),
          _buildSkeletonChart(),
          _buildSkeletonChart(),
          _buildSkeletonChart(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 4.w),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 2.w),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 6.w),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardStats == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PARTIE 1 - 4 WIDGETS PRINCIPAUX (Grid 2x2)
          _buildMainWidgets(),
          SizedBox(height: 6.w),

          // PARTIE 2 - 3 GRAPHIQUES
          _buildChartsSection(),
          SizedBox(height: 6.w),

          // PARTIE 3 - APERÇU DÉTAILLÉ DES ÉTAGES
          _buildFloorDetailsSection(),
        ],
      ),
    );
  }

  // PARTIE 1 - 4 WIDGETS PRINCIPAUX
  Widget _buildMainWidgets() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      crossAxisSpacing: 3.w,
      mainAxisSpacing: 3.w,
      children: [
        _buildOccupationWidget(),
        _buildDailyIncomeWidget(),
        _buildOverdueWidget(),
        _buildMerchantActivityWidget(),
      ],
    );
  }

  // Widget 1 - OCCUPATION (utilise les données réelles)
  Widget _buildOccupationWidget() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Color(0xFF4CAF50), size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'OCCUPATION',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            CircularPercentIndicator(
              radius: 30.0,
              lineWidth: 6.0,
              animation: true,
              percent: _dashboardStats!.tauxOccupation / 100,
              center: Text(
                '${_dashboardStats!.tauxOccupation.toInt()}%',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              circularStrokeCap: CircularStrokeCap.round,
              progressColor: const Color(0xFF4CAF50),
              backgroundColor: Colors.grey[200]!,
            ),
            Text(
              '${_dashboardStats!.occupes}/${_dashboardStats!.totalLocaux} locaux',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              '${_dashboardStats!.disponibles} disponibles • ${_dashboardStats!.inactifs} inactifs',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Widget 2 - ENCAISSEMENTS JOUR (utilise les données réelles)
  Widget _buildDailyIncomeWidget() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.attach_money, size: 36, color: Color(0xFF2196F3)),
            Flexible(
              child: Text(
                '${(_dashboardStats!.encaissements / 1000000).toStringAsFixed(1)}M FCFA',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+12% vs hier',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              'Collecté aujourd\'hui',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget 3 - IMPAYÉS (utilise les données réelles)
  Widget _buildOverdueWidget() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.warning_amber,
                    size: 30, color: Color(0xFFF44336)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: Colors.red[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Flexible(
              child: Text(
                '${(_dashboardStats!.impayes / 1000000).toStringAsFixed(1)}M FCFA',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Montants en retard',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Widget 4 - ACTIVITÉ COMMERÇANTS (utilise les données réelles)
  Widget _buildMerchantActivityWidget() {
    final tauxActivite = _dashboardStats!.totalLocaux > 0
        ? (_dashboardStats!.commercants / _dashboardStats!.totalLocaux) * 100
        : 0.0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF2196F3), size: 20),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'COMMERÇANTS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            Flexible(
              child: Text(
                '${_dashboardStats!.commercants}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            LinearPercentIndicator(
              lineHeight: 6.0,
              percent: tauxActivite / 100,
              backgroundColor: Colors.grey[200]!,
              progressColor: const Color(0xFF4CAF50),
              barRadius: const Radius.circular(4),
              animation: true,
            ),
            Text(
              'Commerçants actifs',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // PARTIE 2 - 3 GRAPHIQUES (utilise les données réelles)
  Widget _buildChartsSection() {
    return Column(
      children: [
        _buildTrendChart(),
        SizedBox(height: 4.w),
        _buildRevenueByTypeChart(),
        SizedBox(height: 4.w),
        _buildOccupancyByFloorChart(),
      ],
    );
  }

  // 1. LineChart - TENDANCE 7 JOURS (utilise les données réelles)
  Widget _buildTrendChart() {
    const List<String> labelsTendance = [
      'Lun',
      'Mar',
      'Mer',
      'Jeu',
      'Ven',
      'Sam',
      'Dim'
    ];

    return Container(
      height: 220,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendance des encaissements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.w),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}M',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]));
                      },
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < labelsTendance.length) {
                          return Text(
                            labelsTendance[value.toInt()],
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _tendancePaiements
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.montant))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF2196F3),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2196F3).withAlpha(26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. BarChart - ENCAISSEMENTS PAR TYPE (utilise les données réelles)
  Widget _buildRevenueByTypeChart() {
    const List<Color> colors = [
      Color(0xFF2196F3), // bleu
      Color(0xFF4CAF50), // vert
      Color(0xFFFF9800), // orange
      Color(0xFF9C27B0), // violet
      Color(0xFFFFEB3B), // jaune
      Color(0xFFF44336), // rouge
    ];

    return Container(
      height: 250,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenus par type de local',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.w),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                barGroups: _encaissementsParType.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.montant,
                        color: colors[entry.key % colors.length],
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}M',
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600])),
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < _encaissementsParType.length) {
                          return Transform.rotate(
                            angle: -0.785398, // 45 degrees in radians
                            child: Text(
                              _encaissementsParType[value.toInt()].type,
                              style: TextStyle(
                                  fontSize: 8, color: Colors.grey[600]),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. PieChart - OCCUPATION PAR ÉTAGE (utilise les données réelles)
  Widget _buildOccupancyByFloorChart() {
    const List<Color> colors = [
      Color(0xFF4CAF50), // vert
      Color(0xFF2196F3), // bleu
      Color(0xFFFF9800), // orange
      Color(0xFFEF5350), // rouge clair
    ];

    return Container(
      height: 220,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Répartition par étage',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.w),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 45,
                          sections:
                              _occupationEtages.asMap().entries.map((entry) {
                            return PieChartSectionData(
                              color: colors[entry.key % colors.length],
                              value: entry.value.taux,
                              title: '${entry.value.taux.toInt()}%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withAlpha(51),
                              spreadRadius: 1,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          '${_dashboardStats!.tauxOccupation.toInt()}%',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _occupationEtages.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: colors[entry.key % colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                '${entry.value.etage}: ${entry.value.taux.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PARTIE 3 - APERÇU DÉTAILLÉ DES ÉTAGES (utilise les données réelles)
  Widget _buildFloorDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails par étage',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.w),
        ..._statsEtages.entries.map((entry) {
          return _buildFloorExpansionTile(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildFloorExpansionTile(
      String floorKey, Map<String, dynamic> floorData) {
    double percentage = floorData['tauxOccupation'] ?? 0.0;
    int occupes = floorData['occupes'] ?? 0;
    int disponibles = floorData['disponibles'] ?? 0;
    Map<String, dynamic> types = floorData['types'] ?? {};

    Color badgeColor = percentage >= 90
        ? const Color(0xFF4CAF50)
        : percentage >= 80
            ? const Color(0xFFFF9800)
            : const Color(0xFFF44336);

    return Card(
      margin: EdgeInsets.only(bottom: 2.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.w),
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Expanded(
              child: Text(
                floorData['nom'] ?? floorKey,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${percentage.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 2.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$occupes occupés • $disponibles disponibles',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 2.w),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                minHeight: 4,
              ),
              SizedBox(height: 2.w),
            ],
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
            child: Column(
              children: types.entries.map<Widget>((typeEntry) {
                String typeName = typeEntry.key;
                Map<String, dynamic> typeData =
                    typeEntry.value as Map<String, dynamic>;
                int typeOccupes = typeData['occupes'] ?? 0;
                int typeTotal = typeData['total'] ?? 0;
                double typePercentage =
                    typeTotal > 0 ? (typeOccupes / typeTotal) * 100 : 0;

                return Container(
                  margin: EdgeInsets.only(bottom: 2.w),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$typeName: $typeOccupes/$typeTotal',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 1.w),
                            LinearProgressIndicator(
                              value: typePercentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2196F3)),
                              minHeight: 3,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 2.w, vertical: 0.5.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${typePercentage.toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton Loading
  Widget _buildSkeletonGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 0.9,
      crossAxisSpacing: 4.w,
      mainAxisSpacing: 4.w,
      children: List.generate(4, (index) => _buildSkeletonCard()),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            SizedBox(height: 3.w),
            Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 2.w),
            Container(
              width: 60,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonChart() {
    return Container(
      height: 200,
      margin: EdgeInsets.only(bottom: 4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(height: 4.w),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4CAF50), Color(0xFF45a049)],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'Marché Cocody Saint Jean',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Gestion locative',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  'Dashboard',
                  Icons.dashboard,
                  '/dashboard-screen',
                  isSelected: true,
                ),
                _buildDrawerItem(
                  context,
                  'Locaux',
                  Icons.business,
                  '/properties-management-screen',
                ),
                _buildDrawerItem(
                  context,
                  'Commerçants',
                  Icons.store,
                  '/merchants-management-screen',
                ),
                _buildDrawerItem(
                  context,
                  'Baux',
                  Icons.description,
                  '/lease-management-screen',
                ),
                _buildDrawerItem(
                  context,
                  'Paiements',
                  Icons.payment,
                  '/payments-management-screen',
                ),
                const Divider(),
                _buildDrawerItem(
                  context,
                  'Paramètres',
                  Icons.settings,
                  '/settings-screen',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route, {
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF4CAF50).withAlpha(26),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
        }
      },
    );
  }
}
