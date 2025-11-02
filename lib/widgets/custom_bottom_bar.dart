import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_routes.dart';

enum CustomBottomBarVariant {
  standard,
  floating,
  minimal,
}

class CustomBottomBar extends StatefulWidget {
  final CustomBottomBarVariant variant;
  final int currentIndex;
  final ValueChanged<int>? onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? elevation;

  const CustomBottomBar({
    super.key,
    this.variant = CustomBottomBarVariant.standard,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(CustomBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _currentIndex = widget.currentIndex;
    }
  }

  final List<_BottomNavItem> _navItems = [
    _BottomNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard-screen',
    ),
    _BottomNavItem(
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      label: 'Properties',
      route: '/properties-management-screen',
    ),
    _BottomNavItem(
      icon: Icons.store_outlined,
      selectedIcon: Icons.store,
      label: 'Merchants',
      route: '/merchants-management-screen',
    ),
    _BottomNavItem(
      icon: Icons.description_outlined,
      selectedIcon: Icons.description,
      label: 'Leases',
      route: '/lease-management-screen',
    ),
    _BottomNavItem(
      icon: Icons.payment_outlined,
      selectedIcon: Icons.payment,
      label: 'Payments',
      route: '/payments-management-screen',
    ),
    _BottomNavItem(
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
      label: 'Reports',
      route: '/reports-screen',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (widget.variant) {
      case CustomBottomBarVariant.standard:
        return _buildModernNavigationBar(
          context,
          colorScheme,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        );
      case CustomBottomBarVariant.floating:
        return _buildModernNavigationBar(
          context,
          colorScheme,
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 28),
        );
      case CustomBottomBarVariant.minimal:
        return _buildMinimalBottomBar(context, colorScheme);
    }
  }

  Widget _buildModernNavigationBar(
    BuildContext context,
    ColorScheme colorScheme, {
    EdgeInsetsGeometry margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
  }) {
    final surfaceColor =
        (widget.backgroundColor ?? colorScheme.surface).withValues(alpha: 0.92);
    final selectedColor = widget.selectedItemColor ?? colorScheme.primary;
    final unselectedColor = widget.unselectedItemColor ??
        colorScheme.onSurfaceVariant.withValues(alpha: 0.75);

    return Padding(
      padding: margin,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 72,
                indicatorColor: selectedColor.withValues(alpha: 0.14),
                indicatorShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? selectedColor : unselectedColor,
                  );
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  final isSelected = states.contains(WidgetState.selected);
                  return IconThemeData(
                    color: isSelected ? selectedColor : unselectedColor,
                    size: isSelected ? 26 : 24,
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                backgroundColor: surfaceColor,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                animationDuration: const Duration(milliseconds: 420),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: [
                  for (final item in _navItems)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    )
                ],
                onDestinationSelected: _handleTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalBottomBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == _currentIndex;

          return Expanded(
            child: InkWell(
              onTap: () => _handleTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected
                          ? (widget.selectedItemColor ?? colorScheme.secondary)
                          : (widget.unselectedItemColor ??
                              colorScheme.onSurfaceVariant),
                      size: 24,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.w400,
                        color: isSelected
                            ? (widget.selectedItemColor ??
                                colorScheme.secondary)
                            : (widget.unselectedItemColor ??
                                colorScheme.onSurfaceVariant),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _handleTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    // Call the provided onTap callback
    widget.onTap?.call(index);

    HapticFeedback.selectionClick();

    // Navigate to the corresponding route with a soft transition
    final routeName = _navItems[index].route;
    final builder = AppRoutes.routes[routeName];

    if (builder != null) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          settings: RouteSettings(name: routeName),
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return builder(context);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        ),
        (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        routeName,
        (route) => false,
      );
    }
  }
}

class _BottomNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const _BottomNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}
