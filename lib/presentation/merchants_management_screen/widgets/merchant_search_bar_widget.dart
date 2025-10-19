import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class MerchantSearchBarWidget extends StatefulWidget {
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterPressed;
  final TextEditingController? controller;

  const MerchantSearchBarWidget({
    super.key,
    this.hintText,
    this.onChanged,
    this.onFilterPressed,
    this.controller,
  });

  @override
  State<MerchantSearchBarWidget> createState() =>
      _MerchantSearchBarWidgetState();
}

class _MerchantSearchBarWidgetState extends State<MerchantSearchBarWidget> {
  late TextEditingController _controller;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged() {
    final isActive = _controller.text.isNotEmpty;
    if (isActive != _isSearchActive) {
      setState(() {
        _isSearchActive = isActive;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          // Search TextField
          Expanded(
            child: Container(
              height: 6.h,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSearchActive
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: _isSearchActive ? 2 : 1,
                ),
                boxShadow: _isSearchActive
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _controller,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Rechercher commerçants...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      size: 20,
                      color: _isSearchActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  suffixIcon: _isSearchActive
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          tooltip: 'Effacer la recherche',
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => widget.onChanged?.call(value),
              ),
            ),
          ),

          SizedBox(width: 3.w),

          // Filter Button
          Container(
            height: 6.h,
            width: 6.h,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onFilterPressed,
                borderRadius: BorderRadius.circular(12),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'filter_list',
                    size: 24,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
