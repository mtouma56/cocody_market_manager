import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../models/dashboard_stats.dart';
import '../../routes/app_routes.dart';
import '../../services/bail_validation_service.dart';
import '../../services/cache_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/notification_service.dart';
import '../../services/paiements_service.dart';
import '../../services/rapport_service.dart';
import '../../services/sync_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/animated/animated_dashboard_hero.dart';
import '../../widgets/animated/animated_drawer_tile.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/notification_badge.dart';
import '../documents_screen/documents_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DashboardService _dashboardService = DashboardService();
  final PaiementsService _paiementsService = PaiementsService();
  final RapportService _rapportService = RapportService();
  final _validationService = BailValidationService();

  // Animation controllers for modern micro-animations
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Nouveaux services pour mode hors ligne
  final _connectivity = ConnectivityService();
  final _cache = CacheService();
  final _sync = SyncService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  // Data from Supabase
  DashboardStats? _dashboardStats;
  List<OccupationEtage> _occupationEtages = [];
  List<TendanceData> _tendancePaiements = [];
  List<EncaissementType> _encaissementsParType = [];
  Map<String, Map<String, dynamic>> _statsEtages = {};

  List<FlSpot> get _trendSpots => _tendancePaiements
      .asMap()
      .entries
      .map((entry) => FlSpot(entry.key.toDouble(), entry.value.montant))
      .toList();

  List<String> get _trendLabels => _tendancePaiements.map((data) {
        final raw = DateFormat('EEE', 'fr_FR').format(data.date);
        final formatted = toBeginningOfSentenceCase(raw);
        if (formatted == null) {
          return raw;
        }
        return formatted;
      }).toList();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeOfflineMode();
    _loadData();
    _verifierConflits();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Initialise le mode hors ligne
  Future<void> _initializeOfflineMode() async {
    try {
      await _cache.initialize();
      await _connectivity.initialize();
      _sync.initialize();

      if (_connectivity.isOnline) {
        _sync.syncAll();
      }

      print('✅ Mode hors ligne initialisé');
    } catch (e) {
      print('❌ Erreur initialisation mode hors ligne: $e');
    }
  }

  Future<void> _verifierConflits() async {
    try {
      final conflits = await _validationService.getConflits();

      if (conflits.isNotEmpty && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: AppTheme.warning, size: 32),
                SizedBox(width: 12),
                Text('Alerte système'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⚠️ ${conflits.length} locaux ont plusieurs baux actifs.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Ceci est une erreur critique qui nécessite une intervention immédiate.',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 8),
                ...conflits.map(
                  (c) => Text(
                    '• ${c['local_numero']} : ${c['nb_baux_actifs']} baux actifs',
                    style: TextStyle(fontSize: 12, color: AppTheme.error),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _resoudreConflitsAutomatiquement();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warning,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Résoudre automatiquement'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Ignorer pour maintenant'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur vérification conflits: $e');
    }
  }

  Future<void> _resoudreConflitsAutomatiquement() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(24),
            margin: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.elevatedCardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 20),
                Text(
                  'Résolution des conflits en cours...',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      );

      final resolutions = await _validationService.resoudreConflits();
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.success, size: 32),
              SizedBox(width: 12),
              Text('Conflits résolus'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ ${resolutions.length} conflits ont été résolus automatiquement.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              if (resolutions.isNotEmpty) ...[
                Text('Détails des résolutions :'),
                SizedBox(height: 8),
                ...resolutions.map(
                  (r) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.success.withAlpha(77),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Local ${r['local_numero']}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('Bail conservé: ${r['bail_garde']}'),
                        if (r['baux_resilies'] != null &&
                            r['baux_resilies'].isNotEmpty)
                          Text(
                            'Baux résiliés: ${(r['baux_resilies'] as List).join(', ')}',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Impossible de résoudre les conflits: $e');
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (mounted) {
        setState(() {
          if (silent) {
            _isRefreshing = true;
          } else {
            _isLoading = true;
          }
          _errorMessage = null;
        });
      }

      // OPTIMISATION : Chargement séquentiel avec délai et timeout pour éviter "Connection reset by peer"
      // Chaque requête a un timeout de 30 secondes et les erreurs sont gérées individuellement

      // 1. Charger getDashboardStats() en premier (données essentielles)
      DashboardStats? dashboardStats;
      try {
        dashboardStats = await _dashboardService.getDashboardStats()
            .timeout(Duration(seconds: 30));
        print('✅ Dashboard stats chargées');
      } catch (e) {
        print('❌ Erreur dashboard stats: $e');
        // Continue même en cas d'erreur
      }

      // Délai de 200ms
      await Future.delayed(Duration(milliseconds: 200));

      // 2. Charger getOccupationParEtage()
      List<OccupationEtage> occupationEtages = [];
      try {
        occupationEtages = await _dashboardService.getOccupationParEtage()
            .timeout(Duration(seconds: 30));
        print('✅ Occupation par étage chargée');
      } catch (e) {
        print('❌ Erreur occupation par étage: $e');
      }

      // Délai de 200ms
      await Future.delayed(Duration(milliseconds: 200));

      // 3. Charger getTendancePaiements()
      List<TendanceData> tendancePaiements = [];
      try {
        tendancePaiements = await _dashboardService.getTendancePaiements(7)
            .timeout(Duration(seconds: 30));
        print('✅ Tendance paiements chargée');
      } catch (e) {
        print('❌ Erreur tendance paiements: $e');
      }

      // Délai de 200ms
      await Future.delayed(Duration(milliseconds: 200));

      // 4. Charger getEncaissementsParType()
      List<EncaissementType> encaissementsParType = [];
      try {
        encaissementsParType = await _dashboardService.getEncaissementsParType()
            .timeout(Duration(seconds: 30));
        print('✅ Encaissements par type chargés');
      } catch (e) {
        print('❌ Erreur encaissements par type: $e');
      }

      // Délai de 200ms
      await Future.delayed(Duration(milliseconds: 200));

      // 5. Charger getStatsDetailleesEtages()
      Map<String, Map<String, dynamic>> statsEtages = {};
      try {
        statsEtages = await _dashboardService.getStatsDetailleesEtages()
            .timeout(Duration(seconds: 30));
        print('✅ Stats détaillées étages chargées');
      } catch (e) {
        print('❌ Erreur stats détaillées étages: $e');
      }

      // Mettre à jour l'état avec toutes les données (même partielles)
      if (mounted) {
        setState(() {
          _dashboardStats = dashboardStats;
          _occupationEtages = occupationEtages;
          _tendancePaiements = tendancePaiements;
          _encaissementsParType = encaissementsParType;
          _statsEtages = statsEtages;
          if (silent) {
            _isRefreshing = false;
          } else {
            _isLoading = false;
          }
        });
      }

      // Restart animations after each refresh to keep the dashboard lively
      _fadeController.forward(from: 0);
      _scaleController.forward(from: 0);
    } catch (error) {
      print('❌ Erreur globale lors du chargement: $error');
      if (mounted) {
        setState(() {
          if (silent) {
            _isRefreshing = false;
          } else {
            _isLoading = false;
          }
          _errorMessage = 'Erreur lors du chargement des données: $error';
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: _buildModernAppBar(),
      drawer: _buildModernDrawer(context),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildDashboardContent(),
      bottomNavigationBar: const CustomBottomBar(
        currentIndex: 0,
        variant: CustomBottomBarVariant.standard,
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return PreferredSize(
      preferredSize: Size.fromHeight(120),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.appBarGradient,
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.menu, color: AppTheme.surface, size: 28),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Dashboard',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: AppTheme.surface),
                      ),
                      Text(
                        'Vue d\'ensemble du marché',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.surface.withAlpha(204),
                            ),
                      ),
                    ],
                  ),
                ),
                NotificationBadge(),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.auto_fix_high, color: AppTheme.surface),
                  tooltip: 'Générer paiements du mois',
                  onPressed: _genererPaiementsMois,
                ),
                IconButton(
                  icon: Icon(Icons.sync, color: AppTheme.surface),
                  tooltip: 'Synchroniser manuellement',
                  onPressed: _syncManuelle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: EdgeInsets.only(top: 120),
      child: Column(
        children: [
          SizedBox(height: 60),
          CircularProgressIndicator(color: AppTheme.primary),
          SizedBox(height: 24),
          Text(
            'Chargement des données...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      margin: EdgeInsets.only(top: 120),
      padding: EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.error.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 64, color: AppTheme.error),
            ),
            SizedBox(height: 24),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.surface,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          displacement: 56,
          strokeWidth: 2.4,
          onRefresh: _handleRefresh,
          child: Container(
            margin: const EdgeInsets.only(top: 120),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _isRefreshing
                        ? Container(
                            key: const ValueKey('refreshing'),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              color: Theme.of(context).colorScheme.primary,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.35),
                            ),
                          )
                        : const SizedBox(key: ValueKey('idle'), height: 0),
                  ),
                  if (_dashboardStats != null) ...[
                    AnimatedDashboardHero(
                      stats: _dashboardStats!,
                      trendSpots: _trendSpots,
                      trendLabels: _trendLabels,
                    ),
                    const SizedBox(height: 24),
                  ],
                  _buildMainStatsGrid(),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 24),
                  _buildChartsSection(),
                  const SizedBox(height: 24),
                  _buildFloorDetailsSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.0,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildOccupationCard(),
        _buildDailyIncomeCard(),
        _buildOverdueCard(),
        _buildPendingPaymentsCard(),
      ],
    );
  }

  // Modern occupation card with glassmorphism and animations
  Widget _buildOccupationCard() {
    if (_dashboardStats == null) return _buildSkeletonCard();

    return AnimatedContainer(
      duration: Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, AppTheme.surface.withAlpha(242)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOccupationDetails(),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: AppTheme.success,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'OCCUPATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularPercentIndicator(
                        radius: 50.0,
                        lineWidth: 8.0,
                        animation: true,
                        animationDuration: 1200,
                        percent: _dashboardStats!.tauxOccupation / 100,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '293',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.success,
                              ),
                            ),
                            Text(
                              'locaux occupés',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: AppTheme.success,
                        backgroundColor: AppTheme.success.withAlpha(26),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern daily income card with trend indicator
  Widget _buildDailyIncomeCard() {
    if (_dashboardStats == null) return _buildSkeletonCard();

    return AnimatedContainer(
      duration: Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.surface, AppTheme.surface.withAlpha(242)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _genererRapportCollecteAujourdhui(),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0x1A10B981),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.attach_money,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.picture_as_pdf, size: 16, color: AppTheme.error),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'COLLECTE AUJOURD\'HUI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${(_dashboardStats!.encaissements / 1000000).toStringAsFixed(1)}M',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'FCFA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 12,
                            color: AppTheme.success,
                          ),
                          Text(
                            '+12%',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern overdue payments card with urgent styling
  Widget _buildOverdueCard() {
    if (_dashboardStats == null) return _buildSkeletonCard();

    return AnimatedContainer(
      duration: Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _genererRapportMontantEnRetard(),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'URGENT',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.surface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.picture_as_pdf, size: 16, color: Colors.pink),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.pink, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'IMPAYÉS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${(_dashboardStats!.impayes / 1000000).toStringAsFixed(1)}M',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'FCFA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'en retard',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern pending payments card
  Widget _buildPendingPaymentsCard() {
    if (_dashboardStats == null) return _buildSkeletonCard();

    return AnimatedContainer(
      duration: Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _genererRapportPaiementsEnAttente(),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.pending_actions,
                        color: AppTheme.warning,
                        size: 20,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.picture_as_pdf,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'PAIEMENTS EN ATTENTE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_dashboardStats!.commercants}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
                ),
                LinearPercentIndicator(
                  lineHeight: 6.0,
                  percent: (_dashboardStats!.commercants / 100).clamp(0.0, 1.0),
                  backgroundColor: AppTheme.warning.withAlpha(51),
                  progressColor: AppTheme.warning,
                  barRadius: Radius.circular(4),
                  animation: true,
                  animationDuration: 1000,
                ),
                SizedBox(height: 4),
                Text(
                  'paiements',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actions rapides',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () => _showQuickActionsBottomSheet(context),
              child: Text('Voir tout'),
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildQuickActionCard(
              icon: Icons.person_add,
              label: 'Nouveau\nCommerçant',
              color: AppTheme.secondary,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.merchantsManagementScreen,
              ),
            ),
            _buildQuickActionCard(
              icon: Icons.receipt_long,
              label: 'Nouveau\nPaiement',
              color: AppTheme.success,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.addPaymentFormScreen,
              ),
            ),
            _buildQuickActionCard(
              icon: Icons.folder,
              label: 'Documents',
              color: AppTheme.warning,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DocumentsScreen(),
                ),
              ),
            ),
            _buildQuickActionCard(
              icon: Icons.assignment,
              label: 'Nouveau\nBail',
              color: AppTheme.primary,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.addLeaseFormScreen,
              ),
            ),
            _buildQuickActionCard(
              icon: Icons.analytics,
              label: 'Statistiques',
              color: Colors.indigo,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.statisticsScreen),
            ),
            _buildQuickActionCard(
              icon: Icons.description,
              label: 'Rapports',
              color: Colors.teal,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.reportsScreen),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.modernCardShadow,
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// NOUVELLE MÉTHODE - Synchronisation manuelle
  Future<void> _syncManuelle() async {
    if (!_connectivity.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de synchroniser hors ligne'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    if (_sync.isSyncing) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Synchronisation déjà en cours')));
      return;
    }

    await _sync.syncAll();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Synchronisation terminée'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  // NOUVELLE MÉTHODE - Génération des paiements du mois avec vérification connexion
  Future<void> _genererPaiementsMois() async {
    if (!_connectivity.isOnline) {
      _showOfflineDialog();
      return;
    }

    final confirme = await _showConfirmationDialog(
      'Générer paiements',
      'Génération des paiements pour les baux actifs uniquement.\n\n'
          'Les locaux sans bail ou avec bail résilié/expiré ne seront pas inclus.\n\n'
          'Continuer ?',
    );

    if (confirme != true) return;

    try {
      _showLoadingDialog('Génération des paiements en cours...');

      final now = DateTime.now();
      final moisConcerne =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      final paiements = await _paiementsService.genererPaiementsMois(
        moisConcerne,
      );

      Navigator.pop(context);

      _showSuccessDialog(
        'Génération terminée',
        '${paiements.length} paiements générés\npour les baux actifs uniquement.',
      );

      _loadData();
      if (_connectivity.isOnline) {
        await _sync.syncAll();
      }

      try {
        await NotificationService().rafraichirCompteurs();
      } catch (e) {
        print('❌ Erreur rafraîchissement notifications: $e');
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Erreur génération : $e');
    }
  }

  // Dialogs and utilitaires
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: EdgeInsets.all(24),
            margin: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.elevatedCardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.primary),
                SizedBox(height: 20),
                Text(
                  message,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info_rounded, color: AppTheme.secondary),
              SizedBox(width: 8),
              Text('Information'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.success, size: 28),
            SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppTheme.error, size: 28),
            SizedBox(width: 8),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOfflineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Mode hors ligne'),
          ],
        ),
        content: Text(
          'Cette action nécessite une connexion internet.\n\n'
          'Vous pouvez consulter les données en cache, mais les modifications '
          'ne seront possibles qu\'une fois reconnecté.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showOccupationDetails() {
    // Navigate to properties screen or show details
    Navigator.pushNamed(context, AppRoutes.propertiesManagementScreen);
  }

  void _showQuickActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLabel,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Actions rapides',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildQuickActionCard(
                    icon: Icons.person_add,
                    label: 'Nouveau\nCommerçant',
                    color: AppTheme.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.merchantsManagementScreen,
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.receipt_long,
                    label: 'Nouveau\nPaiement',
                    color: AppTheme.success,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addPaymentFormScreen,
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.folder,
                    label: 'Documents',
                    color: AppTheme.warning,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DocumentsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.assignment,
                    label: 'Nouveau\nBail',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRoutes.addLeaseFormScreen,
                      );
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.analytics,
                    label: 'Statistiques',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.statisticsScreen);
                    },
                  ),
                  _buildQuickActionCard(
                    icon: Icons.description,
                    label: 'Rapports',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.reportsScreen);
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // PARTIE 2 - 3 GRAPHIQUES (utilise les données réelles)
  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyses et tendances',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16),
        _buildTrendChart(),
        SizedBox(height: 16),
        _buildRevenueByTypeChart(),
        SizedBox(height: 16),
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
      'Dim',
    ];

    // Check if data is empty
    bool hasData = _tendancePaiements.isNotEmpty;

    return Container(
      height: 220,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tendance des encaissements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Expanded(
            child: hasData
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}M',
                                style: Theme.of(context).textTheme.labelSmall,
                              );
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
                                  style: Theme.of(context).textTheme.labelSmall,
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _tendancePaiements
                              .asMap()
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.toDouble(),
                                  e.value.montant,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          color: AppTheme.secondary,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.secondary.withAlpha(26),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Aucune donnée historique',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
      AppTheme.secondary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.primary,
      Color(0xFFFFEB3B),
      AppTheme.error,
    ];

    // Check if data is empty
    bool hasData = _encaissementsParType.isNotEmpty;

    return Container(
      height: 250,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenus par type de local',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Expanded(
            child: hasData
                ? BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups:
                          _encaissementsParType.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: entry.value.montant,
                              color: colors[entry.key % colors.length],
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
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
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            reservedSize: 30,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() <
                                      _encaissementsParType.length) {
                                return Transform.rotate(
                                  angle: -0.785398,
                                  child: Text(
                                    _encaissementsParType[value.toInt()].type,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  )
                : Center(
                    child: Text(
                      'Aucune donnée historique',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
      AppTheme.success,
      AppTheme.secondary,
      AppTheme.warning,
      AppTheme.error,
    ];

    return Container(
      height: 240,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withAlpha(51),
            blurRadius: 8,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition par étage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections:
                              _occupationEtages.asMap().entries.map((entry) {
                            return PieChartSectionData(
                              color: colors[entry.key % colors.length],
                              value: entry.value.taux,
                              title: '',
                              radius: 45,
                            );
                          }).toList(),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor.withAlpha(51),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_dashboardStats?.tauxOccupation.toInt() ?? 0}%',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                  ),
                            ),
                            Text(
                              'Total',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _occupationEtages.asMap().entries.map((entry) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.textLabel.withAlpha(26),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colors[entry.key % colors.length],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value.etage,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${entry.value.taux.toInt()}%',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              colors[entry.key % colors.length],
                                        ),
                                  ),
                                ],
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
        Text(
          'Détails par étage',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 16),
        ..._statsEtages.entries.map((entry) {
          return _buildModernFloorExpansionTile(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildModernFloorExpansionTile(
    String floorKey,
    Map<String, dynamic> floorData,
  ) {
    double percentage = floorData['tauxOccupation'] ?? 0.0;
    int occupes = floorData['occupes'] ?? 0;
    int disponibles = floorData['disponibles'] ?? 0;
    Map<String, dynamic> types = floorData['types'] ?? {};

    Color badgeColor = percentage >= 90
        ? AppTheme.success
        : percentage >= 80
            ? AppTheme.warning
            : AppTheme.error;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.modernCardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Expanded(
                child: Text(
                  floorData['nom'] ?? floorKey,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${percentage.toInt()}%',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$occupes occupés • $disponibles disponibles',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: badgeColor.withAlpha(51),
                  valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textLabel.withAlpha(26),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$typeName: $typeOccupes/$typeTotal',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: typePercentage / 100,
                                backgroundColor:
                                    AppTheme.secondary.withAlpha(51),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.secondary,
                                ),
                                minHeight: 4,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${typePercentage.toInt()}%',
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondary,
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
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.modernCardShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.textLabel.withAlpha(77),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            SizedBox(height: 12),
            Container(
              width: 80,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.textLabel.withAlpha(77),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context) {
    return Container(
      width: 280,
      child: Drawer(
        backgroundColor: AppTheme.surface,
        child: Column(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(gradient: AppTheme.appBarGradient),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withAlpha(51),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business,
                          color: AppTheme.surface,
                          size: 32,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Marché Cocody Saint Jean',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.surface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Gestion locative moderne',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.surface.withAlpha(204),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 16),
                children: [
                  _buildModernDrawerItem(
                    context,
                    'Dashboard',
                    Icons.dashboard_rounded,
                    AppRoutes.dashboardScreen,
                    isSelected: true,
                    description: 'Vue d\'ensemble en temps réel',
                  ),
                  _buildModernDrawerItem(
                    context,
                    'Locaux',
                    Icons.business_rounded,
                    AppRoutes.propertiesManagementScreen,
                    description: 'Gestion des propriétés et étages',
                  ),
                  _buildModernDrawerItem(
                    context,
                    'Commerçants',
                    Icons.store_rounded,
                    AppRoutes.merchantsManagementScreen,
                    description: 'Suivi des marchands actifs',
                  ),
                  _buildModernDrawerItem(
                    context,
                    'Baux',
                    Icons.description_rounded,
                    AppRoutes.leaseManagementScreen,
                    description: 'Contrats et échéances',
                  ),
                  _buildModernDrawerItem(
                    context,
                    'Paiements',
                    Icons.payment_rounded,
                    AppRoutes.paymentsManagementScreen,
                    description: 'Encaissements et relances',
                  ),
                  _buildModernDrawerItem(
                    context,
                    'Documents',
                    Icons.folder_rounded,
                    AppRoutes.documentsScreen,
                    description: 'Contrats, reçus et pièces jointes',
                  ),
                  _buildModernDrawerItem(
                    context,
                    'Rapports',
                    Icons.assessment_rounded,
                    AppRoutes.reportsScreen,
                    description: 'Exports PDF et analyses',
                  ),
                  _buildModernDrawerItem(
                    context,
                    'Statistiques',
                    Icons.analytics_rounded,
                    AppRoutes.statisticsScreen,
                    description: 'Tableaux de bord avancés',
                  ),
                  Divider(height: 32, thickness: 1),
                  _buildModernDrawerItem(
                    context,
                    'Paiements en retard',
                    Icons.warning_rounded,
                    AppRoutes.overduePaymentsScreen,
                    description: 'Suivi des impayés et actions',
                  ),
                  _buildModernDrawerItem(
                    context,
                    'Baux expirant',
                    Icons.timer_rounded,
                    AppRoutes.expiringLeasesScreen,
                    description: 'Contrats à renouveler',
                  ),
                  Divider(height: 32, thickness: 1),
                  _buildModernDrawerItem(
                    context,
                    'Paramètres',
                    Icons.settings_rounded,
                    AppRoutes.settingsScreen,
                    description: 'Personnalisation et préférences',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route, {
    bool isSelected = false,
    String? description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: AnimatedDrawerTile(
        title: title,
        icon: icon,
        isSelected: isSelected,
        description: description,
        onTap: () {
          Navigator.pop(context);
          if (!isSelected) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              route,
              (route) => false,
            );
          }
        },
      ),
    );
  }

  // Fonctions de génération de PDF pour chaque widget
  Future<void> _genererRapportCollecteAujourdhui() async {
    try {
      _showLoadingDialog(
        'Génération du rapport des paiements d\'aujourd\'hui...',
      );

      final now = DateTime.now();
      final dateDebut = DateTime(now.year, now.month, now.day);
      final dateFin = DateTime(now.year, now.month, now.day, 23, 59, 59);

      print(
        '🔍 Recherche des paiements pour le ${DateFormat('yyyy-MM-dd').format(dateDebut)}',
      );

      // Récupérer les paiements qui ont été payés aujourd'hui OU qui sont dus aujourd'hui
      final paiements = await _paiementsService.supabase
          .from('paiements')
          .select('''
          *,
          baux!inner(
            numero_contrat,
            commercants(nom, activite),
            locaux(numero)
          )
        ''')
          .or(
            'date_paiement.eq.${DateFormat('yyyy-MM-dd').format(dateDebut)},date_echeance.eq.${DateFormat('yyyy-MM-dd').format(dateDebut)}',
          )
          .inFilter('statut', ['Payé', 'Partiel'])
          .order('date_paiement', ascending: false);

      print('✅ Trouvé ${paiements.length} paiements pour aujourd\'hui');
      print(
        '📊 Détails des paiements: ${paiements.map((p) => 'ID: ${p['id']}, Statut: ${p['statut']}, Date paiement: ${p['date_paiement']}, Date échéance: ${p['date_echeance']}, Montant: ${p['montant']}').join(' | ')}',
      );

      Navigator.of(context).pop(); // Fermer le dialog de loading

      if (paiements.isEmpty) {
        // Vérifier s'il y a des paiements en base avec une requête plus large pour debug
        final allPayments = await _paiementsService.supabase
            .from('paiements')
            .select('id, statut, date_paiement, date_echeance, montant')
            .order('date_paiement', ascending: false)
            .limit(10);

        print(
          '🔍 Debug - Derniers paiements en base: ${allPayments.map((p) => 'Statut: ${p['statut']}, Date paiement: ${p['date_paiement']}, Date échéance: ${p['date_echeance']}').join(' | ')}',
        );

        _showInfoDialog(
          'Aucun paiement effectué aujourd\'hui (${DateFormat('dd/MM/yyyy').format(dateDebut)}).\n\nVérifiez s\'il y a des paiements avec les statuts "Payé" ou "Partiel" pour cette date.',
        );
        return;
      }

      await _rapportService.genererRapportPDF(
        paiements: paiements,
        dateDebut: dateDebut,
        dateFin: dateFin,
        periode: 'Aujourd\'hui (${DateFormat('dd/MM/yyyy').format(dateDebut)})',
        typeRapport: 'Paiements effectués',
      );

      _showSuccessSnackBar(
        'Rapport des paiements d\'aujourd\'hui généré avec succès ! (${paiements.length} paiements)',
      );
    } catch (e) {
      print('❌ Erreur lors de la génération du rapport: $e');
      Navigator.of(
        context,
      ).pop(); // Fermer le dialog de loading en cas d'erreur
      _showErrorSnackBar(
        'Erreur lors de la génération du rapport: ${e.toString()}',
      );
    }
  }

  Future<void> _genererRapportMontantEnRetard() async {
    try {
      _showLoadingDialog('Génération du rapport des paiements en retard...');

      // Récupérer TOUS les paiements en retard sans restriction de période
      final paiements =
          await _paiementsService.supabase.from('paiements').select('''
          *,
          baux!inner(
            numero_contrat,
            montant_loyer,
            commercants(nom, activite),
            locaux(numero)
          )
        ''').eq('statut', 'En retard').order('date_echeance', ascending: true);

      Navigator.of(context).pop(); // Fermer le dialog de loading

      if (paiements.isEmpty) {
        _showInfoDialog('Aucun paiement en retard trouvé.');
        return;
      }

      // Pour les paiements en retard, pas de restriction de date
      await _rapportService.genererRapportPDF(
        paiements: paiements,
        dateDebut: DateTime.now(), // Date factice pour l'affichage
        dateFin: DateTime.now(), // Date factice pour l'affichage
        periode: 'Toutes périodes',
        typeRapport: 'Paiements en retard',
      );

      _showSuccessSnackBar(
        'Rapport des paiements en retard généré avec succès !',
      );
    } catch (e) {
      Navigator.of(
        context,
      ).pop(); // Fermer le dialog de loading en cas d'erreur
      _showErrorSnackBar(
        'Erreur lors de la génération du rapport: ${e.toString()}',
      );
    }
  }

  Future<void> _genererRapportPaiementsEnAttente() async {
    try {
      _showLoadingDialog('Génération du rapport des paiements en attente...');

      // Récupérer TOUS les paiements en attente sans restriction de période
      final paiements =
          await _paiementsService.supabase.from('paiements').select('''
          *,
          baux!inner(
            numero_contrat,
            montant_loyer,
            commercants(nom, activite),
            locaux(numero)
          )
        ''').eq('statut', 'En attente').order('date_echeance', ascending: true);

      Navigator.of(context).pop(); // Fermer le dialog de loading

      if (paiements.isEmpty) {
        _showInfoDialog('Aucun paiement en attente trouvé.');
        return;
      }

      // Pour les paiements en attente, pas de restriction de date
      await _rapportService.genererRapportPDF(
        paiements: paiements,
        dateDebut: DateTime.now(), // Date factice pour l'affichage
        dateFin: DateTime.now(), // Date factice pour l'affichage
        periode: 'Toutes périodes',
        typeRapport: 'Paiements en attente',
      );

      _showSuccessSnackBar(
        'Rapport des paiements en attente généré avec succès !',
      );
    } catch (e) {
      Navigator.of(
        context,
      ).pop(); // Fermer le dialog de loading en cas d'erreur
      _showErrorSnackBar(
        'Erreur lors de la génération du rapport: ${e.toString()}',
      );
    }
  }
}
