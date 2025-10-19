import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CustomAppBarVariant {
  standard,
  withSearch,
  withActions,
  minimal,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final CustomAppBarVariant variant;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final VoidCallback? onSearchPressed;
  final String? searchHint;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.variant = CustomAppBarVariant.standard,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onSearchPressed,
    this.searchHint,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (variant) {
      case CustomAppBarVariant.standard:
        return _buildStandardAppBar(context, theme, colorScheme);
      case CustomAppBarVariant.withSearch:
        return _buildSearchAppBar(context, theme, colorScheme);
      case CustomAppBarVariant.withActions:
        return _buildActionsAppBar(context, theme, colorScheme);
      case CustomAppBarVariant.minimal:
        return _buildMinimalAppBar(context, theme, colorScheme);
    }
  }

  Widget _buildStandardAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
      ),
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation ?? 1.0,
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: _buildDefaultActions(context),
    );
  }

  Widget _buildSearchAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
      ),
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation ?? 1.0,
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchPressed ?? () => _showSearchBottomSheet(context),
          tooltip: 'Search properties',
        ),
        ..._buildDefaultActions(context),
      ],
    );
  }

  Widget _buildActionsAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: foregroundColor ?? colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
      ),
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation ?? 1.0,
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => _showFilterBottomSheet(context),
          tooltip: 'Filter properties',
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: () => _showSortBottomSheet(context),
          tooltip: 'Sort properties',
        ),
        ..._buildDefaultActions(context),
      ],
    );
  }

  Widget _buildMinimalAppBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return AppBar(
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: foregroundColor ?? colorScheme.onSurface,
          letterSpacing: 0.15,
        ),
      ),
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      elevation: elevation ?? 0.0,
      centerTitle: centerTitle,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    if (actions != null) return actions!;

    return [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => _navigateToNotifications(context),
        tooltip: 'Notifications',
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) => _handleMenuSelection(context, value),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'settings',
            child: ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'help',
            child: ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Help'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ];
  }

  void _showSearchBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: searchHint ?? 'Search properties, tenants...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Text(
                    'Recent Searches',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildSearchSuggestion(context, 'Available properties'),
                  _buildSearchSuggestion(context, 'Overdue payments'),
                  _buildSearchSuggestion(context, 'Lease renewals'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filter Properties',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterOption(context, 'Available', true),
                  _buildFilterOption(context, 'Occupied', false),
                  _buildFilterOption(context, 'Under Maintenance', false),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sort Properties',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSortOption(context, 'Property Name', true),
                  _buildSortOption(context, 'Rent Amount', false),
                  _buildSortOption(context, 'Lease End Date', false),
                  _buildSortOption(context, 'Status', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSuggestion(BuildContext context, String suggestion) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(suggestion),
      onTap: () => Navigator.pop(context),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFilterOption(
      BuildContext context, String option, bool isSelected) {
    return CheckboxListTile(
      title: Text(option),
      value: isSelected,
      onChanged: (value) {},
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSortOption(
      BuildContext context, String option, bool isSelected) {
    return RadioListTile<String>(
      title: Text(option),
      value: option,
      groupValue: isSelected ? option : null,
      onChanged: (value) => Navigator.pop(context),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _navigateToNotifications(BuildContext context) {
    // Navigate to notifications screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications feature coming soon')),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'settings':
        Navigator.pushNamed(context, '/settings-screen');
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help feature coming soon')),
        );
        break;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
