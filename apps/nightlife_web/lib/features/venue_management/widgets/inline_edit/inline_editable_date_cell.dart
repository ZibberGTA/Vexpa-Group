import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'inline_edit_cell_theme.dart';

/// Click-to-edit date cell that opens a date picker.
class InlineEditableDateCell extends StatefulWidget {
  const InlineEditableDateCell({
    super.key,
    required this.value,
    required this.displayText,
    required this.onSave,
    this.firstDate,
    this.enabled = true,
  });

  final DateTime? value;
  final String displayText;
  final Future<String?> Function(DateTime date) onSave;
  final DateTime? firstDate;
  final bool enabled;

  @override
  State<InlineEditableDateCell> createState() => _InlineEditableDateCellState();
}

class _InlineEditableDateCellState extends State<InlineEditableDateCell> {
  InlineCellSaveState _saveState = InlineCellSaveState.idle;
  String? _errorMessage;
  Timer? _successTimer;

  @override
  void dispose() {
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (!widget.enabled || _saveState == InlineCellSaveState.saving) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPink,
              surface: AppColors.surfaceElevated,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null || !mounted) return;

    if (widget.value != null &&
        picked.year == widget.value!.year &&
        picked.month == widget.value!.month &&
        picked.day == widget.value!.day) {
      return;
    }

    setState(() {
      _saveState = InlineCellSaveState.saving;
      _errorMessage = null;
    });

    try {
      final error = await widget.onSave(picked);
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
          onTap: _pickDate,
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
        InlineEditFeedback(
          state: _saveState,
          errorMessage: _errorMessage,
        ),
      ],
    );
  }
}

/// Click-to-edit time cell using HH:mm text input.
class InlineEditableTimeCell extends StatefulWidget {
  const InlineEditableTimeCell({
    super.key,
    required this.value,
    required this.onSave,
    this.enabled = true,
  });

  final String value;
  final Future<String?> Function(String time) onSave;
  final bool enabled;

  @override
  State<InlineEditableTimeCell> createState() => _InlineEditableTimeCellState();
}

class _InlineEditableTimeCellState extends State<InlineEditableTimeCell> {
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
  void didUpdateWidget(covariant InlineEditableTimeCell oldWidget) {
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
      _controller.text = widget.value;
      _saveState = InlineCellSaveState.idle;
      _errorMessage = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _cancelEditing() {
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
    if (_controller.text.trim() == widget.value.trim()) {
      _cancelEditing();
      return;
    }

    setState(() {
      _saveState = InlineCellSaveState.saving;
      _errorMessage = null;
    });

    try {
      final error = await widget.onSave(_controller.text.trim());
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
    final display = widget.value.isEmpty ? '—' : widget.value;

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
              decoration: InlineEditCellTheme.inputDecoration(hintText: '17:00'),
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
                  display,
                  style: InlineEditCellTheme.displayTextStyle.copyWith(
                    fontStyle: display == '—' ? FontStyle.italic : FontStyle.normal,
                    color: display == '—'
                        ? AppColors.textSecondary.withValues(alpha: 0.45)
                        : AppColors.textSecondary,
                  ),
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
