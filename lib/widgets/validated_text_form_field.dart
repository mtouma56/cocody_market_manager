import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ValidatedTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? helperText;
  final String? suffixText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String value)? validator;
  final ValueChanged<String>? onChanged;
  final String Function(String value)? dynamicHintBuilder;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool enabled;

  const ValidatedTextFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.helperText,
    this.suffixText,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.dynamicHintBuilder,
    this.textInputAction,
    this.obscureText = false,
    this.enabled = true,
  });

  @override
  State<ValidatedTextFormField> createState() => _ValidatedTextFormFieldState();
}

class _ValidatedTextFormFieldState extends State<ValidatedTextFormField> {
  String? _errorText;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _validate(String value) {
    final result = widget.validator?.call(value.trim());
    if (result != _errorText) {
      setState(() {
        _errorText = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textValue = widget.controller.text;
    final hasText = textValue.isNotEmpty;
    final isValid = hasText && (_errorText == null || _errorText!.isEmpty);
    final isError = _errorText != null && _errorText!.isNotEmpty;

    final borderColor = isValid
        ? theme.colorScheme.secondary
        : isError
            ? theme.colorScheme.error
            : theme.colorScheme.outlineVariant;

    final dynamicHint = widget.dynamicHintBuilder?.call(textValue.trim());
    final helperToShow = isError
        ? _errorText
        : dynamicHint?.isNotEmpty == true
            ? dynamicHint
            : widget.helperText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.4),
            color: theme.colorScheme.surface,
            boxShadow: isValid
                ? [
                    BoxShadow(
                      color:
                          theme.colorScheme.secondary.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              inputFormatters: widget.inputFormatters,
              style: theme.textTheme.bodyMedium,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (value) {
                final text = value?.trim() ?? '';
                final result = widget.validator?.call(text);
                if (result != _errorText) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _errorText = result;
                      });
                    }
                  });
                }
                return result;
              },
              onChanged: (value) {
                _validate(value);
                widget.onChanged?.call(value);
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          widget.prefixIcon,
                          size: 22,
                          color: _focusNode.hasFocus
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                prefixIconConstraints:
                    const BoxConstraints(minWidth: 0, minHeight: 0),
                suffixIcon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Row(
                    key: ValueKey<String>(
                      isValid
                          ? 'valid'
                          : isError
                              ? 'error'
                              : 'empty',
                    ),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.suffixText != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            widget.suffixText!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (isValid)
                        Icon(Icons.check_circle,
                            color: theme.colorScheme.secondary,
                            key: const ValueKey('valid'))
                      else if (isError)
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.error,
                            key: const ValueKey('error'))
                      else
                        const SizedBox(key: ValueKey('empty')),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: helperToShow != null && helperToShow.isNotEmpty
              ? Text(
                  helperToShow,
                  key: ValueKey(helperToShow),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
