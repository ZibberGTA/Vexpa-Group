import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'inline_edit_cell_theme.dart';

/// Click-to-toggle boolean cell with immediate save.
class InlineEditableToggleCell extends StatefulWidget {
  const InlineEditableToggleCell({
    super.key,
    required this.value,
    required this.onSave,
    this.enabled = true,
    this.useSwitch = false,
  });

  final bool value;
  final Future<String?> Function(bool value) onSave;
  final bool enabled;
  final bool useSwitch;

  @override
  State<InlineEditableToggleCell> createState() =>
      _InlineEditableToggleCellState();
}

class _InlineEditableToggleCellState extends State<InlineEditableToggleCell> {
  InlineCellSaveState _saveState = InlineCellSaveState.idle;
  String? _errorMessage;
  Timer? _successTimer;

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!widget.enabled || _saveState == InlineCellSaveState.saving) return;

    final nextValue = !widget.value;

    setState(() {
      _saveState = InlineCellSaveState.saving;
      _errorMessage = null;
    });

    try {
      final error = await widget.onSave(nextValue);
      if (!mounted) return;

      if (error != null) {
        setState(() {
          _saveState = InlineCellSaveState.error;
          _errorMessage = error;
        });
        return;
      }

      setState(() => _saveState = InlineCellSaveState.success);
      _successTimer?.cancel();
      _successTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _saveState = InlineCellSaveState.idle);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveState = InlineCellSaveState.error;
        _errorMessage = 'Could not save. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.useSwitch ? null : _toggle,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: widget.useSwitch
                ? Transform.scale(
                    scale: 0.82,
                    child: Switch(
                      value: widget.value,
                      activeThumbColor: AppColors.primaryPink,
                      onChanged: widget.enabled &&
                              _saveState != InlineCellSaveState.saving
                          ? (_) => _toggle()
                          : null,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Text(
                      widget.value ? 'Yes' : 'No',
                      style: InlineEditCellTheme.displayTextStyle,
                    ),
                  ),
          ),
        ),
        InlineEditFeedback(
          state: _saveState,
          errorMessage: _errorMessage,
        ),
      ],
    );
  }
}
