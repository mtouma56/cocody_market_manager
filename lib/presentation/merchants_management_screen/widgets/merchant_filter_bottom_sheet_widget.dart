import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MerchantFilterBottomSheetWidget extends StatefulWidget {
  final Map<String, dynamic>? currentFilters;
  final ValueChanged<Map<String, dynamic>>? onFiltersApplied;

  const MerchantFilterBottomSheetWidget({
    super.key,
    this.currentFilters,
    this.onFiltersApplied,
  });

  @override
  State<MerchantFilterBottomSheetWidget> createState() =>
      _MerchantFilterBottomSheetWidgetState();
}

class _MerchantFilterBottomSheetWidgetState
    extends State<MerchantFilterBottomSheetWidget> {
  late Map<String, dynamic> _filters;

  final List<String> _statusOptions = [
    'Tous',
    'Actif',
    'Expire bientôt',
    'En retard'
  ];
  final List<String> _propertyTypeOptions = [
    'Tous',
    'Boutique 9m²',
    'Boutique 4.5m²',
    'Banque',
    'Restaurant',
    'Box',
    'Étal de marché'
  ];
  final List<String> _floorOptions = [
    'Tous',
    'Rez-de-chaussée',
    '1er étage',
    '2ème étage',
    '3ème étage'
  ];

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters ??
        {
          'status': 'Tous',
          'propertyType': 'Tous',
          'floor': 'Tous',
          'hasEmail': false,
          'hasPhone': false,
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Text(
                  'Filtrer les commerçants',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    'Réinitialiser',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),

          // Filter Options
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Filter
                  _buildFilterSection(
                    context,
                    'Statut du bail',
                    _statusOptions,
                    _filters['status'] as String,
                    (value) => setState(() => _filters['status'] = value),
                  ),

                  SizedBox(height: 3.h),

                  // Property Type Filter
                  _buildFilterSection(
                    context,
                    'Type de propriété',
                    _propertyTypeOptions,
                    _filters['propertyType'] as String,
                    (value) => setState(() => _filters['propertyType'] = value),
                  ),

                  SizedBox(height: 3.h),

                  // Floor Filter
                  _buildFilterSection(
                    context,
                    'Étage',
                    _floorOptions,
                    _filters['floor'] as String,
                    (value) => setState(() => _filters['floor'] = value),
                  ),

                  SizedBox(height: 3.h),

                  // Contact Information Filters
                  Text(
                    'Informations de contact',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),

                  CheckboxListTile(
                    title: const Text('Possède un email'),
                    value: _filters['hasEmail'] as bool,
                    onChanged: (value) =>
                        setState(() => _filters['hasEmail'] = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  CheckboxListTile(
                    title: const Text('Possède un téléphone'),
                    value: _filters['hasPhone'] as bool,
                    onChanged: (value) =>
                        setState(() => _filters['hasPhone'] = value ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Appliquer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<String> options,
    String selectedValue,
    ValueChanged<String> onChanged,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onChanged(option);
                }
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.onPrimaryContainer,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = {
        'status': 'Tous',
        'propertyType': 'Tous',
        'floor': 'Tous',
        'hasEmail': false,
        'hasPhone': false,
      };
    });
  }

  void _applyFilters() {
    widget.onFiltersApplied?.call(_filters);
    Navigator.pop(context);
  }
}
