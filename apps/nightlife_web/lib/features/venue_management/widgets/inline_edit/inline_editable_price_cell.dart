import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/drink_categories.dart';
import 'inline_edit_cell_theme.dart';

/// Click-to-edit price cell with £ validation.
class InlineEditablePriceCell extends StatefulWidget {
  const InlineEditablePriceCell({
    super.key,
    required this.price,
    required this.displayText,
    required this.onSave,
    this.enabled = true,
  });

  final double price;
  final String displayText;
  final Future<String?> Function(double? price) onSave;
  final bool enabled;

  @override
  State<InlineEditablePriceCell> createState() => _InlineEditablePriceCellState();
}

class _InlineEditablePriceCellState extends State<InlineEditablePriceCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool _editing = false;
  InlineCellSaveState _saveState = InlineCellSaveState.idle;
  String? _errorMessage;
  Timer? _successTimer;

  String get _editSeed =>
      widget.price > 0 ? widget.price.toStringAsFixed(2) : '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _editSeed);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant InlineEditablePriceCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.price != widget.price) {
      _controller.text = _editSeed;
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _editing) {
      _commitSave();
    }
  }

  void _startEditing() {
    if (!widget.enabled || _saveState == InlineCellSaveState.saving) return;
    setState(() {
      _editing = true;
      _saveState = InlineCellSaveState.idle;
      _errorMessage = null;
      _controller.text = _editSeed;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    if (!_editing) return;
    _controller.text = _editSeed;
    setState(() {
      _editing = false;
      _saveState = InlineCellSaveState.idle;
      _errorMessage = null;
    });
    _focusNode.unfocus();
  }

  Future<void> _commitSave() async {
    if (!_editing || _saveState == InlineCellSaveState.saving) return;

    final validationError = AddDrinkFormValidator.validatePrice(_controller.text);
    if (validationError != null) {
      setState(() {
        _saveState = InlineCellSaveState.error;
        _errorMessage = validationError;
      });
      return;
    }

    final trimmed = _controller.text.trim().replaceAll('£', '');
    final parsed = trimmed.isEmpty ? null : double.tryParse(trimmed);
    final unchanged = parsed == null
        ? widget.price <= 0
        : (widget.price - parsed).abs() < 0.001;

    if (unchanged) {
      _cancelEditing();
      return;
    }

    setState(() {
      _saveState = InlineCellSaveState.saving;
      _errorMessage = null;
    });

    try {
      final error = await widget.onSave(parsed);
      if (!mounted) return;

      if (error != null) {
        setState(() {
          _saveState = InlineCellSaveState.error;
          _errorMessage = error;
        });
        return;
      }

      setState(() {
        _editing = false;
        _saveState = InlineCellSaveState.success;
      });
      _focusNode.unfocus();

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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (inlineEditEscapePressed(event)) {
      _cancelEditing();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_editing)
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: InlineEditCellTheme.editTextStyle,
              decoration: InlineEditCellTheme.inputDecoration(hintText: '9.50')
                  .copyWith(
                prefixText: '£ ',
                prefixStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                errorText:
                    _saveState == InlineCellSaveState.error ? _errorMessage : null,
              ),
              enabled: _saveState != InlineCellSaveState.saving,
              onSubmitted: (_) => _commitSave(),
            )
          else
            GestureDetector(
              onTap: _startEditing,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  widget.displayText,
                  style: InlineEditCellTheme.displayTextStyle.copyWith(
                    fontStyle:
                        widget.displayText == '—' ? FontStyle.italic : FontStyle.normal,
                    color: widget.displayText == '—'
                        ? AppColors.textSecondary.withValues(alpha: 0.45)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          if (!_editing || _saveState != InlineCellSaveState.error)
            InlineEditFeedback(
              state: _saveState,
              errorMessage: _errorMessage,
            ),
        ],
      ),
    );
  }
}
