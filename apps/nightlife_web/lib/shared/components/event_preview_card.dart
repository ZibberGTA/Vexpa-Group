import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/home/models/event_preview.dart';
import 'pill_tag.dart';

class EventPreviewCard extends StatefulWidget {
  const EventPreviewCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final EventPreview event;
  final VoidCallback? onTap;

  @override
  State<EventPreviewCard> createState() => _EventPreviewCardState();
}

class _EventPreviewCardState extends State<EventPreviewCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -6.0 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: _hovered
                ? AppColors.primaryPurple.withValues(alpha: 0.65)
                : AppColors.primaryPurple.withValues(alpha: 0.28),
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            hoverColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLg),
                  ),
                  child: SizedBox(
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.event.imageGradient,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Text(
                              widget.event.time,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.name,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.event.venue,
                        style: const TextStyle(
                          color: AppColors.primaryPink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.event.area,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (var i = 0; i < widget.event.tags.length; i++)
                            PillTag(
                              label: widget.event.tags[i],
                              highlighted: i == 0,
                            ),
                        ],
                      ),
                    ],
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
