import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

import '../../../../shared/widgets/premium_effects.dart';

/// Search input for the drinks management list with optional clear action.
class DrinksSearchField extends StatefulWidget {
  const DrinksSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search drinks…',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  State<DrinksSearchField> createState() => _DrinksSearchFieldState();
}

class _DrinksSearchFieldState extends State<DrinksSearchField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant DrinksSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  void _clearSearch() {
    widget.controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: PremiumEffects.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: _focused ? PremiumEffects.hoverGlow(intensity: 0.25) : null,
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: const TextStyle(color: AppColors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.85),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: _focused ? AppColors.primaryPink : AppColors.textSecondary,
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    tooltip: 'Clear search',
                    onPressed: _clearSearch,
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceElevated.withValues(alpha: _focused ? 0.82 : 0.58),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: AppColors.primaryPurple.withValues(alpha: 0.16),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: AppColors.primaryPurple.withValues(alpha: 0.16),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: AppColors.primaryPink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
