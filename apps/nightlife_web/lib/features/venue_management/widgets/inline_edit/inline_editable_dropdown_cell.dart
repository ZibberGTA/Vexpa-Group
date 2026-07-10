import 'dart:async';

import 'package:flutter/material.dart';

import 'inline_edit_cell_theme.dart';

/// Click-to-edit dropdown cell with blur save and Escape cancel.
class InlineEditableDropdownCell<T> extends StatefulWidget {
  const InlineEditableDropdownCell({
    super.key,
    required this.value,
    required this.items,
    required this.displayLabel,
    required this.onSave,
    this.validate,
    this.enabled = true,
  });

  final T value;
  final List<T> items;
  final String Function(T value) displayLabel;
  final Future<String?> Function(T value) onSave;
  final String? Function(T value)? validate;
  final bool enabled;

  @override
  State<InlineEditableDropdownCell<T>> createState() =>
      _InlineEditableDropdownCellState<T>();
}

class _InlineEditableDropdownCellState<T>
    extends State<InlineEditableDropdownCell<T>> {
  bool _editing = false;
  InlineCellSaveState _saveState = InlineCellSaveState.idle;
  String? _errorMessage;
  Timer? _successTimer;
  T? _draftValue;

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  void _startEditing() {
    if (!widget.enabled || _saveState == InlineCellSaveState.saving) return;
    setState(() {
      _editing = true;
      _draftValue = widget.value;
      _saveState = InlineCellSaveState.idle;
      _errorMessage = null;
    });
  }

  void _cancelEditing() {
    if (!_editing) return;
    setState(() {
      _editing = false;
      _draftValue = null;
      _saveState = InlineCellSaveState.idle;
      _errorMessage = null;
    });
  }

  Future<void> _commitSave(T nextValue) async {
    if (_saveState == InlineCellSaveState.saving) return;
    if (nextValue == widget.value) {
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
        _draftValue = null;
        _saveState = InlineCellSaveState.success;
      });

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
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_editing)
            DropdownButtonFormField<T>(
              value: _draftValue,
              isDense: true,
              isExpanded: true,
              decoration: InlineEditCellTheme.inputDecoration(),
              items: widget.items
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        widget.displayLabel(item),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saveState == InlineCellSaveState.saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _draftValue = value);
                      _commitSave(value);
                    },
            )
          else
            GestureDetector(
              onTap: _startEditing,
              behavior: HitTestBehavior.opaque,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  widget.displayLabel(widget.value),
                  style: InlineEditCellTheme.displayTextStyle,
                ),
              ),
            ),
          InlineEditFeedback(
            state: _saveState,
            errorMessage: _errorMessage,
          ),
        ],
      ),
    );
  }
}
