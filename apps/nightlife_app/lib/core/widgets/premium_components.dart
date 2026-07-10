import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PremiumHeroSection extends StatelessWidget {
  const PremiumHeroSection({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 14),
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withOpacity(0.32),
              AppColors.primaryPink.withOpacity(0.22),
              AppColors.surface.withOpacity(0.92),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.18),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primaryPurple.withOpacity(0.65)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: AppColors.primaryPink),
                        const SizedBox(width: 6),
                        const Text(
                          'Drink Spot',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(title, style: Theme.of(context).textTheme.headlineLarge),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle, this.action});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        gradient: const LinearGradient(
          colors: [AppColors.primaryPink, AppColors.primaryPurple],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
        ),
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
      ),
    );
  }
}

class PremiumLoading extends StatefulWidget {
  const PremiumLoading({super.key, this.label = 'Loading...'});

  final String label;

  @override
  State<PremiumLoading> createState() => _PremiumLoadingState();
}

class _PremiumLoadingState extends State<PremiumLoading> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.55, end: 1).animate(_controller),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumVenueImageCard extends StatelessWidget {
  const PremiumVenueImageCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.crowdLevel,
    this.imageUrl = '',
    this.category = '',
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String crowdLevel;
  final String imageUrl;
  final String category;
  final VoidCallback? onTap;

  Color _crowdColor(String value) {
    switch (value.toLowerCase()) {
      case 'quiet':
        return AppColors.success;
      case 'steady':
      case 'medium':
      case 'moderate':
        return AppColors.warning;
      case 'busy':
        return AppColors.primaryPink;
      case 'packed':
        return AppColors.primaryPurple;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final crowd = crowdLevel.isEmpty ? 'Unknown' : crowdLevel;
    final bg = imageUrl.isEmpty
        ? const _VenueFallbackBackground()
        : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _VenueFallbackBackground(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const _VenueFallbackBackground();
            },
          );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.98, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Ink(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    bg,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.12),
                            Colors.black.withOpacity(0.28),
                            Colors.black.withOpacity(0.82),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _GlassPill(label: category.isEmpty ? 'Venue' : category, icon: Icons.storefront_rounded),
                              const SizedBox(width: 8),
                              _GlassPill(
                                label: crowd,
                                icon: Icons.local_fire_department_rounded,
                                color: _crowdColor(crowd),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(title, style: Theme.of(context).textTheme.titleLarge),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Positioned(
                      top: 14,
                      right: 14,
                      child: CircleAvatar(
                        backgroundColor: Color(0x66000000),
                        child: Icon(Icons.chevron_right_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label, required this.icon, this.color = AppColors.primaryPink});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _VenueFallbackBackground extends StatelessWidget {
  const _VenueFallbackBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepPurpleBackground,
            AppColors.primaryPurple.withOpacity(0.55),
            AppColors.background,
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Icon(Icons.nightlife_rounded, size: 70, color: Colors.white.withOpacity(0.10)),
        ),
      ),
    );
  }
}
