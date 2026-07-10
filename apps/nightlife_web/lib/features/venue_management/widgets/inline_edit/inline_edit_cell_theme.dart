import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Visual feedback state for inline table cell saves.
enum InlineCellSaveState {
  idle,
  saving,
  success,
  error,
}

/// Shared dense input decoration for inline table cells.
class InlineEditCellTheme {
  InlineEditCellTheme._();

  static InputDecoration inputDecoration({String? hintText}) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      filled: true,
      fillColor: AppColors.surfaceElevated.withValues(alpha: 0.72),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 8,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(
          color: AppColors.primaryPink.withValues(alpha: 0.45),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(
          color: AppColors.primaryPink.withValues(alpha: 0.65),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        borderSide: BorderSide(
          color: AppColors.primaryPink.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  static TextStyle get displayTextStyle => const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
        fontSize: 13.5,
      );

  static TextStyle get titleDisplayTextStyle => const TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      );

  static TextStyle get editTextStyle => const TextStyle(
        color: AppColors.white,
        fontWeight: FontWeight.w500,
        fontSize: 13.5,
      );
}

/// Subtle saving / success / error indicator beneath an inline cell.
class InlineEditFeedback extends StatelessWidget {
  const InlineEditFeedback({
    super.key,
    required this.state,
    this.errorMessage,
  });

  final InlineCellSaveState state;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (state == InlineCellSaveState.idle) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: switch (state) {
        InlineCellSaveState.saving => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.primaryPink.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Saving…',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        InlineCellSaveState.success => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_rounded,
                size: 12,
                color: AppColors.primaryPink.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 2),
              Text(
                'Saved',
                style: TextStyle(
                  color: AppColors.primaryPink.withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        InlineCellSaveState.error => Text(
            errorMessage ?? 'Could not save.',
            style: TextStyle(
              color: AppColors.primaryPink.withValues(alpha: 0.95),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        InlineCellSaveState.idle => const SizedBox.shrink(),
      },
    );
  }
}

/// Returns true when [event] is an Escape key press.
bool inlineEditEscapePressed(KeyEvent event) {
  return event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape;
}
