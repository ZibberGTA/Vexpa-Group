import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'inline_edit_cell_theme.dart';

/// Click-to-edit text cell with Enter save, blur save, and Escape cancel.
class InlineEditableTextCell extends StatefulWidget {
  const InlineEditableTextCell({
    super.key,
    required this.value,
    required this.onSave,
    this.validate,
    this.displayStyle,
    this.hintText,
    this.onAdvancedEdit,
    this.enabled = true,
  });

  final String value;
  final Future<String?> Function(String value) onSave;
  final String? Function(String value)? validate;
  final TextStyle? displayStyle;
  final String? hintText;
  final VoidCallback? onAdvancedEdit;
  final bool enabled;

  @override
  State<InlineEditableTextCell> createState() => _InlineEditableTextCellState();
}

class _InlineEditableTextCellState extends State<InlineEditableTextCell> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  bool _editing = false;
  InlineCellSaveState _saveState = InlineCellSaveState.idle;
  String? _errorMessage;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant InlineEditableTextCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = widget.value;
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
      _controller.text = widget.value;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    if (!_editing) return;
    _controller.text = widget.value;
    setState(() {
      _editing = false;
      _saveState = InlineCellSaveState.idle;
      _errorMessage = null;
    });
    _focusNode.unfocus();
  }

  Future<void> _commitSave() async {
    if (!_editing || _saveState == InlineCellSaveState.saving) return;

    final nextValue = _controller.text;
    if (nextValue.trim() == widget.value.trim()) {
      _cancelEditing();
      return;
    }

    final validationError = widget.validate?.call(nextValue);
    if (validationError != null) {
      setState(() {
        _saveState = InlineCellSaveState.error;
        _errorMessage = validationError;
      });
      return;
    }

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

      setState(() {
        _editing = false;
        _saveState = InlineCellSaveState.success;
      });
      _focusNode.unfocus();

      _successTimer?.cancel();
      _successTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) {
          setState(() => _saveState = InlineCellSaveState.idle);
        }
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
    final displayStyle =
        widget.displayStyle ?? InlineEditCellTheme.displayTextStyle;

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
              style: InlineEditCellTheme.editTextStyle,
              decoration: InlineEditCellTheme.inputDecoration(
                hintText: widget.hintText,
              ).copyWith(
                errorText:
                    _saveState == InlineCellSaveState.error ? _errorMessage : null,
              ),
              enabled: _saveState != InlineCellSaveState.saving,
              onSubmitted: (_) => _commitSave(),
            )
          else
            GestureDetector(
              onTap: _startEditing,
              onDoubleTap: widget.onAdvancedEdit,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  widget.value.isEmpty ? '—' : widget.value,
                  style: displayStyle.copyWith(
                    fontStyle: widget.value.isEmpty ? FontStyle.italic : null,
                    color: widget.value.isEmpty
                        ? AppColors.textSecondary.withValues(alpha: 0.45)
                        : displayStyle.color,
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
