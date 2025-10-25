import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum CustomAppBarVariant {
  standard,
  withSearch,
  withActions,
  minimal,
}

enum SortOption {
  propertyNumber,
  propertyType,
  floor,
  status,
}

enum StatusFilter {
  all,
  available,
  occupied,
  maintenance,
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

  // New functional callbacks
  final Function(List<StatusFilter>)? onFilterChanged;
  final Function(SortOption, bool)? onSortChanged;
  final List<StatusFilter>? currentFilters;
  final SortOption? currentSortOption;
  final bool? currentSortAscending;

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
    this.onFilterChanged,
    this.onSortChanged,
    this.currentFilters,
    this.currentSortOption,
    this.currentSortAscending,
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
          tooltip: 'Rechercher locaux',
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
          icon: Icon(
            Icons.filter_list,
            color: (currentFilters?.isNotEmpty == true)
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
          onPressed: () => _showFilterBottomSheet(context),
          tooltip: 'Filtrer les locaux',
        ),
        IconButton(
          icon: Icon(
            Icons.sort,
            color: (currentSortOption != null)
                ? colorScheme.primary
                : colorScheme.onSurface,
          ),
          onPressed: () => _showSortBottomSheet(context),
          tooltip: 'Trier les locaux',
        ),
        if (onSearchPressed != null)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: onSearchPressed,
            tooltip: 'Rechercher',
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
              title: Text('Paramètres'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'help',
            child: ListTile(
              leading: Icon(Icons.help_outline),
              title: Text('Aide'),
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
                  hintText: searchHint ?? 'Rechercher locaux, locataires...',
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
                    'Recherches récentes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildSearchSuggestion(context, 'Locaux disponibles'),
                  _buildSearchSuggestion(context, 'Paiements en retard'),
                  _buildSearchSuggestion(context, 'Renouvellements de bail'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    List<StatusFilter> selectedFilters =
        List.from(currentFilters ?? [StatusFilter.all]);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 350,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtrer par statut',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedFilters = [StatusFilter.all];
                        });
                      },
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterOption(
                      context,
                      'Tous les locaux',
                      StatusFilter.all,
                      selectedFilters,
                      setState,
                    ),
                    _buildFilterOption(
                      context,
                      'Disponibles',
                      StatusFilter.available,
                      selectedFilters,
                      setState,
                    ),
                    _buildFilterOption(
                      context,
                      'Occupés',
                      StatusFilter.occupied,
                      selectedFilters,
                      setState,
                    ),
                    _buildFilterOption(
                      context,
                      'En maintenance',
                      StatusFilter.maintenance,
                      selectedFilters,
                      setState,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onFilterChanged?.call(selectedFilters);
                            },
                            child: const Text('Appliquer'),
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
      ),
    );
  }

  void _showSortBottomSheet(BuildContext context) {
    SortOption selectedSort = currentSortOption ?? SortOption.propertyNumber;
    bool selectedAscending = currentSortAscending ?? true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: 400,
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trier par',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedSort = SortOption.propertyNumber;
                          selectedAscending = true;
                        });
                      },
                      child: const Text('Par défaut'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildSortOption(
                      context,
                      'Numéro de local',
                      SortOption.propertyNumber,
                      selectedSort,
                      (option) => setState(() => selectedSort = option),
                    ),
                    _buildSortOption(
                      context,
                      'Type de local',
                      SortOption.propertyType,
                      selectedSort,
                      (option) => setState(() => selectedSort = option),
                    ),
                    _buildSortOption(
                      context,
                      'Étage',
                      SortOption.floor,
                      selectedSort,
                      (option) => setState(() => selectedSort = option),
                    ),
                    _buildSortOption(
                      context,
                      'Statut',
                      SortOption.status,
                      selectedSort,
                      (option) => setState(() => selectedSort = option),
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      title: const Text('Ordre croissant'),
                      subtitle: Text(
                        selectedAscending ? 'A → Z, 1 → 9' : 'Z → A, 9 → 1',
                      ),
                      value: selectedAscending,
                      onChanged: (value) {
                        setState(() {
                          selectedAscending = value;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onSortChanged?.call(
                                  selectedSort, selectedAscending);
                            },
                            child: const Text('Appliquer'),
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
    BuildContext context,
    String title,
    StatusFilter filter,
    List<StatusFilter> selectedFilters,
    StateSetter setState,
  ) {
    final isSelected = selectedFilters.contains(filter);

    return CheckboxListTile(
      title: Text(title),
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (filter == StatusFilter.all) {
            if (value == true) {
              selectedFilters.clear();
              selectedFilters.add(StatusFilter.all);
            }
          } else {
            if (value == true) {
              selectedFilters.remove(StatusFilter.all);
              selectedFilters.add(filter);
            } else {
              selectedFilters.remove(filter);
              if (selectedFilters.isEmpty) {
                selectedFilters.add(StatusFilter.all);
              }
            }
          }
        });
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String title,
    SortOption option,
    SortOption selectedSort,
    Function(SortOption) onChanged,
  ) {
    return RadioListTile<SortOption>(
      title: Text(title),
      value: option,
      groupValue: selectedSort,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }

  void _navigateToNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications à venir')),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'settings':
        Navigator.pushNamed(context, '/settings-screen');
        break;
      case 'help':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aide à venir')),
        );
        break;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
