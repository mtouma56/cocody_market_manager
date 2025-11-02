import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/dashboard_stats.dart';
import '../../theme/app_theme.dart';

/// Hero section used on the dashboard screen.
///
/// The widget combines subtle entrance animations with a glassmorphism
/// background to immediately surface the most important KPIs.
class AnimatedDashboardHero extends StatelessWidget {
  final DashboardStats stats;
  final List<FlSpot> trendSpots;
  final List<String> trendLabels;

  const AnimatedDashboardHero({
    super.key,
    required this.stats,
    required this.trendSpots,
    required this.trendLabels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.92, end: 1),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.gradientStart, AppTheme.gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 32,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -48,
              right: -36,
              child: _AnimatedGlowingBlob(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              bottom: -36,
              left: -42,
              child: _AnimatedGlowingBlob(
                color: AppTheme.secondary.withValues(alpha: 0.18),
                reverse: true,
                size: 220,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.auto_graph_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vue globale',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Synchronisée avec Supabase en temps réel',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _HeroMetric(
                        icon: Icons.business_center,
                        label: 'Locaux occupés',
                        value: '${stats.occupes}/${stats.totalLocaux}',
                      ),
                      _HeroMetric(
                        icon: Icons.people_alt_rounded,
                        label: 'Commerçants actifs',
                        value: '${stats.commercantsActifs}',
                      ),
                      _HeroMetric(
                        icon: Icons.payments_rounded,
                        label: 'Encaissements (mois)',
                        value: currencyFormat.format(stats.encaissementsMois),
                      ),
                      _HeroMetric(
                        icon: Icons.warning_amber_rounded,
                        label: 'Impays',
                        value: currencyFormat.format(stats.impayes),
                        tone: _HeroMetricTone.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _HeroChart(
                    trendSpots: trendSpots,
                    trendLabels: trendLabels,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _HeroMetricTone { normal, warning }

class _HeroMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _HeroMetricTone tone;

  const _HeroMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.tone = _HeroMetricTone.normal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone == _HeroMetricTone.warning
        ? Colors.amberAccent.shade200
        : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _HeroChart extends StatelessWidget {
  final List<FlSpot> trendSpots;
  final List<String> trendLabels;

  const _HeroChart({
    required this.trendSpots,
    required this.trendLabels,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = trendSpots.isNotEmpty;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(16),
      child: hasData
          ? LineChart(
              LineChartData(
                backgroundColor: Colors.transparent,
                minY: 0,
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value <= 0) return const SizedBox.shrink();
                        return Text(
                          NumberFormat.compactCurrency(
                            locale: 'fr_FR',
                            symbol: 'FCFA',
                            decimalDigits: 0,
                          ).format(value),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= trendLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            trendLabels[index],
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        Colors.black.withValues(alpha: 0.65),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((touchedSpot) {
                        final index = touchedSpot.spotIndex;
                        final label = index < trendLabels.length
                            ? trendLabels[index]
                            : '';
                        final value = NumberFormat.currency(
                          locale: 'fr_FR',
                          symbol: 'FCFA',
                          decimalDigits: 0,
                        ).format(touchedSpot.y);
                        return LineTooltipItem(
                          '$label\n$value',
                          theme.textTheme.labelLarge!.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: trendSpots,
                    isCurved: true,
                    barWidth: 3,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        Colors.white.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor:
                              AppTheme.secondary.withValues(alpha: 0.6),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Text(
                'Pas encore de tendance sur les encaissements',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
    );
  }
}

class _AnimatedGlowingBlob extends StatefulWidget {
  final Color color;
  final bool reverse;
  final double size;

  const _AnimatedGlowingBlob({
    required this.color,
    this.reverse = false,
    this.size = 180,
  });

  @override
  State<_AnimatedGlowingBlob> createState() => _AnimatedGlowingBlobState();
}

class _AnimatedGlowingBlobState extends State<_AnimatedGlowingBlob>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = widget.reverse
            ? 1 - Curves.easeInOut.transform(_controller.value)
            : Curves.easeInOut.transform(_controller.value);
        final scale = 0.9 + (progress * 0.1);
        final opacity = 0.4 + (progress * 0.2);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color,
              blurRadius: 46,
              spreadRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
