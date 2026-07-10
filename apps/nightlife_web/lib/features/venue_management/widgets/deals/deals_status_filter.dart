import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/premium_effects.dart';
import '../../models/deal_status.dart';

/// All + multi-select status filter row for deals management.
class DealsStatusFilterRow extends StatelessWidget {
  const DealsStatusFilterRow({
    super.key,
    required this.selectedStatuses,
    required this.onAllSelected,
    required this.onStatusToggled,
  });

  final Set<String> selectedStatuses;
  final VoidCallback onAllSelected;
  final void Function(String status, bool selected) onStatusToggled;

  String get _statusButtonLabel {
    final count = selectedStatuses.length;
    if (count == 0) return 'Status';
    return 'Status ($count)';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _DealsFilterChip(
          label: 'All',
          selected: selectedStatuses.isEmpty,
          onTap: onAllSelected,
        ),
        _DealsStatusDropdown(
          key: const Key('deals_status_filter_button'),
          label: _statusButtonLabel,
          selectedStatuses: selectedStatuses,
          onStatusToggled: onStatusToggled,
        ),
      ],
    );
  }
}

class _DealsStatusDropdown extends StatelessWidget {
  const _DealsStatusDropdown({
    super.key,
    required this.label,
    required this.selectedStatuses,
    required this.onStatusToggled,
  });

  final String label;
  final Set<String> selectedStatuses;
  final void Function(String status, bool selected) onStatusToggled;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          AppColors.surfaceElevated.withValues(alpha: 0.98),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            side: BorderSide(
              color: AppColors.primaryPurple.withValues(alpha: 0.24),
            ),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
        maximumSize: const WidgetStatePropertyAll(Size(280, 340)),
      ),
      menuChildren: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320, minWidth: 248),
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final status in dealStatusFilterOptions)
                  _StatusCheckboxMenuItem(
                    key: Key('deals_status_filter_$status'),
                    status: status,
                    selected: selectedStatuses.contains(status),
                    onChanged: (selected) => onStatusToggled(status, selected),
                  ),
              ],
            ),
          ),
        ),
      ],
      builder: (context, controller, child) {
        return _DealsFilterChip(
          label: label,
          selected: selectedStatuses.isNotEmpty,
          showDropdownArrow: true,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }
}

class _StatusCheckboxMenuItem extends StatelessWidget {
  const _StatusCheckboxMenuItem({
    super.key,
    required this.status,
    required this.selected,
    required this.onChanged,
  });

  final String status;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!selected),
        hoverColor: AppColors.primaryPurple.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: selected,
                  onChanged: (value) => onChanged(value ?? false),
                  activeColor: AppColors.primaryPink,
                  side: BorderSide(
                    color: AppColors.primaryPurple.withValues(alpha: 0.45),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DealsFilterChip extends StatefulWidget {
  const _DealsFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showDropdownArrow = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDropdownArrow;

  @override
  State<_DealsFilterChip> createState() => _DealsFilterChipState();
}

class _DealsFilterChipState extends State<_DealsFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.selected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: PremiumEffects.fast,
          curve: PremiumEffects.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, highlighted && !widget.selected ? -1.0 : 0.0),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            gradient: widget.selected ? AppColors.brandGradient : null,
            color: widget.selected
                ? null
                : AppColors.surfaceElevated.withValues(alpha: 0.78),
            border: Border.all(
              color: widget.selected
                  ? Colors.transparent
                  : highlighted
                      ? AppColors.primaryPink.withValues(alpha: 0.28)
                      : AppColors.primaryPurple.withValues(alpha: 0.18),
            ),
            boxShadow: widget.selected || (highlighted && !widget.selected)
                ? PremiumEffects.hoverGlow(intensity: widget.selected ? 0.45 : 0.2)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              if (widget.showDropdownArrow) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: widget.selected
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
