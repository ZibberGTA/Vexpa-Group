import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/search_autocomplete_data.dart';

/// Interactive floating glass search bar with placeholder autocomplete.
class SearchFloatingBar extends StatefulWidget {
  const SearchFloatingBar({
    super.key,
    required this.onQueryChanged,
  });

  final ValueChanged<String> onQueryChanged;

  @override
  State<SearchFloatingBar> createState() => _SearchFloatingBarState();
}

class _SearchFloatingBarState extends State<SearchFloatingBar> {
  static const _radius = AppSpacing.radiusXl;
  static const _animationDuration = Duration(milliseconds: 180);

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool _hovered = false;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions =
          _focusNode.hasFocus && _controller.text.trim().isNotEmpty;
    });
  }

  void _onTextChanged() {
    final query = _controller.text;
    widget.onQueryChanged(query);
    setState(() {
      _showSuggestions = _focusNode.hasFocus && query.trim().isNotEmpty;
    });
  }

  void _clearQuery() {
    _controller.clear();
    widget.onQueryChanged('');
    setState(() => _showSuggestions = false);
    _focusNode.requestFocus();
  }

  void _closeSuggestions() {
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
  }

  void _selectSuggestion(String value) {
    _controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    widget.onQueryChanged(value);
    setState(() => _showSuggestions = false);
    _focusNode.requestFocus();
  }

  double _barHeight(BuildContext context) {
    return switch (Breakpoints.of(context)) {
      ScreenSize.desktop => 68.0,
      ScreenSize.tablet => 64.0,
      ScreenSize.mobile => 58.0,
    };
  }

  BorderRadius get _borderRadius => BorderRadius.circular(_radius);

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    final elevated = focused || _hovered;
    final barHeight = _barHeight(context);
    final isMobile = Breakpoints.isMobile(context);
    final iconSlotWidth = isMobile ? 44.0 : 52.0;
    final horizontalPadding = isMobile ? AppSpacing.lg : AppSpacing.xl;
    final fontSize = isMobile ? 14.0 : 16.0;
    final hintSize = isMobile ? 14.0 : 16.0;
    final iconSize = isMobile ? 22.0 : 24.0;
    final hasText = _controller.text.isNotEmpty;
    final suggestions = SearchAutocompleteData.match(_controller.text);
    final visibleSuggestions =
        _showSuggestions && hasText && suggestions.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: _animationDuration,
            curve: Curves.easeOut,
            height: barHeight,
            decoration: BoxDecoration(
              borderRadius: _borderRadius,
              border: Border.all(
                color: elevated
                    ? AppColors.primaryPink.withValues(alpha: 0.75)
                    : AppColors.primaryPurple.withValues(alpha: 0.38),
                width: elevated ? 1.6 : 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceElevated.withValues(alpha: 0.96),
                  AppColors.deepPurple.withValues(alpha: 0.50),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(
                    alpha: elevated ? 0.34 : 0.14,
                  ),
                  blurRadius: elevated ? 40 : 24,
                  spreadRadius: elevated ? 1 : 0,
                  offset: Offset.zero,
                ),
                BoxShadow(
                  color: AppColors.primaryPurple.withValues(
                    alpha: elevated ? 0.24 : 0.10,
                  ),
                  blurRadius: elevated ? 48 : 28,
                  spreadRadius: -2,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: _borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _closeSuggestions(),
                  onTapOutside: (_) => _closeSuggestions(),
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.surface.withValues(alpha: 0.08),
                    hintText: AppStrings.searchPlaceholder,
                    hintStyle: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.88),
                      fontSize: hintSize,
                      height: 1.2,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    prefixIcon: SizedBox(
                      width: iconSlotWidth,
                      child: Center(
                        child: Icon(
                          Icons.search_rounded,
                          size: iconSize,
                          color: elevated
                              ? AppColors.primaryPink
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: iconSlotWidth,
                      maxWidth: iconSlotWidth,
                      minHeight: barHeight,
                      maxHeight: barHeight,
                    ),
                    suffixIcon: SizedBox(
                      width: hasText ? iconSlotWidth * 1.8 : iconSlotWidth,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (hasText)
                            IconButton(
                              onPressed: _clearQuery,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              icon: Icon(
                                Icons.close_rounded,
                                size: isMobile ? 18 : 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          IconButton(
                            onPressed: () {},
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            icon: Icon(
                              Icons.tune_rounded,
                              size: isMobile ? 20 : 22,
                              color: elevated
                                  ? AppColors.primaryPurple
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    suffixIconConstraints: BoxConstraints(
                      minWidth: hasText ? iconSlotWidth * 1.8 : iconSlotWidth,
                      maxWidth: hasText ? iconSlotWidth * 1.8 : iconSlotWidth,
                      minHeight: barHeight,
                      maxHeight: barHeight,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: _animationDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                alignment: Alignment.topCenter,
                child: child,
              ),
            );
          },
          child: visibleSuggestions
              ? _SearchSuggestionsDropdown(
                  key: ValueKey(suggestions.join('|')),
                  suggestions: suggestions,
                  onSuggestionSelected: _selectSuggestion,
                )
              : const SizedBox.shrink(key: ValueKey('empty-suggestions')),
        ),
      ],
    );
  }
}

class _SearchSuggestionsDropdown extends StatelessWidget {
  const _SearchSuggestionsDropdown({
    super.key,
    required this.suggestions,
    required this.onSuggestionSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < suggestions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: AppColors.border.withValues(alpha: 0.35),
                    ),
                  _SuggestionTile(
                    label: suggestions[i],
                    onTap: () => onSuggestionSelected(suggestions[i]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  const _SuggestionTile({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: _hovered
            ? AppColors.primaryPurple.withValues(alpha: 0.18)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: _hovered
                      ? AppColors.primaryPink
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: _hovered ? AppColors.white : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
