import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LeaseSearchWidget extends StatefulWidget {
  final String searchQuery;
  final Function(String) onSearchChanged;
  final VoidCallback? onFilterPressed;

  const LeaseSearchWidget({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onFilterPressed,
  });

  @override
  State<LeaseSearchWidget> createState() => _LeaseSearchWidgetState();
}

class _LeaseSearchWidgetState extends State<LeaseSearchWidget> {
  late TextEditingController _searchController;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSearchActive
                      ? AppTheme.primaryBlue
                      : AppTheme.lightTheme.colorScheme.outline
                          .withValues(alpha: 0.3),
                  width: _isSearchActive ? 2 : 1,
                ),
                boxShadow: _isSearchActive
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                onTap: () => setState(() => _isSearchActive = true),
                onSubmitted: (_) => setState(() => _isSearchActive = false),
                decoration: InputDecoration(
                  hintText: 'Rechercher par commerçant, contrat, propriété...',
                  hintStyle: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: _isSearchActive
                          ? AppTheme.primaryBlue
                          : AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                            setState(() => _isSearchActive = false);
                          },
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                ),
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
            ),
          ),
          SizedBox(width: 3.w),
          GestureDetector(
            onTap: widget.onFilterPressed,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: CustomIconWidget(
                iconName: 'tune',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
