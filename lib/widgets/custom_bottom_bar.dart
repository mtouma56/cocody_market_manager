import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (widget.variant) {
      case CustomBottomBarVariant.standard:
        return _buildStandardBottomBar(context, theme, colorScheme);
      case CustomBottomBarVariant.floating:
        return _buildFloatingBottomBar(context, theme, colorScheme);
      case CustomBottomBarVariant.minimal:
        return _buildMinimalBottomBar(context, theme, colorScheme);
    }
  }

  Widget _buildStandardBottomBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: _handleTap,
      backgroundColor: widget.backgroundColor ?? colorScheme.surface,
      selectedItemColor: widget.selectedItemColor ?? colorScheme.secondary,
      unselectedItemColor:
          widget.unselectedItemColor ?? colorScheme.onSurfaceVariant,
      elevation: widget.elevation ?? 3.0,
      selectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      items: _navItems
          .map((item) => BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.selectedIcon),
                label: item.label,
                tooltip: item.label,
              ))
          .toList(),
    );
  }

  Widget _buildFloatingBottomBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _handleTap,
          backgroundColor: Colors.transparent,
          selectedItemColor: widget.selectedItemColor ?? colorScheme.secondary,
          unselectedItemColor:
              widget.unselectedItemColor ?? colorScheme.onSurfaceVariant,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.roboto(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          items: _navItems
              .map((item) => BottomNavigationBarItem(
                    icon: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(item.icon, size: 22),
                    ),
                    activeIcon: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.selectedIcon, size: 22),
                    ),
                    label: item.label,
                    tooltip: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildMinimalBottomBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
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

    // Navigate to the corresponding route
    final route = _navItems[index].route;
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      (route) => false,
    );
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
